extends Control

var remember_login_details := false

onready var Gateway_ := $"/root/Network/Gateway"
onready var username_input := get_node("Background/UIContainer/Username")
onready var password_input := get_node("Background/UIContainer/Password")
onready var login_button := get_node("Background/UIContainer/LoginButton")
onready var create_account_button := get_node("Background/UIContainer/CreateAccountButton")
onready var error_text := get_node("Background/UIContainer/ErrorText")
	
func _ready() -> void:
	#Check if there's an auth token on the device:
	if (GlobalData.auth_token != ""):
		Logger.log("Logging in with auth token.")
		disable_buttons()
		$Tint.visible = true
		$BufferText.text = "Logging in as " + GlobalData.username + "..."
		$BufferText.visible = true
		username_input.text = GlobalData.username
		Gateway_.connect_to_server(GlobalData.username, GlobalData.auth_token, false, false, "auth_token")
	
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
	$Tint.visible = true
	Logger.log("Logging in with password.")
	$BufferText.text = "Logging in as " + username + "..."
	$BufferText.visible = true
	Gateway_.connect_to_server(username, password, false, remember_login_details, "password")

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
	if (username_input.text.length() > 35):
		error_text.text = "The maximum length for a username is 35 characters."
		return
	for inappropriate_word in GlobalData.inappropriate_words:
		if (inappropriate_word in username_input.text):
			error_text.text = "Please provide an appropriate username."
			return
	error_text.text = ""
	disable_buttons()
	var username: String = username_input.get_text()
	var password: String = password_input.get_text()
	$Tint.visible = true
	Logger.log("Creating account.")
	$BufferText.text = "Creating account..."
	$BufferText.visible = true
	Gateway_.connect_to_server(username, password, true, false, "")

func enable_buttons() -> void:
	login_button.disabled = false
	create_account_button.disabled = false

func disable_buttons() -> void:
	login_button.disabled = true
	create_account_button.disabled = true

func on_successful_connection_to_server() -> void:
	login_button.disabled = false
	create_account_button.disabled = false	
	get_tree().change_scene("res://Menus/MainMenu/MainMenu.tscn")
	

func _on_RememberMe_toggled(button_pressed: bool) -> void:
	remember_login_details = button_pressed


#sign in: sign_in(true/false). if true: generate auth code and save.
#for future: every time we log in send auth code.
#if we sign in with false and auth code exists
