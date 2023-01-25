extends Node

signal scene_cleaned_up
var cleaned_up := false

signal cell_clicked
signal cell_right_clicked
signal button_clicked
signal expansion_button_clicked

enum {O, X, Expansion, Empty, IDLE}
enum {Top, Bottom, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight}

var Tile = preload("res://Classes/Tile.gd")
onready var GameServer := $"/root/Network/GameServer"
onready var Outline: Node = $"Main/Camera/Grid/Outline"
onready var Tiles: Node = $"Main/Camera/Grid/Tiles"
onready var TilesPreview: Node = $"Main/Camera/Grid/TilesPreview"
onready var Expansions: Node = $"Main/Expansions"

onready var tint := $"ErrorCanvas/Tint"
onready var error_text := $"ErrorCanvas/ErrorText"

#Expansion variables:
var expansion_data := {}
var origin_expansion_cell: Vector2
var origin_mouse_coords: Vector2
var possible_expansions: Dictionary
var in_expansion_selection: bool
var current_expansion_direction: String
var cell_selection_mode := "tile" #"tile" or "expansion"

var error_text_source: String #"gameserver_disconnect" or "logged_into_warning"

var is_tutorial: bool
var game_container_node: Node #Is either GameServer.game_container or $Tutorial
	
func _ready() -> void:
	var scene_data: Dictionary = Scenes.transferred_scene_data
	Scenes.on_scene_loaded()
	
	CustomButtons.enable()
	#If the scene was loaded as a tutorial from the main menu, don't treat it as a game
	if (scene_data.has("tutorial")):
		$"%Tutorial".start()
		is_tutorial = true
		game_container_node = $"%Tutorial"
	else:
		is_tutorial = false
		game_container_node = GameServer.game_container
	Expansions.game_container_node = game_container_node
	$"GUI/GUI".game_container_node = game_container_node	

	#Load visual data from GameContainer:
	for cell in game_container_node.map:
		Tiles.set_cell(cell.x, cell.y, game_container_node.map[cell].id)
	for outline_center_cell in game_container_node.outline_center_cells:
		Outline.add_center_cell(outline_center_cell)
	Outline.update()
	
	$"GUI/GUI/TopText/Text".text = game_container_node.top_text
	$"GUI/GUI/BottomText/Text".text = game_container_node.bottom_text
	$"GUI/GUI/GameButton/Text".text = game_container_node.game_button_text
	$"GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator".text = game_container_node.top_timer_text
	$"GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator".text = game_container_node.bottom_timer_text
	$"GUI/GUI/OpponentName".text = game_container_node.opponent_name_text
	
	game_container_node.visual_update_expansion_button()
	
	if (game_container_node.game_ended):
		game_container_node.victory()

func clean_up_scene() -> void: #Ran right before the scene is switched - blocking
	cleaned_up = true
	emit_signal("scene_cleaned_up")

func _process(delta: float) -> void:
	if (in_expansion_selection):
		Expansions.preview_expansion()
		
func _input(event):
	if (event is InputEventKey and event.scancode == KEY_SPACE):
		_on_Game_button_clicked()
		
#Signal-function: cell_clicked. Fired when a cell is clicked.
func _on_Game_cell_clicked(clicked_cell: Vector2):
	#In tutorial, prevent placing when not wanted
	if (is_tutorial && !game_container_node.tile_placement_allowed):
		return
	if (game_container_node.game_ended):
		return
	if (!game_container_node.map.has(clicked_cell) || game_container_node.map[clicked_cell].id != Empty):
		return
	if (game_container_node.made_any_move):
		return
	if (game_container_node.turn != game_container_node.mark):
		return
	game_container_node.emit_signal("cell_click", clicked_cell)

#Signal-function: cell_right_clicked. Fired when a cell is right clicked.
func _on_Game_cell_right_clicked(clicked_cell: Vector2, released: bool):
	#In tutorial, prevent using expansions when not wanted
	if (game_container_node.turn == IDLE || (is_tutorial && !game_container_node.expansions_allowed)):
		return
	if (game_container_node.game_ended):
		return
	if (game_container_node.turn != game_container_node.mark):
		return
	if (game_container_node.expansions == 0):
		return
	if (!released and (!game_container_node.map.has(clicked_cell) || game_container_node.map[clicked_cell].id != Empty)):
		return
	#If the player is holding right click:
	if (!released):
		Expansions.preview_expansion_first_time(clicked_cell)
	#If the player released right click:
	elif (in_expansion_selection):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var cancel_button: NinePatchRect = Scenes.Game.get_node("GUI/GUI/CancelDisplay")
		var cancel_pos: Vector2 = cancel_button.get_global_transform_with_canvas().get_origin()
		var cancel_size = cancel_button.rect_size * cancel_button.get_global_transform_with_canvas().get_scale()
		
		#If released on Cancel button:
		if (mouse_pos.x > cancel_pos.x and mouse_pos.x < (cancel_pos.x + cancel_size.x) and mouse_pos.y > cancel_pos.y and mouse_pos.y < (cancel_pos.y + cancel_size.y)):
			Scenes.Game.in_expansion_selection = false
			TilesPreview.clear()
			expansion_data.clear()
			cancel_button.visible = false
		
		#Otherwise, place the expansion:
		else:
			var origin_expansion_cell: Vector2
			expansion_data.clear()
			Expansions.place_expansion() #This updates expansion_data with the new expansion tiles
			for pos in expansion_data:
				if (expansion_data[pos].id == Expansion):
					origin_expansion_cell = pos
			game_container_node.emit_signal("release_right_click", {"cell": origin_expansion_cell, "direction": current_expansion_direction})

#Signal-function: expansion_button_clicked. Fired when the expansion button is clicked.
func _on_Game_expansion_button_clicked():
	#In tutorial, prevent using the expansion button when not wanted
	if (game_container_node.turn == IDLE || (is_tutorial && !game_container_node.expansion_button_usage_allowed)):
		return
	match cell_selection_mode:
		"tile":
			cell_selection_mode = "expansion"
		"expansion":
			cell_selection_mode = "tile"
	game_container_node.visual_update_expansion_button()

#On Skip/End Turn Button Clicked
func _on_Game_button_clicked() -> void:
	#In tutorial, prevent using the game button when not wanted
	if (game_container_node.turn == IDLE || (is_tutorial && !game_container_node.game_button_usage_allowed)):
		return
	if (game_container_node.game_ended):
		return
	if (game_container_node.turn != game_container_node.mark):
		return
	game_container_node.emit_signal("game_button_click")


func _on_ErrorText_confirmed():
	match error_text_source:
		"gameserver_disconnect":
			Scenes.change_scene(Scenes.BootScreen_path, {})

