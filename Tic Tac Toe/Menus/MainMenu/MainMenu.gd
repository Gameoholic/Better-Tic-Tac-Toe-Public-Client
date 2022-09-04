extends Control

onready var GameServer_ := $"/root/Network/GameServer"

#onready var bottom_bar_outline := $"CanvasLayer/BottomBar/Background/Outline"
#onready var bottom_bar_title:= $"CanvasLayer/BottomBar/Background/Title"
onready var CustomButton = load("res://Classes/CustomButton.gd")

onready var mode_buttons_tween: Tween = $ModeButtonsTween
onready var mode_description_tween: Tween = $ModeDescriptionTween
onready var blitz_button: CustomButton = $"PlayMenu/MiddleButtons/ModesContainer/ModeButtons/Blitz"
onready var classic_button: CustomButton = $"PlayMenu/MiddleButtons/ModesContainer/ModeButtons/Classic"
onready var bullet_button: CustomButton = $"PlayMenu/MiddleButtons/ModesContainer/ModeButtons/Bullet"
onready var play_button: CustomButton = $"PlayMenu/MiddleButtons/HBoxContainer/Play"
onready var modes_button: CustomButton = $"PlayMenu/MiddleButtons/ModesContainer/Modes"
onready var mode_description: Panel = $"PlayMenu/MiddleButtons/ModesContainer/ModeDescription"

var mode_buttons_shown := false
var looking_for_game := false
var game_mode: String

func _ready() -> void:
	$"PlayMenu/VBoxContainer/Version".text = "v" + GlobalData.version
	$"PlayMenu/VBoxContainer/Username".text = GlobalData.displayname
	$"PlayMenu/VBoxContainer/ServerDetails".text = "Server: " + str(GlobalData.gameserver_port)
	if (GlobalData.latest_version != ""):
		$"PlayMenu/NewVersionReminder".dialog_text = "There's a new version available!\nUpdate to v" + GlobalData.latest_version + " in #releases when possible."
		$"PlayMenu/NewVersionReminder".popup()
	
	#Initialize custom buttons:
	CustomButtons.enable()
	set_mode_buttons_visibility(false)
	
	#-
	match GlobalData.game_mode_pref:
		"classic":
			game_mode = "classic"
			bullet_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
			bullet_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
			classic_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
			classic_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
			blitz_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
			blitz_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
		"blitz":
			game_mode = "blitz"
			play_button.get_node("SelectedMode").text = "Blitz"
			bullet_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
			bullet_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
			classic_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
			classic_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
			blitz_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
			blitz_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
		"bullet":
			game_mode = "bullet"
			bullet_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
			bullet_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
			classic_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
			classic_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
			blitz_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
			blitz_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))	
			play_button.get_node("SelectedMode").text = "Bullet"

#func move_to_menu(menu: String):
#	match menu:
#		"stats_menu":
#			#Camera:
#			mode_buttons_tween.interpolate_property($Camera, "offset", $Camera.offset, Vector2(-menu_origin_size.x, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#			#Outline:
#			mode_buttons_tween.interpolate_property(bottom_bar_outline, "rect_position", bottom_bar_outline.rect_position, Vector2(150, bottom_bar_outline.rect_position.y), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#			#Title:
#			bottom_bar_title.rect_position = Vector2(125, bottom_bar_title.rect_position.y)
#			bottom_bar_title.text = "Stats"
#			mode_buttons_tween.interpolate_property(bottom_bar_title, "modulate:a", 0, 1, 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#		"customize_menu":
#			#Camera:
#			mode_buttons_tween.interpolate_property($Camera, "offset", $Camera.offset, Vector2(menu_origin_size.x, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#			#Outline:
#			mode_buttons_tween.interpolate_property(bottom_bar_outline, "rect_position", bottom_bar_outline.rect_position, Vector2(450, bottom_bar_outline.rect_position.y), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#			#Title:
#			bottom_bar_title.rect_position = Vector2(425, bottom_bar_title.rect_position.y)
#			bottom_bar_title.text = "Customize"
#			mode_buttons_tween.interpolate_property(bottom_bar_title, "modulate:a", 0, 1, 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#		"play_menu":
#			#Camera:
#			mode_buttons_tween.interpolate_property($Camera, "offset", $Camera.offset, Vector2(0, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#			#Outline:
#			mode_buttons_tween.interpolate_property(bottom_bar_outline, "rect_position", bottom_bar_outline.rect_position, Vector2(300, bottom_bar_outline.rect_position.y), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#			#Title:
#			bottom_bar_title.rect_position = Vector2(275, bottom_bar_title.rect_position.y)
#			bottom_bar_title.text = "Play"
#			mode_buttons_tween.interpolate_property(bottom_bar_title, "modulate:a", 0, 1, 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
#	mode_buttons_tween.start()
	


#func _on_Customize_pressed() -> void:
#	move_to_menu("customize_menu")
#
#
#func _on_Play_pressed() -> void:
#	move_to_menu("play_menu")
#
#
#func _on_Stats_pressed() -> void:
#	move_to_menu("stats_menu")
	
	

#updateon resize()

#Called when a game is found
func on_game_found() -> void:
	$"PlayMenu/LookingForGame/Label".text = "Game Found!"
	$"PlayMenu/MiddleButtons/HBoxContainer/Play/Label".text = "Loading..."
	$"PlayMenu/MiddleButtons/HBoxContainer/Play".disabled = true
	$"PlayMenu/MiddleButtons/HBoxContainer/Play".texture_disabled = load("res://Assets/menu_button_gray_pressed.png")


#--------------------------------Button Signals--------------------------------:

func _on_Modes_button_pressed() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/ModesContainer/Modes/Label"
	label.rect_position.y = 0 + 12

func _on_Modes_button_released() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/ModesContainer/Modes/Label"
	label.rect_position.y = 0
	
	modes_button.enabled = false
	var mode_buttons: Control = $"PlayMenu/MiddleButtons/ModesContainer/ModeButtons"
	if (!mode_buttons_shown):
		#Reset mode buttons:
		set_mode_buttons_visibility(true)
		blitz_button.enabled = true
		classic_button.enabled = true
		bullet_button.enabled = true
		classic_button.rect_position = Vector2(129, 0)
		blitz_button.rect_position = Vector2(129, 0)
		bullet_button.rect_position = Vector2(129, 0)
		#Start mode buttons animation:
		mode_buttons_tween.interpolate_property(mode_buttons, "rect_position", Vector2(mode_buttons.rect_position.x, 0), Vector2(mode_buttons.rect_position.x, -100), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		mode_buttons_tween.start()
		yield(get_tree().create_timer(0.3), "timeout")
		mode_buttons_tween.interpolate_property(blitz_button, "rect_position", Vector2(129, blitz_button.rect_position.y), Vector2(0, blitz_button.rect_position.y), 0.4, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		mode_buttons_tween.interpolate_property(bullet_button, "rect_position", Vector2(129, bullet_button.rect_position.y), Vector2(258, bullet_button.rect_position.y), 0.4, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		yield(get_tree().create_timer(0.4), "timeout")
	else:
		#Reset mode buttons:
		classic_button.rect_position = Vector2(129, 0)
		blitz_button.rect_position = Vector2(0, 0)
		bullet_button.rect_position = Vector2(258, 0)
		#Start mode buttons animation:
		mode_buttons_tween.interpolate_property(blitz_button, "rect_position", Vector2(0, blitz_button.rect_position.y), Vector2(129, blitz_button.rect_position.y), 0.4, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		mode_buttons_tween.interpolate_property(bullet_button, "rect_position", Vector2(258, bullet_button.rect_position.y), Vector2(129, bullet_button.rect_position.y), 0.4, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		mode_buttons_tween.start()
		yield(get_tree().create_timer(0.3), "timeout")
		mode_buttons_tween.interpolate_property(mode_buttons, "rect_position", Vector2(mode_buttons.rect_position.x, -100), Vector2(mode_buttons.rect_position.x, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		yield(get_tree().create_timer(0.5), "timeout")
		set_mode_buttons_visibility(false)
		blitz_button.enabled = false
		classic_button.enabled = false
		bullet_button.enabled = false
	mode_buttons_shown = !mode_buttons_shown
	modes_button.enabled = true

func set_mode_buttons_visibility(visible: bool) -> void:
	var value := 0
	if (visible):
		value = 1
	for child in $"PlayMenu/MiddleButtons/ModesContainer/ModeButtons".get_children():
		child.modulate.a = value
	
	
func _on_Modes_button_left_area() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/ModesContainer/Modes/Label"
	label.rect_position.y = 0
	
	
func _on_Play_button_pressed() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Play/Label"
	var selected_mode: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Play/SelectedMode"
	label.rect_position.y = 0 + 12
	selected_mode.rect_position.y = 38 + 12

func _on_Play_button_released() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Play/Label"
	var selected_mode: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Play/SelectedMode"
	label.rect_position.y = 0
	selected_mode.rect_position.y = 38
	
	if (!looking_for_game):
		play_button.get_node("Label").text = "CANCEL"
		play_button.set_texture("normal", load("res://Assets/menu_button_red_unpressed.png"))
		play_button.set_texture("pressed", load("res://Assets/menu_button_red_pressed.png"))
		$PlayMenu/LookingForGame.visible = true
		GameServer_.queue_for_game(game_mode)
		looking_for_game = true
	else:
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
		play_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
		$PlayMenu/LookingForGame.visible = false
		GameServer_.remove_from_queue(game_mode)
		looking_for_game = false
	
func _on_Play_button_left_area() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Play/Label"
	var selected_mode: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Play/SelectedMode"
	label.rect_position.y = 0
	selected_mode.rect_position.y = 38


func _on_Custom_button_pressed() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Custom/Label"
	label.rect_position.y = 0 + 12

func _on_Custom_button_released() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Custom/Label"
	label.rect_position.y = 0

func _on_Custom_button_left_area() -> void:
	var label: Label = $"PlayMenu/MiddleButtons/HBoxContainer/Custom/Label"
	label.rect_position.y = 0


func _on_Blitz_button_pressed() -> void:
	blitz_button.get_node("Label").rect_position.y = -15.714 + 12
	blitz_button.get_node("Icon").rect_position.y = 39.286 + 12

func _on_Blitz_button_released() -> void:
	blitz_button.get_node("Label").rect_position.y = -15.714
	blitz_button.get_node("Icon").rect_position.y = 39.286
	
	play_button.get_node("SelectedMode").text = "Blitz"
	bullet_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
	bullet_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
	classic_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
	classic_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
	blitz_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
	blitz_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
	if (looking_for_game and game_mode != "blitz"):
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
		play_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
		$PlayMenu/LookingForGame.visible = false
		GameServer_.remove_from_queue("blitz")
		looking_for_game = false
	game_mode = "blitz"
	Global.update_data_file("mode", game_mode)	

func _on_Blitz_button_left_area() -> void:
	blitz_button.get_node("Label").rect_position.y = -15.714
	blitz_button.get_node("Icon").rect_position.y = 39.286

func _on_Bullet_button_pressed() -> void:
	bullet_button.get_node("Label").rect_position.y = -15.714 + 12
	bullet_button.get_node("Icon").rect_position.y = 39.286 + 12

func _on_Bullet_button_released() -> void:
	bullet_button.get_node("Label").rect_position.y = -15.714
	bullet_button.get_node("Icon").rect_position.y = 39.286
	
	bullet_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
	bullet_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
	classic_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
	classic_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
	blitz_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
	blitz_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))	
	play_button.get_node("SelectedMode").text = "Bullet"
	if (looking_for_game and game_mode != "bullet"):
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
		play_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
		$PlayMenu/LookingForGame.visible = false
		GameServer_.remove_from_queue("bullet")
		looking_for_game = false
	game_mode = "bullet"
	Global.update_data_file("mode", game_mode)	

func _on_Bullet_button_left_area() -> void:
	bullet_button.get_node("Label").rect_position.y = -15.714
	bullet_button.get_node("Icon").rect_position.y = 39.286

func _on_Classic_button_pressed() -> void:
	classic_button.get_node("Label").rect_position.y = 0 + 12

func _on_Classic_button_released() -> void:
	classic_button.get_node("Label").rect_position.y = 0
	
	bullet_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
	bullet_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
	classic_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
	classic_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
	blitz_button.set_texture("normal", load("res://Assets/menu_button_gray_unpressed.png"))
	blitz_button.set_texture("pressed", load("res://Assets/menu_button_gray_pressed.png"))
	play_button.get_node("SelectedMode").text = "Classic"
	if (looking_for_game and game_mode != "classic"):
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", load("res://Assets/menu_button_orange_unpressed.png"))
		play_button.set_texture("pressed", load("res://Assets/menu_button_orange_pressed.png"))
		$PlayMenu/LookingForGame.visible = false
		GameServer_.remove_from_queue("classic")
		looking_for_game = false
	game_mode = "classic"
	Global.update_data_file("mode", game_mode)

func _on_Classic_button_left_area() -> void:
	classic_button.get_node("Label").rect_position.y = 0




func _on_Blitz_mouse_hover() -> void:
	mode_buttons_tween.stop_all()	
	mode_description.get_node("Label").text = "1 minute each\n+1 second per turn\n(1|1)"
	mode_buttons_tween.interpolate_property(mode_description, "modulate", mode_description.modulate, Color(1, 1, 1, 1), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
	mode_buttons_tween.start()

func _on_Blitz_mouse_stop_hover() -> void:
	mode_buttons_tween.stop_all()	
	mode_buttons_tween.interpolate_property(mode_description, "modulate", mode_description.modulate, Color(1, 1, 1, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
	mode_buttons_tween.start()

func _on_Bullet_mouse_hover() -> void:
	mode_buttons_tween.stop_all()	
	mode_description.get_node("Label").text = "30 seconds each\n(0.5|0)"
	mode_buttons_tween.interpolate_property(mode_description, "modulate", mode_description.modulate, Color(1, 1, 1, 1), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
	mode_buttons_tween.start()

func _on_Bullet_mouse_stop_hover() -> void:
	mode_buttons_tween.stop_all()
	mode_buttons_tween.interpolate_property(mode_description, "modulate", mode_description.modulate, Color(1, 1, 1, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
	mode_buttons_tween.start()

func _on_Classic_mouse_hover() -> void:
	mode_buttons_tween.stop_all()
	mode_description.get_node("Label").text = "3 minutes each\n+2 seconds per turn\n(3|2)"
	mode_buttons_tween.interpolate_property(mode_description, "modulate", mode_description.modulate, Color(1, 1, 1, 1), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
	mode_buttons_tween.start()

func _on_Classic_mouse_stop_hover() -> void:
	mode_buttons_tween.stop_all()	
	mode_buttons_tween.interpolate_property(mode_description, "modulate", mode_description.modulate, Color(1, 1, 1, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
	mode_buttons_tween.start()
