extends Node

var network := NetworkedMultiplayerENet.new()
var ip: String
var port: int
var token: String
var unexpected_disconnect: bool #True if connected to server, but unexpectedly lost connection after, without receiving expected result

var game_container: Node #The game_container the game is currently connected to

func _ready() -> void:
	ip = GlobalData.connection_ip

func connect_to_server() -> void:
	network.create_client(ip, port)
	get_tree().set_network_peer(null) #Force reset multiplayer API
	get_tree().set_network_peer(network)
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("server_disconnected", self, "_on_server_disconnected")
	
func _on_connection_failed() -> void:
	Logger.error("Failed to connect to gameserver.", Logger.ERROR)
	network.close_connection()
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	Scenes.BootScreen.display_error("Couldn't connect to server. Please try again later or contact support.")
	 
func _on_connection_succeeded() -> void:
	unexpected_disconnect = true
	Logger.log("Succesfully connected to gameserver. Waiting for token verification.")

func _on_server_disconnected() -> void:
	if (unexpected_disconnect): #If disconnected without clicking on 'Back to menu' button
		Logger.error("Lost connection to Gameserver.", Logger.ERROR)	
		network.disconnect("connection_failed", self, "_on_connection_failed")
		network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
		network.disconnect("server_disconnected", self, "_on_server_disconnected")
		match get_tree().get_current_scene().name:
			"Scenes.BootScreen":
				Scenes.BootScreen.display_error("Lost connection to server. Please check your internet connection or contact support.")
			"MainMenu":
				Scenes.MainMenu.error_text_source = "gameserver_disconnect"
				Scenes.MainMenu.tint.visible = true
				Scenes.MainMenu.error_text_dialog.dialog_text = "Lost connection to Server. Please check your internet connection or contact support."
				CustomButtons.disable()
				Scenes.MainMenu.error_text_dialog.show()
			"Game":
				Scenes.Game.error_text_source = "gameserver_disconnect"
				Scenes.Game.tint.visible = true
				Scenes.Game.error_text.dialog_text = "Lost connection to Server. Please check your internet connection or contact support."
				Scenes.Game.error_text.show()
	else:
		Logger.log("Disconnected from Gameserver.")
	
func close_connection() -> void:
	Logger.log("Closed connection to Gameserver.")
	network.close_connection()
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	
	
#Send token to gameserver
remote func send_token() -> void:
	Logger.log("Sending token to gameserver.")
	rpc_id(1, "receive_token", token)
	
remote func receive_token_verification_results(result: bool) -> void:
	if (result == true):
		Logger.log("Successful token verification, logged into gameserver.")
		Scenes.BootScreen.on_successful_connection_to_gameserver()
	else:
		unexpected_disconnect = false
		Logger.error("Token verification failed. Logged out of gameserver.", Logger.ERROR)
		Scenes.BootScreen.display_error("Couldn't connect to server. Please try again later or contact support.")
			

func queue_for_game_request(game_type: String) -> void:
	Logger.log("Queuing for a game: " + str(game_type) + ".")
	rpc_id(1, "queue_for_game_request", game_type)

func remove_from_queue_request(game_type: String) -> void:
	Logger.log("Dequeuing from a game: " + str(game_type) + ".")
	rpc_id(1, "remove_from_queue_request", game_type)

onready var game_container_scene := preload("res://Network/GameContainer/GameContainer.tscn")

remote func connect_to_game(game_id: String, player_displaynames: Array) -> void:
	#Determine opponent name:
	var opponent_name: String
	for player_displayname in player_displaynames:
		if (player_displayname != GlobalData.displayname):
			opponent_name = player_displayname
	Logger.log("Found game, game ID: " + str(game_id) + ".")
	Scenes.MainMenu.on_game_found()
	yield(get_tree().create_timer(2), "timeout")
	Logger.log("Connecting to game " + str(game_id) + ".")
	#Create game container:
	var new_game_container := game_container_scene.instance()
	new_game_container.name = game_id
	new_game_container.opponent_name = opponent_name
	add_child(new_game_container, true)
	game_container = get_node(game_id)
	Logger.log("Connected to game " + str(game_id) + ".")
	game_container.confirm_connection()
	#Switch to game scene:
	Scenes.change_scene(Scenes.Game_path)
	
remote func receive_kick_reason(reason: String) -> void:
	unexpected_disconnect = false
	Logger.error("Kicked from gameserver: " + reason + ".", Logger.ERROR)	
	network.disconnect("connection_failed", self, "_on_connection_failed")
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("server_disconnected", self, "_on_server_disconnected")
	match Scenes.current_scene.name:
		"BootScreen":
			Scenes.BootScreen.display_error("Lost connection to server. " + reason)
		"MainMenu":
			Scenes.MainMenu.error_text_source = "gameserver_disconnect"
			Scenes.MainMenu.tint.visible = true
			Scenes.MainMenu.error_text_dialog.dialog_text = "Lost connection to server. " + reason
			CustomButtons.disable()
			Scenes.MainMenu.error_text_dialog.show()
		"Game":
			Scenes.Game.error_text_source = "gameserver_disconnect"
			Scenes.Game.tint.visible = true
			Scenes.Game.error_text.dialog_text = "Lost connection to Server. Please check your internet connection or contact support."
			Scenes.Game.error_text.show()

"""
reset_auth_token_request:
	Requests to reset the auth token. Will not return an error if the request couldn't be fulfilled.
	Called by:
		MainMenu.gd
	When:
		The user logs out
"""
func reset_auth_token_request() -> void:
	Logger.log("Sending reset auth token request.")
	rpc_id(1, "reset_auth_token_request")

"""
replace_temp_password_request:
	Requests to replace the initial, temp password of a user with a custom one they picked from the gameserver. The request is later passed on to Master and then to Authentication.
	Will not return an error if the request couldn't be fulfilled.
	Called by:
		MainMenu.gd
	When:
		A user accepts the "create an account" popup - as in, picks a password after the account is already created
	Arguments:
		The new password, HASHED at least once
"""
func replace_temp_password_request(new_password: String) -> void:
	Logger.log("Sending replace temp password request.")
	rpc_id(1, "replace_temp_password_request", new_password)
	
func send_console_command(command: String) -> void:
	var args = command.split(" ", false)
	match args[0]:
		"friend_add":
			rpc_id(1, "friend_rq_request", args[1])
			Logger.log("Sent 'friend request' request: " + args[1])
		"friend_accept":
			rpc_id(1, "friend_accept_request", args[1])
			Logger.log("Sent 'friend accept' request: " + args[1])
		"friend_deny":
			rpc_id(1, "friend_deny_request", args[1])
			Logger.log("Sent 'friend deny' request: " + args[1])
		"friend_cancel":
			rpc_id(1, "friend_cancel_request", args[1])
			Logger.log("Sent 'friend cancel' request: " + args[1])
		"friend_remove":
			rpc_id(1, "friend_remove_request", args[1])
			Logger.log("Sent 'friend remove' request: " + args[1])
		"block_add":
			rpc_id(1, "block_add_request", args[1])
			Logger.log("Sent 'block add' request: " + args[1])
		"block_remove":
			rpc_id(1, "block_remove_request", args[1])
			Logger.log("Sent 'block remove' request: " + args[1])
			#DOn't forget to make this cancel existing frq's
			pass
		_:
			Logger.error("Unknown console command.", Logger.ERROR)
			


"""
FRIEND REQUESTS & SOCIAL:
"""
#When: Received result for 'friend request' request
remote func receive_friend_rq_request_result(result: bool, error_code: String) -> void:
	Logger.log("friend rq result:" + str(result) + ": " + str(error_code))

#When: Received friend request from user
remote func receive_friend_rq(sender_displayname: String) -> void:
	Logger.log("firend req from:" + str(sender_displayname))

#When: Received result for 'friend accept' request
remote func receive_friend_accept_request_result(result: bool, error_code: String) -> void:
	Logger.log("accept:" + str(result) + ": " + str(error_code))
	
#When: User accepted friend request
remote func receive_friend_accept(sender_displayname: String) -> void:
	Logger.log("firend accepted from:" + str(sender_displayname))

#When: Received result for 'friend deny' request
remote func receive_friend_deny_request_result(result: bool, error_code: String) -> void:
	Logger.log("deny:" + str(result) + ": " + str(error_code))
	
#When: Received result for 'friend cancel' request
remote func receive_friend_cancel_request_result(result: bool, error_code: String) -> void:
	Logger.log("friend cancel result:" + str(result) + ": " + str(error_code))

#When: Friend request cancelled by user
remote func receive_friend_cancel(sender_displayname: String) -> void:
	Logger.log("firend cancel from:" + str(sender_displayname))

#When: Received result for 'friend remove' request
remote func receive_friend_remove_request_result(result: bool, error_code: String) -> void:
	Logger.log("friend remove result:" + str(result) + ": " + str(error_code))

#When: Friend removed
remote func receive_friend_remove(sender_displayname: String) -> void:
	Logger.log("firend removed:" + str(sender_displayname))

#When: Received result for 'block add' request
remote func receive_block_add_request_result(result: bool, error_code: String) -> void:
	Logger.log("block add result:" + str(result) + ": " + str(error_code))

#When: Received result for 'block remove' request
remote func receive_block_remove_request_result(result: bool, error_code: String) -> void:
	Logger.log("block remove result:" + str(result) + ": " + str(error_code))
