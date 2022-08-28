extends Control

onready var GameServer_ := $"/root/Network/GameServer"
onready var modes_button := $Modes
onready var play_button := $"HBoxContainer/Play"
onready var custom_button := $"HBoxContainer/Custom"
onready var looking_for_game_panel := $"../LookingForGame"

var looking_for_game := false
var game_mode := "classic"

func _on_Play_pressed() -> void:
	if (!looking_for_game):
		play_button.get_node("Label").text = "CANCEL"
		play_button.texture_normal = load("res://Assets/menu_button_red_unpressed.png")
		play_button.texture_pressed = load("res://Assets/menu_button_red_pressed.png")
		looking_for_game_panel.visible = true
		GameServer_.queue_for_game(game_mode)
		looking_for_game = true
	else:
		play_button.get_node("Label").text = "PLAY"
		play_button.texture_normal = load("res://Assets/menu_button_orange_unpressed.png")
		play_button.texture_pressed = load("res://Assets/menu_button_orange_pressed.png")
		looking_for_game_panel.visible = false
		GameServer_.remove_from_queue(game_mode)
		looking_for_game = false

func _on_Play_button_down() -> void:
	play_button.get_node("Label").rect_position.y += 12
	play_button.get_node("SelectedMode").rect_position.y += 12
func _on_Modes_button_down() -> void:
	modes_button.get_node("Label").rect_position.y += 12
func _on_Custom_button_down() -> void:
	custom_button.get_node("Label").rect_position.y += 12
func _on_Play_button_up() -> void:
	play_button.get_node("Label").rect_position.y -= 12
	play_button.get_node("SelectedMode").rect_position.y -= 12
func _on_Modes_button_up() -> void:
	modes_button.get_node("Label").rect_position.y -= 12
func _on_Custom_button_up() -> void:
	custom_button.get_node("Label").rect_position.y -= 12


