extends Node

onready var LoginScreen_ := get_node("/root/LoginScreen")

var network := NetworkedMultiplayerENet.new()
var ip: String
var port: int
var token: String

var game_container: Node #The game_container the game is currently connected to

func _ready() -> void:
	ip = GlobalData.connection_ip

func connect_to_server() -> void:
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	 
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	
func _on_connection_failed() -> void:
	Logger.error("Failed to connect to gameserver.", Logger.Error)
	get_node("/root/LoginScreen").enable_buttons()
	 
func _on_connection_succeeded() -> void:
	Logger.log("Succesfully connected to gameserver. Waiting for token verification.")

func fetch_player_stats() -> void:
	rpc_id(1, "fetch_player_stats")
	
remote func return_player_stats(stats) -> void:
	print(stats)
	
#Send token to gameserver
remote func send_token() -> void:
	Logger.log("Sending token to gameserver.")
	rpc_id(1, "receive_token", token)
	
remote func return_token_verification_results(result: bool) -> void:
	if result == true:
		Logger.log("Successful token verification, logged into gameserver.")
		LoginScreen_.on_successful_connection_to_server()
	else:
		Logger.error("Token verification failed. Logged out of gameserver.", Logger.Error)
		LoginScreen_.enable_buttons()

remote func queue_for_game(game_type: String) -> void:
	Logger.log("Queuing for a game: " + str(game_type))
	rpc_id(1, "queue_for_game", game_type)

remote func remove_from_queue(game_type: String) -> void:
	Logger.log("Dequeuing for a game: " + str(game_type))
	rpc_id(1, "remove_from_queue", game_type)

onready var game_container_scene := preload("res://Network/GameContainer/GameContainer.tscn")

remote func connect_to_game(game_id: String, player_displaynames: Array) -> void:
	#Determine opponent name:
	var opponent_name: String
	for player_displayname in player_displaynames:
		if (player_displayname != GlobalData.displayname):
			opponent_name = player_displayname
	Logger.log("Found game, game ID:" + str(game_id))
	get_node("/root/MainMenu").on_game_found()
	yield(get_tree().create_timer(2), "timeout")
	Logger.log("Connecting to game " + str(game_id))
	#Create game container:
	var new_game_container := game_container_scene.instance()
	new_game_container.name = game_id
	new_game_container.opponent_name = opponent_name
	add_child(new_game_container, true)
	game_container = get_node(game_id)
	Logger.log("Connected to game " + str(game_id))
	game_container.confirm_connection()
	#Switch to game scene:
	get_tree().change_scene("res://Game/Game.tscn")
	
