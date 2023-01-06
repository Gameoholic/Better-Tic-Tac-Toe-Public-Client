extends Control

signal scene_cleaned_up
var cleaned_up := false

"""
PhaseType:
	Represents states of the Boot Screen
	LOGO_ANIMATION:
		Displaying a logo animation.
	ACCOUNT_CREATION:
		Prompting the user to pick a username, or waiting for their input.
	ACCOUNT_REGISTARTION:
		Creating the account server-side.
	ACCOUNT_LOGGING_IN_INPUT:
		Prompting the user to enter username and password, waiting for their input.
	ACCOUNT_LOGGING_IN:
		Logging into the account using password.
	LIMBO:
		Finished displaying current animation and waiting for an event like a connection to the server.
"""
enum PhaseType {LOGO_ANIMATION, ACCOUNT_CREATION, ACCOUNT_REGISTRATION, ACCOUNT_LOGGING_IN_INPUT, ACCOUNT_LOGGING_IN, LIMBO}

var phase: int
var queued_switch_to_main_menu := false #Set to true when connected to gameserver and waiting for anim to finish
var queued_account_creation := false #Set to true when successfully connected to proxy and can proceed to account creation.
var queued_display_error := false #Set to true when waiting for anim to finish and needs to display error
var g_error_text: String
var temp_password: String #Password will be temporarily stored here when account created for the first time. Auth token will be used after that, but changing the password is recommended.
var created_new_account: bool #Whether a new account was created

onready var Proxy := $"/root/Network/Proxy"
onready var username := $"VBoxContainer/Username"
onready var version := $"VBoxContainer/Version"
onready var splash_text := $"LoadingInfo/SplashText"
onready var username_input_container := $UsernameInput
onready var prompt_text := $"UsernameInput/PromptText"
onready var username_edit := $"UsernameInput/PromptText/Username"
onready var tween := $Tween

var username_confirmed := false

func clean_up_scene() -> void: #Ran right before the scene is switched - blocking
	cleaned_up = true
	emit_signal("scene_cleaned_up")
	
func _ready():	
	var scene_data: Dictionary = Scenes.transferred_scene_data
	Scenes.on_scene_loaded()
	CustomButtons.enable()

	phase = PhaseType.LOGO_ANIMATION
	var has_auth_token := true
	version.text = "Beta v" + GlobalData.version
	splash_text.text = "Connecting to server..."
	if (false): #scene_data.has("logged_out")
		pass
	else:
		#Check if there's an auth token on the device:
		if (GlobalData.auth_token != ""):
			username.text = "Username: " + GlobalData.username
			Logger.log("Logging in with auth token.")
			Proxy.gateway_connection_request(GlobalData.username, GlobalData.auth_token, true, "auth_token", false)
		else:
			Logger.log("No auth token detected.")
			has_auth_token = false
			Proxy.validate_version_and_get_server_status_request()
		
		
	$VideoPlayer.play()
	tween.interpolate_property(username, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1.5, tween.TRANS_LINEAR)
	tween.interpolate_property(version, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1.5, tween.TRANS_LINEAR)
	tween.start()
	yield(get_tree().create_timer(2), "timeout")
	splash_text.visible = true
	splash_text.modulate = Color(1, 1, 1, 0)
	tween.interpolate_property(splash_text, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)
	tween.start()
	AudioPlayer.play_sound("boot")
	yield(get_tree().create_timer(2), "timeout")
	
	phase = PhaseType.LIMBO
	if (queued_display_error):
		display_error(g_error_text)
	elif (queued_switch_to_main_menu):
		on_successful_connection_to_gameserver()
	elif (!has_auth_token and queued_account_creation):
		start_account_creation()

func start_account_creation() -> void:
	phase = PhaseType.ACCOUNT_CREATION
	Logger.log("Starting account creation.")
	AudioPlayer.play_sound("pencil_stroke")
	$VideoPlayer3.play()
	splash_text.visible = false
	yield(get_tree().create_timer(0.05), "timeout")
	#TODO: Get rid of multiple video players mess
	$VideoPlayer.visible = false
	$VideoPlayer2.visible = false
	$VideoPlayer4.visible = false
	yield(get_tree().create_timer(0.3), "timeout") #problematic
	
	prompt_text.text = "Welcome to Better Tic Tac Toe!\nPlease pick a username for yourself."
	prompt_text.self_modulate = Color(1, 1, 1, 0)
	username_edit.self_modulate = Color(1, 1, 1, 0)
	$"%PlayedBefore".self_modulate = Color(1, 1, 1, 0)
	$"%PlayedBefore".visible = true
	prompt_text.visible = true
	username_edit.visible = true
	
	tween.interpolate_property(prompt_text, "self_modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.3, tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property(username_input_container, "rect_position", Vector2(username_input_container.rect_position.x, 125), Vector2(username_input_container.rect_position.x, 16), 0.5, tween.TRANS_CUBIC, tween.EASE_IN_OUT)
	tween.start()
	yield(get_tree().create_timer(0.3), "timeout")
	tween.interpolate_property(username_edit, "self_modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.3, tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.interpolate_property($"%PlayedBefore", "self_modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.3, tween.TRANS_LINEAR, tween.EASE_IN_OUT)	
	tween.start()

func on_successful_connection_to_gameserver() -> void:
	queued_switch_to_main_menu = true
	if (phase != PhaseType.LIMBO):
		return
	queued_switch_to_main_menu = false
	
	$VideoPlayer5.play()
	splash_text.visible = false
	yield(get_tree().create_timer(0.05), "timeout")
	AudioPlayer.play_sound("pencil_stroke")
	$VideoPlayer.visible = false
	$VideoPlayer2.visible = false
	$VideoPlayer3.visible = false
	$VideoPlayer4.visible = false
	
	yield(get_tree().create_timer(0.25), "timeout")
	
	var scene_data := {"created_new_account": created_new_account}
	if (GlobalData.account_already_logged_on_time != 0):
		scene_data["account_already_logged_on_time"] = GlobalData.account_already_logged_on_time
	GlobalData.account_already_logged_on_time = 0
	Scenes.change_scene(Scenes.MainMenu_path, scene_data)

func display_error(error_text: String) -> void:
	queued_display_error = true
	g_error_text = error_text
	if (phase != PhaseType.LIMBO and phase != PhaseType.ACCOUNT_REGISTRATION and phase != PhaseType.ACCOUNT_LOGGING_IN):
		return
	queued_display_error = false
	if (phase == PhaseType.LIMBO):
		splash_text.add_color_override("font_color", Color(1,0,0,1))
		splash_text.text = error_text
		$"LoadingInfo".rect_position.y += 13 * splash_text.text.count("\n")
		if ("\n" in splash_text.text):
			$"LoadingInfo/SplashText/Retry".rect_position.y += 14 * splash_text.text.count("\n")
		$"LoadingInfo/SplashText/Retry".visible = true
		return
		AudioPlayer.play_sound("expansion")
	elif (phase == PhaseType.ACCOUNT_REGISTRATION):
		prompt_text.text = "Welcome to Better Tic Tac Toe!\nPlease pick a username for yourself."
		prompt_text.self_modulate = Color(1, 1, 1, 1)
		username_edit.self_modulate = Color(1, 1, 1, 1)
		username_edit.visible = true
		prompt_text.visible = true
		username_edit.visible = true
		$"%Error".visible = true
		$"%Error".text = error_text
		username_edit.editable = true
		AudioPlayer.play_sound("expansion")
	elif (phase == PhaseType.ACCOUNT_LOGGING_IN):
		prompt_text.text = "Please enter your account credentials.\n"
		$"%PlayedBefore".visible = false
		$"%Login".visible = true
		$"%Cancel".visible = true
		$"UsernameInput/PromptText/Username/PasswordContainer".visible = true
		phase = PhaseType.ACCOUNT_LOGGING_IN_INPUT
		$"%RememberMeContainer".visible = true	
		$"%LoginError".visible = true
		$"%LoginError".text = error_text
		$"%Username".editable = true
		$"%Password".editable = true
		AudioPlayer.play_sound("expansion")


func _on_Proceed_button_pressed():
	var label: Label = $"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/Proceed/Label"
	label.rect_position.y = 0 + 6

func _on_Proceed_button_released():
	var label: Label = $"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/Proceed/Label"
	label.rect_position.y = 0
	var username_input: LineEdit = $"UsernameInput/PromptText/Username"
	var error_text: Label = $"UsernameInput/PromptText/Username/TextContainer/Error"
	#All other string validation checks occur in LineEdit script
	if (username_input.text.length() < 2):
		error_text.visible = true
		error_text.text = "Your username must contain at least 2 characters."
		return
	for inappropriate_word in GlobalData.inappropriate_words:
		error_text.visible = true
		if (inappropriate_word in username_input.text):
			error_text.text = "Please provide an appropriate username."
			return
	if (!username_confirmed):
		#PROCEED CHECK:
		username_confirmed = true
		error_text.text = ""
		error_text.visible = false
		prompt_text.text = "Your username will be " + username_input.text + ".\nWould you like to proceed?"
	else:
		#CREATE ACCOUNT:
		prompt_text.text = "Registering...\n"
		$"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/Proceed".visible = false
		$"UsernameInput/PromptText/Username/TextContainer/Warning".visible = false
		username_edit.editable = false
		phase = PhaseType.ACCOUNT_REGISTRATION
		
		randomize()
		temp_password = (str(randi()).sha256_text() + str(OS.get_unix_time()).sha256_text()).substr(0, 128)
		Proxy.gateway_connection_request(username_input.text, temp_password, false, "", true)

func finish_account_creation(username: String) -> void:
	phase = PhaseType.LOGO_ANIMATION
	created_new_account = true
	prompt_text.text = "Registered!"
	username_edit.visible = false
	yield(get_tree().create_timer(0.2), "timeout")
	tween.interpolate_property(prompt_text, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.start()
	
	Logger.log("Logging in with generated token.")
	Proxy.gateway_connection_request(username, temp_password, true, "password", false)
	temp_password = ""
	
	$VideoPlayer4.play()
	$VideoPlayer4.visible = true
	$VideoPlayer2.visible = false
	$VideoPlayer.visible = false
	yield(get_tree().create_timer(0.05), "timeout")
	$VideoPlayer3.visible = false
	splash_text.visible = true
	splash_text.text = "Connecting to server..."
	splash_text.modulate = Color(1, 1, 1, 0)
	yield(get_tree().create_timer(1), "timeout")
	tween.interpolate_property(splash_text, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)
	tween.start()
	
	yield(get_tree().create_timer(0.25), "timeout")
	phase = PhaseType.LIMBO
	if (queued_display_error):
		display_error(g_error_text)
	elif (queued_switch_to_main_menu):
		on_successful_connection_to_gameserver()

func finish_log_in() -> void:
	phase = PhaseType.LOGO_ANIMATION
	prompt_text.text = "Logged in!"
	username_edit.visible = false
	yield(get_tree().create_timer(0.2), "timeout")
	tween.interpolate_property(prompt_text, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, tween.TRANS_LINEAR, tween.EASE_IN_OUT)
	tween.start()
	
	
	$VideoPlayer4.play()
	$VideoPlayer4.visible = true
	$VideoPlayer2.visible = false
	$VideoPlayer.visible = false
	yield(get_tree().create_timer(0.05), "timeout")
	$VideoPlayer3.visible = false
	splash_text.visible = true
	splash_text.text = "Connecting to server..."
	splash_text.modulate = Color(1, 1, 1, 0)
	yield(get_tree().create_timer(1), "timeout")
	tween.interpolate_property(splash_text, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)
	tween.start()
	
	yield(get_tree().create_timer(0.5), "timeout")
	phase = PhaseType.LIMBO
	if (queued_display_error):
		display_error(g_error_text)
	elif (queued_switch_to_main_menu):
		on_successful_connection_to_gameserver()

func _on_Proceed_button_left_area():
	var label: Label = $"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/Proceed/Label"
	label.rect_position.y = 0


func _on_Retry_button_pressed():
	var label: Label = $"LoadingInfo/SplashText/Retry/Label"
	label.rect_position.y = 0 + 6


func _on_Retry_button_released():
	var label: Label = $"LoadingInfo/SplashText/Retry/Label"
	label.rect_position.y = 0

func _on_Retry_button_left_area():
	var label: Label = $"LoadingInfo/SplashText/Retry/Label"
	label.rect_position.y = 0



func _on_PlayedBefore_button_pressed():
	var label: Label = $"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/VBoxContainer/PlayedBefore/Label"
	label.rect_position.y = 0 + 6

func _on_PlayedBefore_button_released():
	var label: Label = $"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/VBoxContainer/PlayedBefore/Label"
	label.rect_position.y = 0
	
	phase = PhaseType.ACCOUNT_LOGGING_IN_INPUT
	prompt_text.text = "Please enter your account credentials.\n"
	$"%PlayedBefore".enabled = false
	$"%Login".enabled = true
	$"%Cancel".enabled = true
	$"%RememberMeContainer".visible = true
	$"%RememberMeContainer".modulate = Color(1, 1, 1, 1)
	$"%RememberMe".disabled = false	
	$"%PlayedBefore".visible = false
	$"%PlayedBefore".modulate = Color(1, 1, 1, 1)
	$"%Login".modulate = Color(1, 1, 1, 0)
	$"%Cancel".modulate = Color(1, 1, 1, 0)
	$"%Password".modulate = Color(1, 1, 1, 0)
	$"%Login".visible = true
	$"%Cancel".visible = true
	$"%Password".visible = true
	$"%Username".text = ""
	$"UsernameInput/PromptText/Username/PasswordContainer".visible = true
	tween.interpolate_property($"%RememberMeContainer", "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)	
	tween.interpolate_property($"%PlayedBefore", "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, tween.TRANS_LINEAR)
	tween.interpolate_property($"%Login", "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)
	tween.interpolate_property($"%Cancel", "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)
	tween.interpolate_property($"%Password", "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.25, tween.TRANS_LINEAR)
	
	tween.start()
	
	


func _on_PlayedBefore_button_left_area():
	var label: Label = $"UsernameInput/PromptText/Username/TextContainer/HBoxContainer/VBoxContainer/PlayedBefore/Label"
	label.rect_position.y = 0

func _on_Login_button_pressed():
	var label: Label = $"UsernameInput/PromptText/Username/PasswordContainer/Login/Label"
	label.rect_position.y = 0 + 6

func _on_Login_button_released():
	var label: Label = $"UsernameInput/PromptText/Username/PasswordContainer/Login/Label"
	label.rect_position.y = 0
	
	if ($"%Username".text.length() < 1):
		$"%LoginError".visible = true
		$"%LoginError".text = "Username mustn't be empty."	
		return
	if ($"%Password".text.length() < 1):
		$"%LoginError".visible = true
		$"%LoginError".text = "Password mustn't be empty."	
		return
	
	prompt_text.text = "Logging in...\n"
	$"%Login".visible = false
	$"%Cancel".visible = false
	$"%Password".editable = false
	$"%Username".editable = false
	$"%RememberMeContainer".visible = false
	phase = PhaseType.ACCOUNT_LOGGING_IN
	Logger.log("Logging in with password.")
	Proxy.gateway_connection_request($"%Username".text, $"%Password".text, $"%RememberMe".pressed, "password", false)
	

func _on_Login_button_left_area():
	var label: Label = $"UsernameInput/PromptText/Username/PasswordContainer/Login/Label"
	label.rect_position.y = 0

func _on_Cancel_button_pressed():
	var label: Label = $"UsernameInput/PromptText/Username/PasswordContainer/Cancel/Label"
	label.rect_position.y = 0 + 6
	

func _on_Cancel_button_released():
	var label: Label = $"UsernameInput/PromptText/Username/PasswordContainer/Cancel/Label"
	label.rect_position.y = 0
	
	phase = PhaseType.ACCOUNT_CREATION	
	prompt_text.text = "Welcome to Better Tic Tac Toe!\nPlease pick a username for yourself."
	$"%Username".text = ""
	$"%Password".text = ""
	$"%Cancel".visible = false
	$"%LoginError".visible = false
	$"%PlayedBefore".visible = true
	prompt_text.visible = true
	username_edit.visible = true
	$"%PlayedBefore".enabled = true
	$"%Login".enabled = false
	$"%Cancel".enabled = false
	
		
	$"%RememberMe".disabled = true
	tween.interpolate_property($"%RememberMeContainer", "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, tween.TRANS_LINEAR)	
	tween.interpolate_property($"%Login", "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, tween.TRANS_LINEAR)
	tween.interpolate_property($"%Cancel", "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, tween.TRANS_LINEAR)
	tween.interpolate_property($"%Password", "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.25, tween.TRANS_LINEAR)
	tween.interpolate_property($"%PlayedBefore", "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.3, tween.TRANS_LINEAR, tween.EASE_IN_OUT)	
	
	tween.start()


func _on_Cancel_button_left_area():
	var label: Label = $"UsernameInput/PromptText/Username/PasswordContainer/Cancel/Label"
	label.rect_position.y = 0

