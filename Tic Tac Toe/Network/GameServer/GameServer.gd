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
	print("Failed to connect to game server")
	get_node("/root/LoginScreen").enable_buttons()
	 
func _on_connection_succeeded() -> void:
	print("Succesfully connected to game server. Waiting for token verification.")

func fetch_player_stats() -> void:
	rpc_id(1, "fetch_player_stats")
	
remote func return_player_stats(stats) -> void:
	print(stats)
	
#Send token to gameserver
remote func send_token() -> void:
	rpc_id(1, "receive_token", token)
	
remote func return_token_verification_results(result: bool) -> void:
	if result == true:
		print("Successful token verification.\nYou are now logged in.")
		LoginScreen_.on_successful_connection_to_server()
	else:
		print("Login failed, please try again.")
		LoginScreen_.enable_buttons()

remote func queue_for_game(game_type: String) -> void:
	rpc_id(1, "queue_for_game", game_type)

remote func remove_from_queue(game_type: String) -> void:
	rpc_id(1, "remove_from_queue", game_type)

onready var game_container_scene := preload("res://Network/GameContainer/GameContainer.tscn")

remote func connect_to_game(game_id: String, player_displaynames: Array) -> void:
	#Determine opponent name:
	var opponent_name: String
	for player_displayname in player_displaynames:
		if (player_displayname != GlobalData.displayname):
			opponent_name = player_displayname
	print("Found game!" + str(game_id))
	get_node("/root/MainMenu").on_game_found()
	yield(get_tree().create_timer(2), "timeout")
	print("Connecting to game " + str(game_id) + "...")
	#Create game container:
	var new_game_container := game_container_scene.instance()
	new_game_container.name = game_id
	new_game_container.opponent_name = opponent_name
	add_child(new_game_container, true)
	game_container = get_node(game_id)
	print("Connected to game " + str(game_id))
	game_container.confirm_connection()
	#Switch to game scene:
	get_tree().change_scene("res://Game/Game.tscn")
	
