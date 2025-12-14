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
	# ESC will get you out of the chosen menu tools
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if itemToPlace != null:
			itemToPlace = null
		# Reset the UI of the button - find the button pressed and release it
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node:
			focused_node.release_focus()
	if itemToPlace == null:
		return
	# place objects on click location
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if itemToPlace == creamPoofScene:
				placeOnFace()
		else:
			placeAtMouse()
			

# Gets mouse coords
func getMouseCoords():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	if result:
		# print(result.position)
		return result.position # Returns a Vector3 (X, Y, Z)
	else:
		# print("null")
		return null

# Returns a Dictionary with { "node": Node3D, "normal": Vector3 }
# Returns empty {} if nothing hit
func objectClicked() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	var result = space_state.intersect_ray(query)
	
	if result and result.has("collider"):
		return {
			"node": result["collider"],
			"normal": result["normal"],     # The world-space normal of the face
			"position": result["position"]  # The exact hit point
		}
	
	return {}
# -----------------------------
# Andrea Placement (Cream Poof)
# -----------------------------
# Debug function check if collides
func is_inside_buildable_area(object: Node3D) -> bool:
	# get the visual boundaries of the buildable area
	var area_aabb: AABB
	# try to find a MeshInstance3D child to get accurate bounds
	var mesh_child = null
	for child in buildableArea.get_children():
		if child is MeshInstance3D:
			mesh_child = child
			break	
	if mesh_child:
		# Get AABB in local space and transform to global space
		area_aabb = mesh_child.get_aabb()
	else:
		push_warning("Buildable Area has no MeshInstance3D to define bounds.")
		return true # Default to true to prevent blocking if setup is wrong
	# Transform the object's position into the Buildable Area's LOCAL space
	var object_local_pos = mesh_child.to_local(object.global_position)
	# Check if that local point is inside the local AABB
	return area_aabb.has_point(object_local_pos)

# Returns true if the two objects' bounding boxes overlap
func check_intersection(node_a: Node3D, node_b: Node3D) -> bool:
	var aabb_a = _get_global_aabb(node_a)
	var aabb_b = _get_global_aabb(node_b)
	# Make slightly smaller so objects we place on top of
	var shrunk_a = aabb_a.grow(-0.01) 
	# The intersection check
	return shrunk_a.intersects(aabb_b)

# Returns true if 'target_object' overlaps with any other Node3D in the relevant containers
func intersects_anything(target_object: Node3D) -> bool:
	# 1. Define the list of objects to check against
	# We combine walls and any other loose objects (like cream poofs)
	var potential_colliders = []
	
	# Add all walls
	potential_colliders.append_array(wall_container.get_children())
	
	# Add other objects (assuming they are direct children of the main script's node)
	# We iterate through children of 'self' (the main Node3D script)
	for child in get_children():
		# Exclude the target object itself so it doesn't collide with itself
		if child != target_object and child is Node3D:
			# Optional: Exclude "System" nodes like Camera, Sunlight, etc.
			if child != camera and child != wall_container and child != buildableArea:
				potential_colliders.append(child)

	# 2. Loop through everything and check for overlap
	for other_object in potential_colliders:
		# Skip if checking against itself (double safety)
		if other_object == target_object:
			continue
			
		# Run the AABB intersection test
		if check_intersection(target_object, other_object):
			# Collision found!
			print("Intersecting with: ", other_object.name)
			return true
			
	# 3. If we finished the loop without returning true, we are safe.
	return false

# Helper to get the bounding box in World Space (Global)
func _get_global_aabb(node: Node3D) -> AABB:
	var mesh_instance = null
	
	# 1. Find the mesh inside the node
	if node is MeshInstance3D:
		mesh_instance = node
	else:
		# Search children for a mesh
		for child in node.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	# 2. Calculate Global AABB
	if mesh_instance:
		# get_aabb() returns Local Space bounds (relative to the object center)
		var local_aabb = mesh_instance.get_aabb()
		# Transform it to Global Space using the object's transform (Position/Rotation/Scale)
		return mesh_instance.global_transform * local_aabb
	
	# Fallback: If no mesh found, return a tiny box at the object's position
	return AABB(node.global_position, Vector3(0.1, 0.1, 0.1))

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
	
	# CHECK: Is it allowed here?
	if not is_inside_buildable_area(new_object) and not intersects_anything(new_object):
		new_object.queue_free() # Delete it immediately
		return

# Helper function for get_snappedNormal which gets cardinal dir
func get_snapped_normal(n: Vector3) -> Vector3:
	# Find which axis has the largest absolute value and snap to it
	if abs(n.y) > abs(n.x) and abs(n.y) > abs(n.z):
		return Vector3(0, sign(n.y), 0) # Top/Bottom
	elif abs(n.x) > abs(n.z):
		return Vector3(sign(n.x), 0, 0) # Left/Right
	else:
		return Vector3(0, 0, sign(n.z)) # Front/Back

# Places an object aligned to the face of the clicked face on mesh 
func placeOnFace() -> void:
	var hit_object = objectClicked()
	# Make sure we actually clicked on object
	var clicked_node = hit_object["node"]
	print(clicked_node, clicked_node.is_in_group("walls"))
	if not hit_object.is_empty() and clicked_node.is_in_group("walls"):
		var click_pos = hit_object["position"]
		var raw_normal = hit_object["normal"]
		# call snapped normal
		var face_normal = get_snapped_normal(raw_normal)
		# create new object
		var new_object = itemToPlace.instantiate()
		add_child(new_object)
		# place it where clicked
		new_object.global_position = click_pos
		# orient object so the Y up is oriented to the face normal
		if face_normal.is_equal_approx(Vector3.UP):
			new_object.rotation_degrees = Vector3.ZERO
		elif face_normal.is_equal_approx(Vector3.DOWN):
			new_object.rotation_degrees = Vector3(180, 0, 0)
		else:
			new_object.look_at(click_pos + face_normal, Vector3.UP)
			new_object.rotate_object_local(Vector3.RIGHT, -PI/2)
			# Prevent object from falling, since it is attached to smth
			if new_object is RigidBody3D:
				# but if it gets hit by stuff in the future 
				# it should fall to gravity
				new_object.freeze = true
				new_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
				new_object.contact_monitor = true
				new_object.max_contacts_reported = 1
				if "anchor_node" in new_object:
					new_object.anchor_node = clicked_node
	else:
		placeAtMouse()
	
	
"""
# -----------------------------
# Glen Grid Wall Placement
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

#
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
	
	if not is_inside_buildable_area(wall):
			print("Wall outside buildable area! Deleting...")
			wall.queue_free()

	# Occupy all cells in the wall
	var stack = []
	for i in length:
		var cell = Vector2i(start.x + i, start.y)
		stack = _ensure_cell_stack(cell)
		stack.append(wall)
		print(get_colliding_object(wall))

# -----------------------------
# Scratch discard
# -----------------------------
var cream_poof_scene = preload("res://Scenes/creamPoof.tscn")

# On button press, adds an instance of creamPoof randomly to scene
func _on_add_cream_pressed() -> void:
	var newPoof = cream_poof_scene.instantiate()
	var randX = randf_range(-5, 5)
	var randZ = randf_range(-5, 5)
	newPoof.position = Vector3(randX, 5, randZ)
	add_child(newPoof)
"""
