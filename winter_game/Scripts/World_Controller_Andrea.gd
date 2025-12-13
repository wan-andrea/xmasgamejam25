extends Node3D



var cream_poof_scene = preload("res://Scenes/creamPoof.tscn")

# On button press, adds an instance of creamPoof randomly to scene
func _on_add_cream_pressed() -> void:
	var newPoof = cream_poof_scene.instantiate()
	var randX = randf_range(-5, 5)
	var randZ = randf_range(-5, 5)
	newPoof.position = Vector3(randX, 5, randZ)
	add_child(newPoof)
