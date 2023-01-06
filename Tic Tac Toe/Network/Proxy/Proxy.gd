extends Node

onready var Gateway := $"/root/Network/Gateway"

var network := NetworkedMultiplayerENet.new()
var multiplayer_api := MultiplayerAPI.new()

var ip: String
var port: int
var unexpected_disconnect: bool #True if connected to server, but unexpectedly lost connection after, without receiving expected result
var version: String

#Arguments to be passed to Proxy/Gateway on successful connection:
var request_name: String
var username: String
var credentials: String #Can be password or auth token
var credentials_type: String #'Password' or 'auth_token'
var remember_account_details: bool
var login_type: String
var create_account: bool #If false, will login. If True, will create account.

func _ready() -> void:
	ip = GlobalData.connection_ip
	port = GlobalData.connection_port
	version = GlobalData.version
	
func _process(delta) -> void:
	if (get_custom_multiplayer() == null):
		return
	if (not custom_multiplayer.has_network_peer()):
		return
	custom_multiplayer.poll()
	
func connect_to_server() -> void:
	network.create_client(ip, port)
	set_custom_multiplayer(multiplayer_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(null) #Force reset multiplayer API
	custom_multiplayer.set_network_peer(network)
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("server_disconnected", self, "_on_server_disconnected")
	

func _on_connection_failed() -> void:
	Logger.error("Failed to connect to Proxy server.", Logger.ERROR)
	network.close_connection()
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	
	Scenes.BootScreen.display_error("Couldn't connect to server. Please check your internet connection or contact support.")
	 
func _on_connection_succeeded() -> void:
	unexpected_disconnect = true
	Logger.log("Successfully connected to Proxy server.")
	match request_name:
		"gateway_connection":
			Logger.log("Making gateway connection request from Proxy...")
			rpc_id(1, "gateway_connection_request", GlobalData.version)
		"validate_version_and_get_server_status":
			Logger.log("Validating version and getting server status from Proxy...")
			rpc_id(1, "validate_version_and_get_server_status_request", GlobalData.version)

func _on_server_disconnected() -> void:
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	if (unexpected_disconnect):
		Logger.error("Lost connection to Proxy.", Logger.ERROR)
		Scenes.BootScreen.display_error("Lost connection to server. Please check your internet connection or contact support.")
	else:
		Logger.log("Disconnected from Proxy.")

#Connect to Proxy. If successful, make a gateway connection request
func gateway_connection_request(local_username: String, local_credentials: String, local_remember_account_details: bool, local_credentials_type: String, local_create_account: bool) -> void:
	username = local_username
	credentials = local_credentials
	credentials_type = local_credentials_type
	remember_account_details = local_remember_account_details
	create_account = local_create_account
	request_name = "gateway_connection"
	connect_to_server()

func validate_version_and_get_server_status_request() -> void:
	request_name = "validate_version_and_get_server_status"
	connect_to_server()


#Called by: Proxy
#When: Received true result for "gateway connection" request.
#Arguments: Receives gateway connection details, along with latest version number.
remote func true_gateway_connection_request_result(gateway_ip: String, gateway_port: int, latest_version: String) -> void:
	unexpected_disconnect = false
	Logger.log("True result received from Proxy for gateway connection request.")
	if (latest_version != GlobalData.version):
		Logger.error("Running on outdated version " + GlobalData.version + ", latest version is " + latest_version + ".", Logger.WARNING)
		GlobalData.latest_version = latest_version
	else:
		Logger.log("Running on latest version " + GlobalData.version + ".")
	Gateway.ip = gateway_ip
	Gateway.port = gateway_port
	Gateway.connect_to_server(username, credentials, create_account, remember_account_details, credentials_type)
	credentials = ""

#Called by: Proxy
#When: Received false result for "gateway connection" request.
#Arguments: Receives denial reason and version details.
remote func false_gateway_connection_request_result(denial_reason: String, required_version: String, latest_version: String) -> void:
	unexpected_disconnect = false	
	if (required_version != ""):
		Logger.error("New update available. Must run on version " + required_version + ", latest version is " + latest_version + ". Currently running on " + GlobalData.version + ".", Logger.ALERT)
		Scenes.BootScreen.display_error("New update available, please install v" + latest_version + " from the #releases channel to be able to play.")		
	if (denial_reason != ""):
		Logger.error("False result received from Proxy for gateway connection request: " + denial_reason + ".", Logger.ALERT)
		var error_message := "Couldn't connect to server:\n" + denial_reason
		if (required_version != ""):
			error_message += "\nAdditionally, please install v" + latest_version + " from the #releases channel to be able to play."
		Scenes.BootScreen.display_error(error_message)
	credentials = ""

#Called by: Proxy
#When: Received true result for "validate version and get server status" request.
#Arguments: Receives gateway connection details, along with latest version number.
remote func true_validate_version_and_get_server_status_request_result() -> void:
	unexpected_disconnect = false
	Logger.log("True result received from Proxy for 'validate version and get server status' request: Gateway server is online and game version is valid.")
	Scenes.BootScreen.queued_account_creation = true
	if (Scenes.BootScreen.phase == Scenes.BootScreen.PhaseType.LIMBO):
		Scenes.BootScreen.start_account_creation()

#Called by: Proxy
#When: Received false result for "gateway connection" request.
#Arguments: Receives denial reason and version details. Will only provide required version if version's outdated.
remote func false_validate_version_and_get_server_status_request_result(required_version: String, denial_reason: String, latest_version: String) -> void:
	unexpected_disconnect = false	
	if (required_version != "" and denial_reason == ""):
		Logger.error("New update available. Must run on version " + required_version + ", latest version is " + latest_version + ". Currently running on " + GlobalData.version + ".", Logger.ALERT)
		Scenes.BootScreen.display_error("New update available, please install v" + latest_version + " from the #releases channel to be able to play.")		
	if (denial_reason != ""):
		Logger.error("False result received from Proxy for gateway connection request: " + denial_reason + ".", Logger.ALERT)
		var error_message := "Couldn't connect to server:\n" + denial_reason
		if (required_version != ""):
			error_message += "\nAdditionally, please install v" + latest_version + " from the #releases channel to be able to play."
		Scenes.BootScreen.display_error(error_message)
