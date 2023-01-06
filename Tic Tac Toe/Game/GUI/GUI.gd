extends Node2D

onready var GameServer := $"/root/Network/GameServer"

enum {O, X, Expansion, Empty}

func show_victory_GUI(mark: String) -> void:
	$"VictoryGUI/Main/VictoryRect/Text".text = str(mark) + " won!"
	$"VictoryGUI/Main".visible = true

func _on_GameButton_pressed() -> void:
	Scenes.Game.emit_signal("button_clicked")

func _on_ExpansionButton_pressed():
	match Scenes.Game.cell_selection_mode:
		"tile":
			Scenes.Game.cell_selection_mode = "expansion"
		"expansion":
			Scenes.Game.cell_selection_mode = "tile"
	GameServer.game_container.visual_update_expansion_button()
	
func _on_GoBackButton_pressed() -> void:
	Scenes.change_scene(Scenes.MainMenu_path)



