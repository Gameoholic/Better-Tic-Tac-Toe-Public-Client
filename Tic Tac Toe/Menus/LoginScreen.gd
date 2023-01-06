extends Control

signal scene_cleaned_up
var cleaned_up := false

onready var Proxy := $"/root/Network/Proxy"
onready var username_input := get_node("Background/CanvasLayer/UIContainer/Username")
onready var password_input := get_node("Background/CanvasLayer/UIContainer/Password")
onready var login_button := get_node("Background/CanvasLayer/UIContainer/LoginButton")
onready var create_account_button := get_node("Background/CanvasLayer/UIContainer/CreateAccountButton")
onready var error_text := get_node("Background/CanvasLayer/UIContainer/ErrorText")
onready var buffer_text := $"CanvasLayer/BufferText"
onready var tint := $"CanvasLayer/Tint"
var remember_login_details := false

func _ready() -> void:
	var scene_data: Dictionary = Scenes.transferred_scene_data
	Scenes.on_scene_loaded()
	
	$"Background/CanvasLayer/UIContainer/Title".text = "Better Tic Tac Toe [BETA]\nv" + GlobalData.version
	if (GlobalData.username != ""):
		username_input.text = GlobalData.username
	if (scene_data.has("logged_out")):
		pass
	else:
		#Check if there's an auth token on the device:
		if (GlobalData.auth_token != ""):
			Logger.log("Logging in with auth token.")
			disable_buttons()
			tint.visible = true
			buffer_text.text = "Logging in as " + GlobalData.username + "..."
			buffer_text.visible = true
			Proxy.connect_to_server(GlobalData.username, GlobalData.auth_token, false, true, "auth_token") #It doesn't matter if the second boolean is true or false

func clean_up_scene() -> void: #Ran right before the scene is switched - blocking
	enable_buttons()
	cleaned_up = true
	emit_signal("scene_cleaned_up")

func _process(delta) -> void:
	var anim = $"ParallaxBackground/ParallaxLayer"
	anim.motion_offset = Vector2(anim.position.x - 0.5, anim.position.y + 0.5)
	
func _on_LoginButton_pressed() -> void:
	if (' ' in username_input.text || ' ' in password_input.text):
		error_text.text = "Your username and password cannot contain spaces."
		return
	if (username_input.text == "" || password_input.text == "" || username_input.text.length() > 15 || password_input.text.length() > 35):
		error_text.text = "Please provide a valid username and password."
		return
			
	for inappropriate_word in GlobalData.inappropriate_words:
		if (inappropriate_word in username_input.text):
			error_text.text = "Please provide a valid username and password."
			return
	error_text.text = ""
	disable_buttons()
	var username: String = username_input.get_text()
	var password: String = password_input.get_text()
	tint.visible = true
	Logger.log("Logging in with password.")
	buffer_text.text = "Logging in as " + username + "..."
	buffer_text.visible = true
	Proxy.gateway_connection_request(username, password, remember_login_details, "password")

func _on_CreateAccountButton_pressed() -> void:	
	if (' ' in username_input.text || ' ' in password_input.text):
		error_text.text = "Your username and password cannot contain spaces."
		return
	if (username_input.text == "" || password_input.text == ""):
		error_text.text = "Please provide a valid username and password."
		return
	if (username_input.text.length() > 15):
		error_text.text = "The maximum length for a username is 15 characters."
		return
	if (password_input.text.length() > 35):
		error_text.text = "The maximum length for a password is 35 characters."
		return
	for inappropriate_word in GlobalData.inappropriate_words:
		if (inappropriate_word in username_input.text):
			error_text.text = "Please provide an appropriate username."
			return
	error_text.text = ""
	disable_buttons()
	var username: String = username_input.get_text()
	var password: String = password_input.get_text()
	tint.visible = true
	Logger.log("Creating account.")
	buffer_text.text = "Creating account..."
	buffer_text.visible = true
	Proxy.connect_to_server(username, password, true, false, "")

func enable_buttons() -> void:
	login_button.disabled = false
	create_account_button.disabled = false
	buffer_text.visible = false
	tint.visible = false

func disable_buttons() -> void:
	login_button.disabled = true
	create_account_button.disabled = true

func on_successful_connection_to_server() -> void:
	login_button.disabled = false
	create_account_button.disabled = false
	var scene_data := {}
	if (GlobalData.account_already_logged_on_time != 0):
		scene_data["account_already_logged_on_time"] = GlobalData.account_already_logged_on_time
	GlobalData.account_already_logged_on_time = 0
	Scenes.change_scene(Scenes.MainMenu_path, scene_data)
	
func _on_RememberMe_toggled(button_pressed: bool) -> void:
	remember_login_details = button_pressed

