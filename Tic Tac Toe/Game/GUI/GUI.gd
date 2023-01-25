extends Node2D

onready var GameServer := $"/root/Network/GameServer"

enum {O, X, Expansion, Empty}

var game_container_node: Node #Is either game_container_node or $Tutorial

func show_victory_GUI(mark: String) -> void:
	$"VictoryGUI/Main/VictoryRect/Text".text = str(mark) + " won!"
	$"VictoryGUI/Main".visible = true

func _on_GameButton_pressed() -> void:
	Scenes.Game.emit_signal("button_clicked")

func _on_ExpansionButton_pressed():
	Scenes.Game.emit_signal("expansion_button_clicked")	
	
func _on_GoBackButton_pressed() -> void:
	Scenes.change_scene(Scenes.MainMenu_path)

func _on_Leave_button_pressed() -> void:
	var label: Label = $"Leave/Label"
	label.rect_position.y = 0 + 6

func _on_Leave_button_released() -> void:
	var label: Label = $"Leave/Label"
	label.rect_position.y = 0
	Scenes.change_scene(Scenes.MainMenu_path)
	if (!Scenes.Game.is_tutorial and !game_container_node.game_ended):
		game_container_node.send_game_data({"surrender": true})

func _on_Leave_button_left_area() -> void:
	var label: Label = $"Leave/Label"
	label.rect_position.y = 0
