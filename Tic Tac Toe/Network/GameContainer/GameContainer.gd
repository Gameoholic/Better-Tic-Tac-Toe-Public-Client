extends Node

onready var GameServer_ := $"/root/Network/GameServer"

signal cell_click
signal release_right_click
signal game_button_click

enum {O, X, Expansion, Empty}

var map := {} #cell (Vector2), tile (Tile)
var turn: int = X
var mark: int
var expansions := 2
var game_ended := false
var winner_mark: int
var x_expansions := 2
var o_expansions := 2
var made_any_move := false

var opponent_name: String

var Game_: WeakRef #Will be set when the Game scene loads

"""
Visual information variables:
	Will be used to update the Game scene with data such as outlines, tiles and text when loaded and hosting the game that the game container belongs to.
"""

#In future: may need to add opponent name as well. TODO because it isnt addeda lready

var outline_center_cells := [] #Contains ALL center cells (Vector2) that define outlines for this specific gamer container
var top_text: String = ""
var bottom_text: String = "X: " + str(x_expansions) + "\nO: " + str(o_expansions)
var game_button_text: String = "..."
var top_timer_text: String = ""
var bottom_timer_text: String = ""


func confirm_connection() -> void:
	rpc_id(1, "confirm_connection")

remote func send_game_data(data: Dictionary) -> void:
	rpc_id(1, "receive_game_data", data)
	
remote func receive_game_data(data: Dictionary) -> void:
	if (data.has("server_mark")):
		set_mark(data["server_mark"])
	if (data.has("server_turn")):
		set_turn(data["server_turn"])
	if (data.has("server_tile")):
		set_tile(data["server_tile"][0], data["server_tile"][1]) #Cell, Mark
	if (data.has("server_expansion")):
		set_expansion(data["server_expansion"])
	if (data.has("server_add_expansions")):
		add_expansions(data["server_add_expansions"][0], data["server_add_expansions"][1]) #No. of Expansions, Mark
	if (data.has("server_timer1")):
		set_timer1(data["server_timer1"])
	if (data.has("server_timer2")):
		set_timer2(data["server_timer2"])
	if (data.has("server_winner")):
		game_ended = true
		winner_mark = data["server_winner"]
		victory()

"""
Visual information update methods:
"""
func _process(delta: float) -> void:
	#TODO: Optimize this to maybe not update it 60 times a second, especially if >60s
	if (game_ended):
		return
	visual_set_timer("timer1", $Timer1.time_left)
	visual_set_timer("timer2", $Timer2.time_left)

func visual_add_outline(center_cell: Vector2) -> void:
	if (has_node("/root/Game/Grid/Outline")):
		var Outline_: Node = get_node("/root/Game/Grid/Outline")
		Outline_.add_center_cell(center_cell)
		Outline_.update()
	outline_center_cells.append(center_cell)
func visual_add_tile(tile: Dictionary) -> void:
	if (has_node("/root/Game/Grid/Tiles")):
		var Tiles_: Node = get_node("/root/Game/Grid/Tiles")
		Tiles_.set_cell(tile.x, tile.y, tile.id)
func visual_set_text(node_name: String, value: String) -> void:
	if (node_name == "top_text"):
		if (has_node("/root/Game/GUI/GUI/TopText/Text")):
			var top_text_node: Node = $"/root/Game/GUI/GUI/TopText/Text"
			top_text_node.text = value
		top_text = value
	elif (node_name == "bottom_text"):
		if (has_node("/root/Game/GUI/GUI/BottomText/Text")):
			var bottom_text_node: Node = $"/root/Game/GUI/GUI/BottomText/Text"
			bottom_text_node.text = value
		bottom_text = value
	elif (node_name == "game_button_text"):
		if (has_node("/root/Game/GUI/GUI/GameButton/Text")):
			var game_button_text_node: Node = $"/root/Game/GUI/GUI/GameButton/Text"
			game_button_text_node.text = value
		game_button_text = value
func visual_set_timer(timer_name: String, seconds: float):
	var timer_text: String = "%02d:%02d" % [int(seconds)/60, int(seconds)%60]
	#timer1 - X, timer2 - O
	if ((timer_name == "timer1" and mark == X) || (timer_name == "timer2" and mark == O)):
		if (has_node("/root/Game/GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator")):
			var top_timer_text_node: Node = $"/root/Game/GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator"
			top_timer_text_node.text = timer_text
		top_timer_text = timer_text
	elif ((timer_name == "timer1" and mark == O) || (timer_name == "timer2" and mark == X)):
		if (has_node("/root/Game/GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator")):
			var bottom_timer_text_node: Node = $"/root/Game/GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator"
			bottom_timer_text_node.text = timer_text
		bottom_timer_text = timer_text

"""
Server methods:
	These are meant to be used only from the receive_game_data method
"""
func set_mark(receieved_mark: int) -> void:
	mark = receieved_mark
	var mark_string := "X"
	if (mark == O):
		mark_string = "O"
	$"/root/Game/GUI/GUI/OpponentName".text = "Opponent: " + opponent_name + "\nYou're " + mark_string #TODO: don't do it like this, use visual update method
	
	
func set_turn(receieved_turn: int) -> void:
	turn = receieved_turn
	if (turn == X):
		visual_set_text("top_text", "X TURN")
	else:
		visual_set_text("top_text", "O TURN")
	if (turn == mark):
		visual_set_text("game_button_text", "Skip\nTurn")
	else:
		visual_set_text("game_button_text", "...")

func set_tile(cell: Vector2, mark: int) -> void:
	place_tile(cell, mark, false, true)
	
func set_expansion(receieved_expansion_data: Dictionary) -> void:
	for tile_position in receieved_expansion_data:
		var tile = Tile.from_dictionary(receieved_expansion_data[tile_position])
		place_tile(tile_position, tile.id, tile.is_center_of_local_grid)
		if (tile.is_center_of_local_grid):
			visual_add_outline(tile_position)

func add_expansions(expansions: int, mark: int) -> void:
	if (mark == X):
		x_expansions += expansions
	else:
		o_expansions += expansions
	visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))

func set_timer1(timer_data: Dictionary) -> void:
	$Timer1.start(timer_data.seconds)
	$Timer1.set_paused(timer_data.paused)
	visual_set_timer("timer1", timer_data.seconds)

func set_timer2(timer_data: Dictionary) -> void:
	$Timer2.start(timer_data.seconds)
	$Timer2.set_paused(timer_data.paused)
	visual_set_timer("timer2", timer_data.seconds)
	
func victory() -> void:
	$Timer1.set_paused(true)
	$Timer2.set_paused(true)
	if (has_node("/root/Game/GUI/GUI")):
		if (winner_mark == X):
			get_node("/root/Game/GUI/GUI").show_victory_GUI("X")
		else:
			get_node("/root/Game/GUI/GUI").show_victory_GUI("O")
"""
Normal methods:
"""
func _ready() -> void:
	generate_grid_around_center(Vector2(0, 0))
	

#Signal-function: cell_clicked. Fired when a cell is clicked.
func _on_GameContainer_cell_click(clicked_cell: Vector2) -> void:
	made_any_move = true
	place_tile(clicked_cell, mark, false, true)
	var server_data = {"tile": clicked_cell}
	if (expansions == 0):
		end_turn()
		server_data["end_turn"] = true
	else:
		visual_set_text("game_button_text", "End\nTurn")
	send_game_data(server_data)

#Signal-function: cell_clicked. Fired when right click is released.
func _on_GameContainer_release_right_click(expansion_data: Dictionary) -> void:
	var server_data = {}
	server_data["expansion"] = expansion_data
	made_any_move = true
	expansions -= 1
	if (turn == X):
		x_expansions -= 1
	else:
		o_expansions -= 1
	if (expansions == 0):
		end_turn()
		server_data["end_turn"] = true
	else:
		visual_set_text("game_button_text", "End\nTurn")
	visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))
	GameServer_.game_container.send_game_data(server_data)
	
#Signal-function: game_button_click. Fired when the game button is clicked
func _on_GameContainer_game_button_click() -> void:
	var server_data = {}
	#End Turn:
	if (made_any_move):
		end_turn()
		server_data["end_turn"] = true
	#Skip Turn:
	else:
		if (only_one_empty_cell_left() || expansions == 3): #Can't skip turn under these conditions
			return
		expansions += 1
		if (turn == X):
			x_expansions += 1
		else:
			o_expansions += 1
		end_turn()
		server_data["skip_turn"] = true
	send_game_data(server_data)
	
#Places a tile and adds it to the map
func place_tile(pos: Vector2, id: int, is_center_of_local_grid: bool = false, check_for_victory: bool = false) -> void:
	
	visual_add_tile({"x": pos.x, "y": pos.y, "id": id})
	#If tile overrides empty center tile, set its center status to true
	if (map.has(pos) && map[pos].is_center_of_local_grid):
		is_center_of_local_grid = true
	var tile: Tile = Tile.new(id, is_center_of_local_grid)
	map[pos] = tile
	if (Game_ != null && Game_.get_ref()): #If the Game_ object exists and the Game scene is loaded:
		Game_.get_ref().expansion_data[pos] = tile.to_dictionary() #If the tile is part of an expansion, it will be used in expansion_data, if it is not, this line can be safely ignored.
	if (check_for_victory):
		check_for_victory(pos, id)

#Places tiles using a given dictionary where the keys are positions of the tiles and the values are the tiles themselves.
func place_tiles(tiles: Dictionary):
	for tile_position in tiles.keys():
		place_tile(tile_position, tiles[tile_position].id, tiles[tile_position].is_center_of_local_grid)

func end_turn():
	if (game_ended):
		return
	if (turn == X):
		turn = O
	else:
		turn = X
	made_any_move = false
	visual_set_text("game_button_text", "...")
	if (turn == X):
		visual_set_text("top_text", "X TURN")
	else:
		visual_set_text("top_text", "O TURN")
	visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))

#Generates a grid around a center tile. This accounts for already placed tiles.
func generate_grid_around_center(center: Vector2):
	for i in range(-1 + center.x, 2 + center.x, 1):
		for j in range(-1 + center.y, 2 + center.y, 1):
			var pos = Vector2(i, j)
			if (!map.has(pos)):
				#If the tile is in the center of the new grid:
				if (pos == center):
					place_tile(pos, Empty, true)
				#If it isn't:
				else:
					place_tile(pos, Empty)
	visual_add_outline(center)

#Returns whether the tile exists and if its ID is equal to a parameter
func tile_is_of_id(pos: Vector2, param_id: int) -> bool:
	if (!map.has(pos)):
		return false
	if (map[pos].id == param_id):
		return true
	return false

#Returns whether all the tiles exist and if all their ID's are equal to a parameter
func tiles_are_of_id(positions: Array, id: int) -> bool:
	for position in positions:
		if (!tile_is_of_id(position, id)):
			return false
	return true

#Returns whether there is only one empty cell left in the entire grid
func only_one_empty_cell_left() -> bool:
	var count = 0
	for tile in map:
		if (map[tile].id == Empty):
			count += 1
		if (count > 1):
			return false
	return true

#Returns whether there are no cells left in the entire grid
func no_empty_cells_left() -> bool:
	for tile in map:
		if (map[tile].id == Empty):
			return false
	return true

func check_for_victory(tile_pos: Vector2, tile_id: int) -> void:
	var deltas: Array = [
		[Vector2(-1, 0), Vector2(1, 0)],
		[Vector2(-1, 0), Vector2(-2, 0)],
		[Vector2(1, 0), Vector2(2, 0)],
		[Vector2(0, 1), Vector2(0, -1)],
		[Vector2(0, 1), Vector2(0, 2)],
		[Vector2(0, -1), Vector2(0, -2)],
		[Vector2(1, 1), Vector2(2, 2)],
		[Vector2(-1, -1), Vector2(-2, -2)],
		[Vector2(-1, -1), Vector2(1, 1)],
		[Vector2(1, 1), Vector2(2, 2)],
		[Vector2(1, -1), Vector2(2, -2)],
		[Vector2(1, -1), Vector2(-2, 1)],
		[Vector2(-1, 1), Vector2(-2, 2)]
		]
		
	for delta in deltas:
		if (tiles_are_of_id(
			[Vector2(tile_pos.x + delta[0].x, tile_pos.y + delta[0].y), 
			Vector2(tile_pos.x + delta[1].x, tile_pos.y + delta[1].y)], tile_id)):
			game_ended = true
			break
	
	if (no_empty_cells_left()):
		game_ended = true


func _on_Timer1_timeout() -> void:
	game_ended = true

func _on_Timer2_timeout() -> void:
	game_ended = true
