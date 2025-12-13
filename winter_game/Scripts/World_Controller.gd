extends Node3D

@export var cell_size: float = 1.0
@export var wall_1x1: PackedScene
@export var wall_2x1: PackedScene

@onready var camera: Camera3D = $Camera3D
@onready var wall_container: Node3D = $WallContainer

var occupied_cells := {} # Dictionary<Vector2i, bool>

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_wall(1) # 1x1 wall
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_place_wall(2) # 2x1 wall

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

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_dir * 1000.0
	)

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return Vector2i.ZERO

	var world_pos: Vector3 = result.position

	var x := int(floor(world_pos.x / cell_size))
	var z := int(floor(world_pos.z / cell_size))

	return Vector2i(x, z)

func _can_place(start: Vector2i, length: int) -> bool:
	for i in length:
		var cell := Vector2i(start.x + i, start.y)
		if occupied_cells.has(cell):
			return false
	return true

func _occupy_cells(start: Vector2i, length: int):
	for i in length:
		var cell := Vector2i(start.x + i, start.y)
		occupied_cells[cell] = true

func _place_wall(start: Vector2i, length: int):
	var scene := wall_1x1 if length == 1 else wall_2x1
	if scene == null:
		push_error("Wall prefab not assigned")
		return

	var wall: Node3D = scene.instantiate()
	wall_container.add_child(wall)

	# World position (bottom-left aligned)
	var world_x := (start.x + length * 0.5) * cell_size
	var world_z := (start.y + 0.5) * cell_size

	wall.global_position = Vector3(world_x, 0.0, world_z)

	_occupy_cells(start, length)
