extends Node

enum {Notice, Warning, Alert, Error} #Severities

onready var GameServer_ := $"/root/Network/GameServer"
onready var LoginScreen_ := get_node("/root/LoginScreen")

var network := NetworkedMultiplayerENet.new()
var multiplayer_api := MultiplayerAPI.new()

var ip: String
var port: int
var cert := load("res://Data/Certificate/X509_Certificate.crt")

var username: String
var password: String
var new_account: bool
var remember_account_details: bool
var login_type: String #password, or auth_token

func _ready() -> void:
	ip = GlobalData.connection_ip
	port = GlobalData.connection_port
	
func _process(delta) -> void:
	if get_custom_multiplayer() == null:
		return
	if not custom_multiplayer.has_network_peer():
		return
	custom_multiplayer.poll()
	
func connect_to_server(local_username: String, local_password: String, local_new_account: bool, local_remember_account_details: bool, local_login_type: String) -> void:
	network.set_dtls_enabled(true)
	network.set_dtls_verify_enabled(false) #set to true when using signed certificate
	network.set_dtls_certificate(cert)
	username = local_username
	password = local_password
	new_account = local_new_account
	remember_account_details = local_remember_account_details
	login_type = local_login_type
	network.create_client(ip, port)
	set_custom_multiplayer(multiplayer_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(null) #Force reset multiplayer API
	custom_multiplayer.set_network_peer(network)
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	
func _on_connection_failed() -> void:
	Logger.error("Failed to connect to gateway server.", Error)
	 
func _on_connection_succeeded() -> void:
	Logger.log("Successfully connected to gateway server.")
	if new_account == true:
		request_create_account()
	else:
		request_login()
		
func request_login() -> void:
	Logger.log("Connecting to gateway to request login.")
	if (login_type == "password"):
		rpc_id(1, "login_request", username, password.sha256_text(), remember_account_details, login_type)
	elif (login_type == "auth_token"):
		rpc_id(1, "login_request", username, password, remember_account_details, login_type)
	password = ""
	
func request_create_account() -> void:
	Logger.log("Creating new account.")
	rpc_id(1, "create_account_request", username, password.sha256_text())
	password = ""
	
remote func receive_create_account_result(result: bool, error_code: String) -> void:
	Logger.log("Results received for account creation")
	if result == true:
		Logger.log("Account created successfully.")
		LoginScreen_.error_text.text = "Account created. You may now log in."
	else:
		match error_code:
			"G001":
				Logger.error("Couldn't create an account, no username/password.", Notice)
				LoginScreen_.error_text.text = "Couldn't create an account, please enter a username and a password."
			"A001":
				Logger.error("Couldn't create an account, the username already exists.", Notice)
				LoginScreen_.error_text.text = "Couldn't create an account, the username already exists."
			"A003":
				Logger.error("Couldn't create an account, account details aren't valid. Possible outdated version.", Notice)
				LoginScreen_.error_text.text = "Couldn't create an account, account details aren't valid. Make sure you're running the most updated version."
			_:
				Logger.error("Couldn't create an account, please try again. (" + error_code + ")", Alert)
				LoginScreen_.error_text.text = "Couldn't create an account, please try again. (" + error_code + ")"
				
	get_node("/root/LoginScreen").enable_buttons()
	LoginScreen_.get_node("Tint").visible = false
	LoginScreen_.get_node("BufferText").visible = false
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")

#Contains details on how to connect to gameserver. {"port": ..., "token":...}	
remote func receive_gameserver_connection_details(result: bool, gameserver_connection_details: Dictionary) -> void:
	Logger.log("Received gameserver connection details: " + str(result) + ", " + str(gameserver_connection_details))
	if (result == true):
		GlobalData.displayname = username #IN FUTURE, CHANGE THIS TO DISPLAYNAME. NOT USERNAME AAAAAAAAAAAAAAAAAAAAAIN FUTURE, CHANGE THIS TO DISPLAYNAME. NOT USERNAME AAAAAAAAAAAAAAAAAAAAAIN FUTURE, CHANGE THIS TO DISPLAYNAME. NOT USERNAME AAAAAAAAAAAAAAAAAAAAA
		GlobalData.gameserver_port = gameserver_connection_details.port
		GameServer_.port = gameserver_connection_details.port
		GameServer_.token = gameserver_connection_details.token
		#If authentication created an auth token for us and was piggybacked here, store it:
		if (!(gameserver_connection_details.auth_token == "" and login_type == "auth_token")):
			var auth_token_file := File.new()
			auth_token_file.open("user://Data/login_data.json", File.WRITE)
			if (gameserver_connection_details.auth_token == ""):
				username = ""
			auth_token_file.store_line(JSON.print({"username": username, "auth_token": gameserver_connection_details.auth_token}, "\t"))
			auth_token_file.close()
		GameServer_.connect_to_server()
	else:
		Logger.error("Failed to log in. Incorrect credentials provided.", Notice)
		LoginScreen_.enable_buttons()
		LoginScreen_.get_node("Tint").visible = false
		LoginScreen_.get_node("BufferText").visible = false
		LoginScreen_.error_text.text = "Incorrect credentials provided."
		LoginScreen_.error_text.visible = true
		
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")

remote func receive_error(error_code: String) -> void:
	match error_code:
		"M001":
			Logger.error("Couldn't connect to server, please try again. (" + error_code + ")", Error)
		_:
			Logger.error("An error has occured: " + str(error_code), Error)
