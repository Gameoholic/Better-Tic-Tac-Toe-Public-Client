extends Node2D

onready var Game_: Node = get_node("/root/Game")

func show_victory_GUI(mark: String) -> void:
	$"VictoryGUI/Main/VictoryRect/Text".text = str(mark) + " won!"
	$"VictoryGUI/Main".visible = true
	$"VictoryGUI/GoBack".visible = false
#GameButton:
func _on_Button_pressed() -> void:
	Game_.emit_signal("button_clicked")

func _on_GoBackButton_pressed() -> void:
	CustomButtons.enable()
	get_tree().change_scene("res://Menus/MainMenu/MainMenu.tscn")

func _on_CloseButton_pressed() -> void:
	$"VictoryGUI/Main".visible = false
	$"VictoryGUI/GoBack".visible = true
