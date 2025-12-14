extends Control

@onready var title_label = $CenterContainer/VBoxContainer/Label
@onready var info_label = $CenterContainer/VBoxContainer/Label2

func setup(is_victory: bool, score: int):
	if is_victory:
		title_label.text = "You Win!"
	else:
		title_label.text = "Game Over"

	info_label.text = "Score: %d" % score
