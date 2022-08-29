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
	var auth_token_file := File.new()
	auth_token_file.open("user://Data/login_data.json", File.READ)
	var file_json := JSON.parse(auth_token_file.get_as_text())
	var auth_token: String = file_json.result.auth_token
	var username: String = file_json.result.username
	auth_token_file.close()
	if (auth_token != ""):
		disable_buttons()
		$Tint.visible = true
		$BufferText.text = "Logging in as " + username + "..."
		$BufferText.visible = true
		username_input.text = username
		Gateway_.connect_to_server(username, auth_token, false, false, "auth_token")
	
func _on_LoginButton_pressed() -> void:
	if (username_input.text == "" || password_input.text == ""):
		print("Please provide a valid username and password.")
		error_text.text = "Please provide a valid username and password."
		return
	disable_buttons()
	var username: String = username_input.get_text()
	var password: String = password_input.get_text()
	$Tint.visible = true
	$BufferText.text = "Logging in as " + username + "..."
	$BufferText.visible = true
	Gateway_.connect_to_server(username, password, false, remember_login_details, "password")

func _on_CreateAccountButton_pressed() -> void:
	if (username_input.text == "" || password_input.text == ""):
		print("Please provide a valid username and password.")
		return
	login_button.disabled = true
	create_account_button.disabled = true
	var username: String = username_input.get_text()
	var password: String = password_input.get_text()
	$Tint.visible = true
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
