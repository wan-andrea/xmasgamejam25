extends Node3D
@export var cell_size: float = 1.0
@export var wall_1x1: PackedScene
@export var wall_2x1: PackedScene
@export var wall_height: float = 1.0

@onready var camera: Camera3D = $Camera3D
@onready var wall_container: Node3D = $WallContainer
@onready var wind_sources: Node = $WindSources
@onready var buildableArea: StaticBody3D = $buildableArea

# For the grid
var occupied_cells := {} # Vector2i -> Array[Node3D]

# -----------------------------
# Load meshes into menu bar
# -----------------------------
# All the meshes to load into menu bar
# var thingToPlace_scene = preload("filepath_")
var creamPoofScene = preload("res://Scenes/creamPoof.tscn")

# -----------------------------
# Handling which menu button we are using
# -----------------------------
# Global variable to store which object currently placing
# null if not placing any menu items, initiated as null
var itemToPlace = null

# Determine which object we are placing - one function per menu button
func placeCream() -> void:
	itemToPlace = creamPoofScene
	print("Tool selected: creamPoof")

func placeWall() -> void:
	itemToPlace = wall_1x1
	print("Tool selected: Wall Builder")
	
# -----------------------------
# Place objects based on mouse coordinates
# -----------------------------
# If we are placing an object, get the mouse coords and place
func _unhandled_input(event):
	if itemToPlace == wall_1x1:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_try_place_wall(1)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_try_place_wall(2)
	# place not walls
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		placeAtMouse()
	if  event is InputEventMouseButton and itemToPlace == null:
		# FIX THIS 

# Gets mouse coords
func getMouseCoords():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	if result:
		print(result.position)
		return result.position # Returns a Vector3 (X, Y, Z)
	else:
		print("null")
		return null

# -----------------------------
# Andrea Placement (Cream Poof)
# -----------------------------
# Places current object at mouse coordinates
# Calls getMouseCoords
func placeAtMouse() -> void:
	var world_position = getMouseCoords()
	if world_position == null:
		return
	# Instance of new object to place
	var new_object = itemToPlace.instantiate()
	# Place in scene
	add_child(new_object)
	new_object.global_position = world_position + Vector3(0, 0, 0)

# -----------------------------
# Glen Grid Wall Placement
# -----------------------------
func _try_place_wall(length_in_cells: int):
	var grid_pos := _get_mouse_grid_position()
	if grid_pos == Vector2i.ZERO and not _mouse_hits_something(): 
		# Added a safety check: Vector2i.ZERO is valid (0,0), 
		# but usually we want to ensure we actually hit the grid.
		return

	if not _can_place(grid_pos, length_in_cells):
		return

	_place_wall(grid_pos, length_in_cells)

func _mouse_hits_something() -> bool:
	# Helper to distinguish between "Clicked 0,0" and "Clicked nothing"
	return getMouseCoords() != null

func _get_mouse_grid_position() -> Vector2i:
	var world_pos = getMouseCoords()
	if world_pos == null:
		return Vector2i.ZERO

	# Grid math
	return Vector2i(int(floor(world_pos.x / cell_size)), int(floor(world_pos.z / cell_size)))

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

	for i in length:
		var cell = Vector2i(start.x + i, start.y)
		var stack = _ensure_cell_stack(cell)
		stack.append(wall)

# -----------------------------
# Scratch discard
# -----------------------------
"""
var cream_poof_scene = preload("res://Scenes/creamPoof.tscn")

# On button press, adds an instance of creamPoof randomly to scene
func _on_add_cream_pressed() -> void:
	var newPoof = cream_poof_scene.instantiate()
	var randX = randf_range(-5, 5)
	var randZ = randf_range(-5, 5)
	newPoof.position = Vector3(randX, 5, randZ)
	add_child(newPoof)
"""
