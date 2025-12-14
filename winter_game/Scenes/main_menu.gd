extends Control

# This function runs when the button is clicked
func _on_start_button_pressed():
	# This command tells Godot to swap the current scene with "Andrea.tscn"
	print("Pressed...")
	get_tree().change_scene_to_file("res://Scenes/Andrea.tscn")
