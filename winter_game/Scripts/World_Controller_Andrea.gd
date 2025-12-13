extends Node3D


# All the meshes to load into menu bar
# var thingToPlace_scene = preload("filepath_")
var creamPoofScene = preload("res://Scenes/creamPoof.tscn")

# Global variable to store which object currently placing
# null if not placing any menu items, initiated as null
var itemToPlace = null

# Determine which object we are placing - one function per menu button
func placeCream() -> void:
	itemToPlace = creamPoofScene
	print("Tool selected: creamPoof")

# If we are placing an object, get the mouse coords and place
func _unhandled_input(event):
	if itemToPlace == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		placeAtMouse()

# Gets mouse coords
func getMouseCoords():
	var camera = $Camera3D
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
