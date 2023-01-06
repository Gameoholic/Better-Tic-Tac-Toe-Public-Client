extends Node

onready var Proxy := $"/root/Network/Proxy"
onready var GameServer := $"/root/Network/GameServer"
	
var network := NetworkedMultiplayerENet.new()
var multiplayer_api := MultiplayerAPI.new()

var ip: String
var port: int
var cert := load("res://Data/Certificate/X509_Certificate.crt")
var unexpected_disconnect: bool #True if connected to server, but unexpectedly lost connection after, without receiving expected result
var failed_login_attempts := 0
var temp_credentials #The 'credentials' varaible is cleared upon disconnecting from the gateway server so we need to store it here temporarily when attempting to connect to gateway when already logged in.

var username: String
var credentials: String #password or auth token
var new_account: bool
var remember_account_details: bool
var login_type: String #password, or auth_token
	
func _process(delta) -> void:
	if (get_custom_multiplayer() == null):
		return
	if (not custom_multiplayer.has_network_peer()):
		return
	custom_multiplayer.poll()
	
func connect_to_server(local_username: String, local_credentials: String, local_new_account: bool, local_remember_account_details: bool, local_login_type: String) -> void:
	network.set_dtls_enabled(true)
	network.set_dtls_verify_enabled(false) #set to true when using signed certificate
	network.set_dtls_certificate(cert)
	username = local_username
	credentials = local_credentials
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
	network.connect("server_disconnected", self, "_on_server_disconnected")
	
func _on_connection_failed() -> void:
	Logger.error("Failed to connect to gateway server.", Logger.ERROR)
	network.close_connection()
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")	
	Scenes.BootScreen.display_error("Couldn't connect to server. Please try again or contact support.")
	credentials = ""
	temp_credentials = ""
	
func _on_connection_succeeded() -> void:
	unexpected_disconnect = true
	Logger.log("Successfully connected to gateway server.")
	if (new_account == true):
		request_create_account()
	else:
		request_login()

func _on_server_disconnected() -> void:
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	if (unexpected_disconnect):
		Logger.error("Lost connection to Gateway.", Logger.ERROR)
		Scenes.BootScreen.display_error("Lost connection to server. Please check your internet connection or contact support.")
	else:
		Logger.log("Disconnected from Gateway.")
		credentials = ""

remote func receive_kick_reason(reason: String) -> void:
	unexpected_disconnect = false
	Logger.error("Kicked from gateway: " + reason + ".", Logger.ERROR)	
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	match Scenes.current_scene.name:
		"BootScreen":
			Scenes.BootScreen.display_error("Lost connection to server. " + reason)
			
func request_login() -> void:
	Logger.log("Requesting login from Gateway.")
	if (login_type == "password"):
		rpc_id(1, "login_request", username, credentials.sha256_text(), remember_account_details, login_type)
	elif (login_type == "auth_token"):
		rpc_id(1, "login_request", username, credentials, remember_account_details, login_type)
	
func request_create_account() -> void:
	Logger.log("Requesting to create account from Gateway.")
	rpc_id(1, "create_account_request", username, credentials.sha256_text())
	
remote func receive_create_account_result(result: bool, error_code: String) -> void:
	unexpected_disconnect = false
	Logger.log("Results received for account creation")
	if (result == true):
		Logger.log("Account created successfully.")
		Scenes.BootScreen.finish_account_creation(username)
	else:
		match error_code:
			"G001":
				Logger.error("Couldn't register, account details aren't valid. Possible outdated version.", Logger.NOTICE)
				Scenes.BootScreen.display_error("Couldn't register, account details aren't valid. \nMake sure you're running the most updated version or contact support.")
			"A001":
				Logger.error("Couldn't register, the username is already taken.", Logger.NOTICE)
				Scenes.BootScreen.display_error("Couldn't register, the username is already taken.")
			_:
				Logger.error("Couldn't register, please try again. (" + error_code + ")", Logger.ALERT)
				Scenes.BootScreen.display_error("Couldn't register, please try again. (" + error_code + ")")
			

#Contains details on how to connect to gameserver.
#gameserver_connection_details: {"port": ..., "token":...}	
#additional_data: {"displayname": ...}
remote func receive_gameserver_connection_details(result: bool, gameserver_connection_details: Dictionary, additional_data: Dictionary) -> void:
	unexpected_disconnect = false
#	print(gameserver_connection_details) #TODO: friend system should be dependant soley on user IDs
#	print(additional_data)
	if (result == true):
		failed_login_attempts = 0
		credentials = ""
		temp_credentials = ""
		Logger.log("Successfully connected to gateway and received gameserver connection details.")
		GlobalData.displayname = additional_data.displayname
		GlobalData.gameserver_name = additional_data.gameserver_name	
		GlobalData.gameserver_port = gameserver_connection_details.port
		GameServer.port = gameserver_connection_details.port
		GameServer.token = gameserver_connection_details.token
		 #If the account is logged into from another device: (stores time when it logged in)
		if (additional_data.has("account_already_logged_on_time")):
			GlobalData.account_already_logged_on_time = additional_data.account_already_logged_on_time
		#If authentication created an auth token for us and was piggybacked here, store it:
		if (!(gameserver_connection_details.auth_token == "" and login_type == "auth_token")):
			var auth_token_file := File.new()
			auth_token_file.open("user://Data/login_data.json", File.WRITE)
			if (gameserver_connection_details.auth_token == ""):
				username = ""
			auth_token_file.store_line(JSON.print({"username": username, "auth_token": gameserver_connection_details.auth_token}, "\t"))
			auth_token_file.close()
		if (Scenes.BootScreen.phase == Scenes.BootScreen.PhaseType.ACCOUNT_LOGGING_IN):
			Scenes.BootScreen.finish_log_in()
		GameServer.connect_to_server()
	else:
		if (additional_data.has("already_logged_in")):
			Logger.error("Failed to log in. Account already logged into on " + str(OS.get_datetime_from_unix_time(additional_data["already_logged_in"])) + ".", Logger.NOTICE)						
			if (failed_login_attempts >= 3):
				Logger.error("Failed to log in after 3 additional attempts.", Logger.ERROR)
				credentials = ""
				Scenes.BootScreen.display_error("Failed to log in, you're logged in from another device.\nPlease try again or contact support.")
				return
			GlobalData.account_already_logged_on_time = int(additional_data["already_logged_in"])
			failed_login_attempts += 1
			temp_credentials = credentials 
			yield(get_tree().create_timer(3 * failed_login_attempts), "timeout")
			Logger.error("Retrying log in, attempt number " + str(failed_login_attempts) + ".", Logger.NOTICE)
			Proxy.gateway_connection_request(username, temp_credentials, remember_account_details, login_type, false)
		else:
			credentials = ""
			temp_credentials = ""
			Logger.error("Failed to log in. Incorrect credentials provided.", Logger.NOTICE)
			var auth_token_file := File.new()
			auth_token_file.open("user://Data/login_data.json", File.WRITE)
			auth_token_file.store_line(JSON.print({"username": username, "auth_token": ""}, "\t"))
			auth_token_file.close()
			Scenes.BootScreen.display_error("Incorrect credentials provided.")

func request_reset_auth_token() -> void:
	Logger.log("Sent auth token reset request.")
	rpc_id(1, "reset_auth_token_request")
	
remote func receive_error(error_code: String) -> void:
	Scenes.BootScreen.display_error("Couldn't connect to server, please try again later or contact support. (" + error_code + ")")
	match error_code:
		"M001":
			Logger.error("Couldn't connect to server. (" + error_code + ")", Logger.ERROR)
		_:
			Logger.error("An error has occured: " + str(error_code), Logger.ERROR)
