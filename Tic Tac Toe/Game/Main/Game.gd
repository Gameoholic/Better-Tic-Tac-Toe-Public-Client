extends Node

signal scene_cleaned_up
var cleaned_up := false

signal cell_clicked
signal cell_right_clicked
signal button_clicked

enum {O, X, Expansion, Empty}
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
	
func _ready() -> void:
	var scene_data: Dictionary = Scenes.transferred_scene_data
	Scenes.on_scene_loaded()
	
	#Load visual data from GameContainer:
	for cell in GameServer.game_container.map:
		Tiles.set_cell(cell.x, cell.y, GameServer.game_container.map[cell].id)
	for outline_center_cell in GameServer.game_container.outline_center_cells:
		Outline.add_center_cell(outline_center_cell)
	Outline.update()
	
	$"GUI/GUI/TopText/Text".text = GameServer.game_container.top_text
	$"GUI/GUI/BottomText/Text".text = GameServer.game_container.bottom_text
	$"GUI/GUI/GameButton/Text".text = GameServer.game_container.game_button_text
	$"GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator".text = GameServer.game_container.top_timer_text
	$"GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator".text = GameServer.game_container.bottom_timer_text
	$"GUI/GUI/OpponentName".text = GameServer.game_container.opponent_name_text
	
	GameServer.game_container.visual_update_expansion_button()
	
	if (GameServer.game_container.game_ended):
		GameServer.game_container.victory()

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
	if (GameServer.game_container.game_ended):
		return
	if (!GameServer.game_container.map.has(clicked_cell) || GameServer.game_container.map[clicked_cell].id != Empty):
		return
	if (GameServer.game_container.made_any_move):
		return
	if (GameServer.game_container.turn != GameServer.game_container.mark):
		return
	GameServer.game_container.emit_signal("cell_click", clicked_cell)

#Signal-function: cell_right_clicked. Fired when a cell is right clicked.
func _on_Game_cell_right_clicked(clicked_cell: Vector2, released: bool):
	if (GameServer.game_container.game_ended):
		return
	if (GameServer.game_container.turn != GameServer.game_container.mark):
		return
	if (GameServer.game_container.expansions == 0):
		return
	if (!released and (!GameServer.game_container.map.has(clicked_cell) || GameServer.game_container.map[clicked_cell].id != Empty)):
		return
	#If the player is holding right click:
	if (!released):
		Expansions.preview_expansion_first_time(clicked_cell)
	#If the player released right click, place the expansion
	elif (in_expansion_selection):
		var origin_expansion_cell: Vector2
		expansion_data.clear()
		Expansions.place_expansion() #This updates expansion_data with the new expansion tiles
		for pos in expansion_data:
			if (expansion_data[pos].id == Expansion):
				origin_expansion_cell = pos
		GameServer.game_container.emit_signal("release_right_click", {"cell": origin_expansion_cell, "direction": current_expansion_direction})

#On Skip/End Turn Button Clicked
func _on_Game_button_clicked() -> void:
	if (GameServer.game_container.game_ended):
		return
	if (GameServer.game_container.turn != GameServer.game_container.mark):
		return
	GameServer.game_container.emit_signal("game_button_click")


func _on_ErrorText_confirmed():
	match error_text_source:
		"gameserver_disconnect":
			Scenes.change_scene(Scenes.BootScreen_path, {})
