extends Control

signal scene_cleaned_up
var cleaned_up := false

onready var CustomButton = load("res://Classes/CustomButton.gd")
onready var GameServer := $"/root/Network/GameServer"

onready var mode_buttons_tween: Tween = $"Tweens/ModeButtonsTween"
onready var mode_description_tween: Tween = $"Tweens/ModeDescriptionTween"
onready var friends_menu_tween: DynamicTween = $"Tweens/FriendsMenuTween"

onready var blitz_button: CustomButton = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/ModeButtons/Blitz"
onready var classic_button: CustomButton = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/ModeButtons/Classic"
onready var bullet_button: CustomButton = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/ModeButtons/Bullet"
onready var play_button: CustomButton = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play"
onready var modes_button: CustomButton = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/Modes"
onready var logout_button: CustomButton = $"CanvasLayer/PlayMenu/VBoxContainer/LogoutContainer/Logout"
onready var mode_description: Panel = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/ModeDescription"
onready var error_text_dialog: AcceptDialog = $"CanvasLayer2/ErrorText"
onready var tint: ColorRect = $"CanvasLayer2/Tint"
onready var friends_panel = $"CanvasLayer/PlayMenu/FriendsMenu/FriendsPanel/Panel"

#Preload all textures:
var t_menu_button_gray_unpressed = preload("res://Assets/menu_button_gray_unpressed.png")
var t_menu_button_gray_pressed = preload("res://Assets/menu_button_gray_pressed.png")
var t_menu_button_orange_unpressed = preload("res://Assets/menu_button_orange_unpressed.png")
var t_menu_button_orange_pressed = preload("res://Assets/menu_button_orange_pressed.png")
var t_menu_button_purple_unpressed = preload("res://Assets/menu_button_purple_unpressed.png")
var t_menu_button_purple_pressed = preload("res://Assets/menu_button_purple_pressed.png")
var t_menu_button_red_unpressed = preload("res://Assets/menu_button_red_unpressed.png")
var t_menu_button_red_pressed = preload("res://Assets/menu_button_red_pressed.png")
var t_menu_button_yellow_unpressed = preload("res://Assets/menu_button_yellow_unpressed.png")
var t_menu_button_yellow_pressed = preload("res://Assets/menu_button_yellow_pressed.png")

var mode_buttons_shown := false
var looking_for_game := false
var game_mode: String
var error_text_source: String #"gameserver_disconnect" or "logged_into_warning"


func _ready() -> void:
	var scene_data: Dictionary = Scenes.transferred_scene_data
	Scenes.on_scene_loaded()
	error_text_dialog.get_close_button().visible = false
	match GlobalData.game_mode_pref:
		"classic":
			game_mode = "classic"
			bullet_button.set_texture("normal", t_menu_button_gray_unpressed)
			bullet_button.set_texture("pressed", t_menu_button_gray_pressed)
			classic_button.set_texture("normal", t_menu_button_orange_unpressed)
			classic_button.set_texture("pressed", t_menu_button_orange_pressed)
			blitz_button.set_texture("normal", t_menu_button_gray_unpressed)
			blitz_button.set_texture("pressed", t_menu_button_gray_pressed)
		"blitz":
			game_mode = "blitz"
			play_button.get_node("SelectedMode").text = "Blitz"
			bullet_button.set_texture("normal", t_menu_button_gray_unpressed)
			bullet_button.set_texture("pressed", t_menu_button_gray_pressed)
			classic_button.set_texture("normal", t_menu_button_gray_unpressed)
			classic_button.set_texture("pressed", t_menu_button_gray_pressed)
			blitz_button.set_texture("normal", t_menu_button_orange_unpressed)
			blitz_button.set_texture("pressed", t_menu_button_orange_pressed)
		"bullet":
			game_mode = "bullet"
			bullet_button.set_texture("normal", t_menu_button_orange_unpressed)
			bullet_button.set_texture("pressed", t_menu_button_orange_pressed)
			classic_button.set_texture("normal", t_menu_button_gray_unpressed)
			classic_button.set_texture("pressed", t_menu_button_gray_pressed)
			blitz_button.set_texture("normal", t_menu_button_gray_unpressed)
			blitz_button.set_texture("pressed", t_menu_button_gray_pressed)	
			play_button.get_node("SelectedMode").text = "Bullet"
	
	set_mode_buttons_visibility(false)
	
	$"CanvasLayer/PlayMenu/VBoxContainer/Version".text = "Beta v" + GlobalData.version
	$"CanvasLayer/PlayMenu/VBoxContainer/Username".text = GlobalData.displayname
	$"CanvasLayer/PlayMenu/VBoxContainer/ServerDetails".text = "Server: " + str(GlobalData.gameserver_name)
	if (GlobalData.latest_version != ""):
		$"CanvasLayer/PlayMenu/NewVersionReminder".dialog_text = "There's a new version available!\nUpdate to v" + GlobalData.latest_version + " in #releases when possible."
		$"CanvasLayer/PlayMenu/NewVersionReminder".popup()
	
	var enable_buttons := true
	if (scene_data.has("account_already_logged_on_time")):
		Logger.error("Account logged in from another location on " + str(OS.get_datetime_from_unix_time(scene_data.account_already_logged_on_time)) + ".", Logger.WARNING)
		CustomButtons.disable()
		enable_buttons = false
		tint.visible = true
		error_text_dialog.dialog_text = "You're already logged in from another device, we've disconnected them."
		error_text_source = "logged_into_warning"
		error_text_dialog.show()
	if (scene_data.has("created_new_account") && scene_data["created_new_account"] == true):
		CustomButtons.disable()
		enable_buttons = false
		tint.visible = true
		$"%CreateAccountSuggestion".dialog_text = "Would you like to create an account to save your progress?"
		$"%CreateAccountSuggestion".add_button("NO", true, "no")
		$"%CreateAccountSuggestion".show()
	CustomButtons.set_enabled(enable_buttons)
	
	if (GlobalData.test_music and !GlobalData.temp_music_run_before):
		AudioPlayer.play_sound("main_menu_music")
	GlobalData.temp_music_run_before = true
	

func clean_up_scene() -> void: #Ran right before the scene is switched - blocking
	cleaned_up = true
	emit_signal("scene_cleaned_up")
	
func _process(delta) -> void:
	var anim = $"ParallaxBackground/ParallaxLayer"
	anim.motion_offset = Vector2(anim.position.x - 0.5, anim.position.y + 0.5)

#Called when a game is found
func on_game_found() -> void:
	AudioPlayer.play_sound("match_found")
	$"CanvasLayer/PlayMenu/LookingForGame/Label".text = "Game Found!"
	$"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/Label".text = "Loading..."
	$"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play".disabled = true
	$"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play".texture_disabled = t_menu_button_gray_pressed
	CustomButtons.disable()


#--------------------------------Button Signals--------------------------------:

func _on_Modes_button_pressed() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/Modes/Label"
	label.rect_position.y = 0 + 12

func _on_Modes_button_released() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/Modes/Label"
	label.rect_position.y = 0
	
	modes_button.enabled = false
	var mode_buttons: Control = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/ModeButtons"
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
		blitz_button.enabled = true
		classic_button.enabled = true
		bullet_button.enabled = true
	mode_buttons_shown = !mode_buttons_shown
	modes_button.enabled = true

func set_mode_buttons_visibility(visible: bool) -> void:
	var value := 0
	if (visible):
		value = 1
	for child in $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/ModeButtons".get_children():
		child.modulate.a = value
	
	
func _on_Modes_button_left_area() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/ModesContainer/Modes/Label"
	label.rect_position.y = 0
	
	
func _on_Play_button_pressed() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/Label"
	var selected_mode: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/SelectedMode"
	label.rect_position.y = 0 + 12
	selected_mode.rect_position.y = 38 + 12

func _on_Play_button_released() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/Label"
	var selected_mode: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/SelectedMode"
	label.rect_position.y = 0
	selected_mode.rect_position.y = 38
	
	if (!looking_for_game):
		play_button.get_node("Label").text = "CANCEL"
		play_button.set_texture("normal", t_menu_button_red_unpressed)
		play_button.set_texture("pressed", t_menu_button_red_pressed)
		$CanvasLayer/PlayMenu/LookingForGame.visible = true
		GameServer.queue_for_game_request(game_mode)
		looking_for_game = true
	else:
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", t_menu_button_orange_unpressed)
		play_button.set_texture("pressed", t_menu_button_orange_pressed)
		$CanvasLayer/PlayMenu/LookingForGame.visible = false
		GameServer.remove_from_queue_request(game_mode)
		looking_for_game = false
	
func _on_Play_button_left_area() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/Label"
	var selected_mode: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Play/SelectedMode"
	label.rect_position.y = 0
	selected_mode.rect_position.y = 38

func _on_Custom_button_pressed() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Custom/Label"
	var label2: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Custom/Label2"
	label.rect_position.y = 0 + 12
	label2.rect_position.y = -49.8 + 12

func _on_Custom_button_released() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Custom/Label"
	var label2: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Custom/Label2"
	label.rect_position.y = 0
	label2.rect_position.y = -49.8

func _on_Custom_button_left_area() -> void:
	var label: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Custom/Label"
	var label2: Label = $"CanvasLayer/PlayMenu/MiddleButtons/HBoxContainer/Custom/Label2"
	label.rect_position.y = 0
	label2.rect_position.y = -49.8


func _on_Blitz_button_pressed() -> void:
	blitz_button.get_node("Label").rect_position.y = -15.714 + 12
	blitz_button.get_node("Icon").rect_position.y = 39.286 + 12

func _on_Blitz_button_released() -> void:
	blitz_button.get_node("Label").rect_position.y = -15.714
	blitz_button.get_node("Icon").rect_position.y = 39.286
	
	play_button.get_node("SelectedMode").text = "Blitz"
	bullet_button.set_texture("normal", t_menu_button_gray_unpressed)
	bullet_button.set_texture("pressed", t_menu_button_gray_pressed)
	classic_button.set_texture("normal", t_menu_button_gray_unpressed)
	classic_button.set_texture("pressed", t_menu_button_gray_pressed)
	blitz_button.set_texture("normal", t_menu_button_orange_unpressed)
	blitz_button.set_texture("pressed", t_menu_button_orange_pressed)
	if (looking_for_game and game_mode != "blitz"):
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", t_menu_button_orange_unpressed)
		play_button.set_texture("pressed", t_menu_button_orange_pressed)
		$CanvasLayer/PlayMenu/LookingForGame.visible = false
		GameServer.remove_from_queue_request("blitz")
		looking_for_game = false
	game_mode = "blitz"
	GlobalData.game_mode_pref = game_mode
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
	
	bullet_button.set_texture("normal", t_menu_button_orange_unpressed)
	bullet_button.set_texture("pressed", t_menu_button_orange_pressed)
	classic_button.set_texture("normal", t_menu_button_gray_unpressed)
	classic_button.set_texture("pressed", t_menu_button_gray_pressed)
	blitz_button.set_texture("normal", t_menu_button_gray_unpressed)
	blitz_button.set_texture("pressed", t_menu_button_gray_pressed)	
	play_button.get_node("SelectedMode").text = "Bullet"
	if (looking_for_game and game_mode != "bullet"):
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", t_menu_button_orange_unpressed)
		play_button.set_texture("pressed", t_menu_button_orange_pressed)
		$CanvasLayer/PlayMenu/LookingForGame.visible = false
		GameServer.remove_from_queue("bullet")
		looking_for_game = false
	game_mode = "bullet"
	GlobalData.game_mode_pref = game_mode	
	Global.update_data_file("mode", game_mode)	

func _on_Bullet_button_left_area() -> void:
	bullet_button.get_node("Label").rect_position.y = -15.714
	bullet_button.get_node("Icon").rect_position.y = 39.286

func _on_Classic_button_pressed() -> void:
	classic_button.get_node("Label").rect_position.y = 0 + 12

func _on_Classic_button_released() -> void:
	classic_button.get_node("Label").rect_position.y = 0
	
	bullet_button.set_texture("normal", t_menu_button_gray_unpressed)
	bullet_button.set_texture("pressed", t_menu_button_gray_pressed)
	classic_button.set_texture("normal", t_menu_button_orange_unpressed)
	classic_button.set_texture("pressed", t_menu_button_orange_pressed)
	blitz_button.set_texture("normal", t_menu_button_gray_unpressed)
	blitz_button.set_texture("pressed", t_menu_button_gray_pressed)
	play_button.get_node("SelectedMode").text = "Classic"
	if (looking_for_game and game_mode != "classic"):
		play_button.get_node("Label").text = "PLAY"
		play_button.set_texture("normal", t_menu_button_orange_unpressed)
		play_button.set_texture("pressed", t_menu_button_orange_pressed)
		$CanvasLayer/PlayMenu/LookingForGame.visible = false
		GameServer.remove_from_queue_request("classic")
		looking_for_game = false
	game_mode = "classic"
	GlobalData.game_mode_pref = game_mode
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
	mode_description.get_node("Label").text = "30 seconds each\n(0.5|0.5)"
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
	
func _on_Logout_button_pressed():
	logout_button.get_node("Label").rect_position.y = 0 + 6

func _on_Logout_button_released():
	logout_button.get_node("Label").rect_position.y = 0
	Logger.log("Logging out of account.")
	GameServer.reset_auth_token_request()
	yield(get_tree(), "physics_frame") #Wait for above method execution
	yield(get_tree(), "physics_frame") #Wait for above method execution
	
	var auth_token_file := File.new()
	auth_token_file.open("user://Data/login_data.json", File.WRITE)
	auth_token_file.store_line(JSON.print({"username": GlobalData.username, "auth_token": ""}, "\t"))
	auth_token_file.close()
	GlobalData.auth_token = ""

	GameServer.close_connection()
	Scenes.change_scene(Scenes.BootScreen_path, {"logged_out": true}, false)
	
func _on_Logout_button_left_area():
	logout_button.get_node("Label").rect_position.y = 0

func _on_ErrorText_confirmed() -> void:
	match error_text_source:
		"logged_into_warning":
			CustomButtons.enable()
			tint.visible = false
		"gameserver_disconnect":
			Scenes.change_scene(Scenes.BootScreen_path, {})

func _on_CreateAccountSuggestion_confirmed():
	$"%NewPasswordContainer".visible = true
	CustomButtons.enable()
	CustomButtons.set_enabled_individually_for_all_buttons(false)
	$"%NewPasswordContainer".get_node("Proceed").enabled = true

func _on_CreateAccountSuggestion_custom_action(action):
	if (action == "no"):
		$"%CreateAccountSuggestion".visible = false
		$"%NewPasswordContainer".visible = false
		CustomButtons.enable()
		tint.visible = false	

var started := false
func _on_FriendButton_button_released():
	if (!started):
		friends_menu_tween.stop_all()
		friends_menu_tween.interpolate_property(friends_panel, "rect_position", Vector2(0, 0), Vector2(-200, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		friends_menu_tween.start()
	else:
		friends_menu_tween.stop_all()
		friends_menu_tween.interpolate_property(friends_panel, "rect_position", Vector2(-200, 0), Vector2(0, 0), 0.5, mode_buttons_tween.TRANS_CUBIC, mode_buttons_tween.EASE_OUT)
		friends_menu_tween.start()
	started = !started


func _on_Proceed_button_pressed():
	$"%NewPasswordContainer".get_node("Proceed/Label").rect_position.y = 0 + 6

func _on_Proceed_button_released():
	$"%NewPasswordContainer".get_node("Proceed/Label").rect_position.y = 0
	GameServer.replace_temp_password_request($"%NewPasswordContainer".get_node("Password").text.sha256_text())
	$"%NewPasswordContainer".visible = false
	tint.visible = false
	CustomButtons.set_enabled_individually_for_all_buttons(true)
	
func _on_Proceed_button_left_area():
	$"%NewPasswordContainer".get_node("Proceed/Label").rect_position.y = 0

