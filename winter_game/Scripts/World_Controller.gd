extends Node3D

@export var cell_size: float = 1.0
@export var wall_1x1: PackedScene
@export var wall_2x1: PackedScene
@export var wall_height: float = 1.0

@onready var camera: Camera3D = $Camera3D
@onready var wall_container: Node3D = $WallContainer
@onready var wind_sources: Node = $WindSources
@onready var build_area: StaticBody3D = $BuildArea

var occupied_cells := {} # Vector2i -> Array[Node3D]

# -----------------------------
# Wind system
# -----------------------------
var wind_active: bool = false
@export var min_wind_force: float = 50.0
@export var max_wind_force: float = 200.0

# -----------------------------
# Input handling
# -----------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_wall(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_place_wall(2)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			wind_active = !wind_active
			if wind_active:
				print("Wind ON")
			else:
				print("Wind OFF")

# -----------------------------
# Physics loop for wind
# -----------------------------
func _physics_process(delta):
	_draw_wind_debug()
	if not wind_active:
		return

	if build_area == null:
		return

	var center = build_area.global_position

	for wind_area in wind_sources.get_children():
		if wind_area is Area3D:
			var bodies = wind_area.get_overlapping_bodies()
			for body in bodies:
				if body is RigidBody3D:
					# Direction toward build area center + slight random variation
					var dir = (center - body.global_position).normalized()
					var random_offset = Vector3(randf_range(-0.2,0.2), randf_range(0,0.2), randf_range(-0.2,0.2))
					dir += random_offset
					dir = dir.normalized()

					# Randomized force magnitude
					var force_mag = randf_range(min_wind_force, max_wind_force)
					var force = dir * force_mag

					body.apply_impulse(Vector3.ZERO, force)

# -----------------------------
# Wall placement
# -----------------------------
func _try_place_wall(length_in_cells: int):
	var grid_pos := _get_mouse_grid_position()
	if grid_pos == null:
		return

	if not _can_place(grid_pos, length_in_cells):
		return

	_place_wall(grid_pos, length_in_cells)

func _get_mouse_grid_position() -> Vector2i:
	var mouse_pos := get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_dir * 1000.0
	)

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return Vector2i.ZERO

	var world_pos: Vector3 = result.position
	return Vector2i(int(floor(world_pos.x / cell_size)), int(floor(world_pos.z / cell_size)))

# -----------------------------
# Grid stacking logic
# -----------------------------
func _can_place(start: Vector2i, length: int) -> bool:
	var target_height = _get_stack_height(start)
	for i in length:
		var cell = Vector2i(start.x + i, start.y)
		if _get_stack_height(cell) != target_height:
			return false
	return true

func _get_stack_height(cell: Vector2i) -> int:
	if not occupied_cells.has(cell):
		return 0
	return occupied_cells[cell].size()

func _ensure_cell_stack(cell: Vector2i) -> Array:
	if not occupied_cells.has(cell):
		occupied_cells[cell] = []
	return occupied_cells[cell]

# -----------------------------
# Place walls
# -----------------------------
func _place_wall(start: Vector2i, length: int):
	var scene = wall_1x1 if length == 1 else wall_2x1
	if scene == null:
		push_error("Wall prefab not assigned")
		return

	var wall: Node3D = scene.instantiate()
	wall_container.add_child(wall)

	var height_index = _get_stack_height(start)
	var y = height_index * wall_height

	var world_x = (start.x + length * 0.5) * cell_size
	var world_z = (start.y + 0.5) * cell_size

	wall.global_position = Vector3(world_x, y, world_z)

	# Occupy all cells in the wall
	for i in length:
		var cell = Vector2i(start.x + i, start.y)
		var stack = _ensure_cell_stack(cell)
		stack.append(wall)

# -----------------------------
# Debug wind visualization
# -----------------------------
func _draw_wind_debug():
	if build_area == null:
		return

	var center = build_area.global_position

	for wind_area in wind_sources.get_children():
		if wind_area is Area3D:
			# Find the DebugArrow node
			var debug_arrow = wind_area.get_node_or_null("DebugArrow") as MeshInstance3D
			if debug_arrow == null:
				continue

			# Compute direction to center
			var dir = (center - wind_area.global_position).normalized()

			# Optional: add slight random offset for realism
			var random_offset = Vector3(randf_range(-0.2,0.2), 0, randf_range(-0.2,0.2))
			var arrow_dir = (dir + random_offset).normalized()

			# Create ImmediateMesh arrow
			var arrow_mesh = ImmediateMesh.new()
			arrow_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

			var start_pos = Vector3.ZERO
			var end_pos = arrow_dir * 2.0  # Arrow length 2 units

			# Line from center to tip
			arrow_mesh.surface_add_vertex(start_pos)
			arrow_mesh.surface_add_vertex(end_pos)

			# Optional: small arrowhead
			var left = end_pos + Vector3(-0.2, 0.1, 0)
			var right = end_pos + Vector3(0.2, 0.1, 0)
			arrow_mesh.surface_add_vertex(end_pos)
			arrow_mesh.surface_add_vertex(left)
			arrow_mesh.surface_add_vertex(end_pos)
			arrow_mesh.surface_add_vertex(right)

			arrow_mesh.surface_end()
			debug_arrow.mesh = arrow_mesh
