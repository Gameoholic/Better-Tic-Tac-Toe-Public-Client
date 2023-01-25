extends Node

"""
This Tutorial script is a copy of the GameContainer script, except it ignores all network related calls and procedures.
"""

signal cell_click
signal release_right_click
signal game_button_click

enum {O, X, Expansion, Empty, IDLE}

onready var tutorial_box: ColorRect = $TutorialBox

var map := {} #cell (Vector2), tile (Tile)
var turn: int = X
var mark: int
var expansions := 2
var game_ended := false
var winner_mark: int
var x_expansions := 2
var o_expansions := 2
var made_any_move := false

var game_button_allowed: bool




#Visual information variables:
#	Will be used to update the Game scene with data such as outlines, tiles and text when loaded and hosting the game that the game container belongs to.
#	The Game scene is the "visual representation" of the GameContainer. There can be multiple GameContainers, only one Game scene.


var outline_center_cells := [] #Contains ALL center cells (Vector2) that define outlines for this specific game container
var top_text: String = ""
var bottom_text: String = "X: " + str(x_expansions) + "\nO: " + str(o_expansions)
var game_button_text: String = "..."
var expansion_button_text: String = "EXPAND\n2 available"
var top_timer_text: String = ""
var bottom_timer_text: String = ""
var opponent_name_text: String = ""


#Specific to tutorial:

var started := false
var progress := 1
var maps := {} #progress(int): map

#Checked in game.gd:
var game_button_usage_allowed: bool
var expansion_button_usage_allowed: bool
var expansions_allowed: bool
var tile_placement_allowed: bool

func start() -> void:
	tutorial_box.visible = true
	tutorial_box.set_progress(1)
	mark = X
	visual_set_text("opponent_name", "Tutorial\nYou're X")
	visual_set_text("top_text", "X TURN")
	visual_set_text("game_button_text", "...")
	$TutorialBox.visible = true
	started = true
	

func on_tutorial_progressed(new_progress: int) -> void:
	if (new_progress >= progress):
		maps[new_progress] = map.duplicate()
	else:
		map = maps[new_progress].duplicate()
		redraw_grid()
	progress = new_progress
	match progress:
		1:
			$Timer1.start(300)
			$Timer2.start(300)
			$Timer1.set_paused(true)
			$Timer2.set_paused(true)			
			turn = IDLE
			visual_set_text("game_button_text", "...")
		2:
			tutorial_box.set_next_visible(false)
			$Timer1.start(300)
			$Timer1.set_paused(false)	
			set_turn(X)
			game_button_usage_allowed = false
			expansion_button_usage_allowed = false
			expansions_allowed = false
			made_any_move = false
			tile_placement_allowed = true
		3:
			made_any_move = true
			visual_set_text("game_button_text", "End\nTurn")			
			tutorial_box.set_next_visible(false)
			game_button_usage_allowed = true
		4:
			$Timer1.set_paused(true)	
			$Timer2.set_paused(false)							
			if (map[Vector2(1,1)].id != Empty):
				place_tile(Vector2(0, 0), O)
			else:
				place_tile(Vector2(1, 1), O)
			AudioPlayer.play_sound("place")
			set_turn(X)
			$Timer1.set_paused(false)	
			$Timer2.set_paused(true)	
			game_button_usage_allowed = false
			tile_placement_allowed = false
		5:
			tutorial_box.set_next_visible(false)
			expansion_button_usage_allowed = true
		6:
			x_expansions = 2
			expansions = 2
			visual_set_text("game_button_text", "Skip\nTurn")
			made_any_move = false
			tile_placement_allowed = false
			game_button_usage_allowed = false
			visual_update_expansion_button()	
			tutorial_box.set_next_visible(false)			
			expansions_allowed = true
			visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))			
		7:
			$Timer1.set_paused(false)	
			$Timer2.set_paused(true)
			made_any_move = true
			turn = X
			visual_set_text("top_text", "X TURN")
			visual_set_text("game_button_text", "End\nTurn")			
			tutorial_box.set_next_visible(false)			
			expansions_allowed = false
			game_button_usage_allowed = true
		8:
			$Timer1.set_paused(true)	
			$Timer2.set_paused(false)
		9:
			$Timer1.set_paused(true)	
			$Timer2.set_paused(false)
			expansions_allowed = false
			tile_placement_allowed = false
			o_expansions = 2
			x_expansions = 1
			visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))
			visual_set_text("game_button_text", "...")					
		10:
			$Timer1.set_paused(false)	
			$Timer2.set_paused(true)
			tutorial_box.set_next_visible(false)						
			game_button_usage_allowed = false
			tile_placement_allowed = true
			expansions_allowed = true
			made_any_move = false
			AudioPlayer.play_sound("skip_turn")
			expansions = 3
			o_expansions = 3
			end_turn()
			x_expansions = 3
			expansions = 3
			turn = X
			visual_set_text("top_text", "X TURN")			
			visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))			
			visual_set_text("game_button_text", "Skip\nTurn")
			visual_update_expansion_button()			
		11:
			$Timer1.set_paused(true)	
			$Timer2.set_paused(false)
		15:
			$Timer1.set_paused(true)	
			$Timer2.set_paused(false)
			x_expansions = 0
			visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))
			visual_update_expansion_button()					
		16:
			$Timer1.set_paused(true)	
			$Timer2.set_paused(true)
			end_turn()
			visual_set_text("game_button_text", "Skip\nTurn")			
			AudioPlayer.play_sound("skip_turn")			
			x_expansions = 99
			expansions = 99
			visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))			
			visual_update_expansion_button()	
	

"""
Visual information update methods:
"""
func _process(delta: float) -> void:
	#TODO: Optimize this to maybe not update it 60 times a second, especially if >60s
	if (game_ended || !started):
		return
	visual_set_timer("timer1", $Timer1.time_left)
	visual_set_timer("timer2", $Timer2.time_left)
func visual_add_outline(center_cell: Vector2) -> void:
	if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("Main/Camera/Grid/Outline")):
		var Outline: Node = Scenes.Game.get_node("Main/Camera/Grid/Outline")
		Outline.add_center_cell(center_cell)
		Outline.update()
	outline_center_cells.append(center_cell)
func visual_add_tile(tile: Dictionary) -> void:
	if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("Main/Camera/Grid/Tiles")):
		var Tiles: Node = Scenes.Game.get_node("Main/Camera/Grid/Tiles")
		Tiles.set_cell(tile.x, tile.y, tile.id)
func visual_set_text(node_name: String, value: String) -> void:
	if (node_name == "top_text"):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/TopText/Text")):		
			var top_text_node: Node = Scenes.Game.get_node("GUI/GUI/TopText/Text")
			top_text_node.text = value
		top_text = value
	elif (node_name == "bottom_text"):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/BottomText/Text")):				
			var bottom_text_node: Node = Scenes.Game.get_node("GUI/GUI/BottomText/Text")
			bottom_text_node.text = value
		bottom_text = value
	elif (node_name == "game_button_text"):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/GameButton/Text")):						
			var game_button_text_node: Node = Scenes.Game.get_node("GUI/GUI/GameButton/Text")
			game_button_text_node.text = value
		game_button_text = value
	elif (node_name == "expansion_button_text"):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/ExpansionButton/Text")):						
			var expansion_button_text_node: Node = Scenes.Game.get_node("GUI/GUI/ExpansionButton/Text")
			expansion_button_text_node.text = value
		expansion_button_text = value
	elif (node_name == "opponent_name"):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/OpponentName")):						
			var opponent_name_text_node: Node = Scenes.Game.get_node("GUI/GUI/OpponentName")
			opponent_name_text_node.text = value
		opponent_name_text = value		
func visual_set_timer(timer_name: String, seconds: float):
	var timer_text: String = "%02d:%02d" % [int(seconds)/60, int(seconds)%60]
	#timer1 - X, timer2 - O
	if ((timer_name == "timer1" and mark == X) || (timer_name == "timer2" and mark == O)):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator")):								
			var top_timer_text_node: Node = Scenes.Game.get_node("GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator")
			top_timer_text_node.text = timer_text
		top_timer_text = timer_text
	elif ((timer_name == "timer1" and mark == O) || (timer_name == "timer2" and mark == X)):
		if (Scenes.current_scene.name == "Game" and Scenes.Game.has_node("GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator")):										
			var bottom_timer_text_node: Node = Scenes.Game.get_node("GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator")
			bottom_timer_text_node.text = timer_text
		bottom_timer_text = timer_text
func visual_update_expansion_button() -> void:
	var your_expansions: int = x_expansions
	if (mark == O):
		your_expansions = o_expansions
	if (Scenes.current_scene.name == "Game"):
		var tile_texture_node: NinePatchRect = Scenes.Game.get_node("GUI/GUI/TileDisplay/TileTexture")
		match Scenes.Game.cell_selection_mode:
			"tile":
				tile_texture_node.region_rect.position = Vector2(1, 1)
				if (mark == X):
					tile_texture_node.region_rect.position = Vector2(1, 66)
				visual_set_text("expansion_button_text", "EXPAND\n" + str(your_expansions) + " available")
			"expansion":
				tile_texture_node.region_rect.position = Vector2(1, 130)
				visual_set_text("expansion_button_text", "EXPANDING\n" + str(your_expansions) + " available")
				
	if (progress == 5):
		tutorial_box.set_progress(6)

"""
Game methods:
"""
func _ready() -> void:
	generate_grid_around_center(Vector2(0, 0))
	maps[1] = map.duplicate()
	$TutorialBox.visible = false

#Signal-function: cell_clicked.
func _on_Tutorial_cell_click(clicked_cell: Vector2) -> void:
	made_any_move = true
	place_tile(clicked_cell, mark, false, true)
	AudioPlayer.play_sound("place")
	var server_data = {"tile": clicked_cell}
	if (expansions == 0):
		AudioPlayer.play_sound("end_turn")
		end_turn()
	else:
		visual_set_text("game_button_text", "End\nTurn")

#Signal-function: cell_clicked.
func _on_Tutorial_release_right_click(expansion_data: Dictionary) -> void:
	made_any_move = true
	expansions -= 1
	if (turn == X):
		x_expansions -= 1
	else:
		o_expansions -= 1
	if (expansions == 0):
		end_turn()
	else:
		visual_set_text("game_button_text", "End\nTurn")
	visual_update_expansion_button()
	visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))
	AudioPlayer.play_sound("expansion")
	if (progress == 6):
		tutorial_box.set_progress(7)
	
#Signal-function: game_button_click.
func _on_Tutorial_game_button_click() -> void:
	#End Turn:
	if (made_any_move):
		end_turn()
		AudioPlayer.play_sound("end_turn")
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
		AudioPlayer.play_sound("skip_turn")
	
#Places a tile and adds it to the map
func place_tile(pos: Vector2, id: int, is_center_of_local_grid: bool = false, check_for_victory: bool = false) -> void:
	
	visual_add_tile({"x": pos.x, "y": pos.y, "id": id})
	#If tile overrides empty center tile, set its center status to true
	if (map.has(pos) && map[pos].is_center_of_local_grid):
		is_center_of_local_grid = true
	var tile: Tile = Tile.new(id, is_center_of_local_grid)
	map[pos] = tile
	if (Scenes.current_scene.name == "Game"):
		Scenes.Game.expansion_data[pos] = tile.to_dictionary() #If the tile is part of an expansion, it will be used in expansion_data, if it is not, this line can be safely ignored.
	if (check_for_victory):
		check_for_victory(pos, id)
		
	if (progress == 2):
		tutorial_box.set_progress(3)

#Places tiles using a given dictionary where the keys are positions of the tiles and the values are the tiles themselves.
func place_tiles(tiles: Dictionary):
	for tile_position in tiles.keys():
		place_tile(tile_position, tiles[tile_position].id, tiles[tile_position].is_center_of_local_grid)

func end_turn() -> void:
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
	Scenes.Game.cell_selection_mode = "tile"
	visual_update_expansion_button()
	visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))
	
	if (progress == 3):
		tutorial_box.set_progress(4)
	if (progress == 7):
		tutorial_box.set_progress(8)
	if (progress == 10 and expansions == 0):
		tutorial_box.set_progress(11)

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

#WARNING: This will take time if the map size is large. Should only be used on small map sizes.
func redraw_grid() -> void:
	#Reset map:
	var Outline: Node = Scenes.Game.get_node("Main/Camera/Grid/Outline")
	Outline.all_outlines = []
	Outline.update()
	var Tiles: Node = Scenes.Game.get_node("Main/Camera/Grid/Tiles")
	Tiles.clear()
	
	for cell in map:
		visual_add_tile({"x": cell.x, "y": cell.y, "id": map[cell].id})
		if (map[cell].is_center_of_local_grid):
			visual_add_outline(cell)
	
func _on_Timer1_timeout():
	pass # Replace with function body.


func _on_Timer2_timeout():
	pass # Replace with function body.

"""
Tutorial methods:
	These are meant to be used for when the game's state needs to change for the tutorial
"""

	
func set_turn(receieved_turn: int) -> void:
	turn = receieved_turn
	if (turn == X):
		visual_set_text("top_text", "X TURN")
	else:
		visual_set_text("top_text", "O TURN")
	if (turn == mark):
		visual_set_text("game_button_text", "Skip\nTurn")
		AudioPlayer.play_sound("your_turn")
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
	visual_update_expansion_button()
	visual_set_text("bottom_text", "X: " + str(x_expansions) + "\nO: " + str(o_expansions))
