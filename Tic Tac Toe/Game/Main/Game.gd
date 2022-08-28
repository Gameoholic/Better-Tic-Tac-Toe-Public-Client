extends Node

signal cell_clicked
signal cell_right_clicked
signal button_clicked

enum {O, X, Expansion, Empty}
enum {Top, Bottom, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight}

var Tile = preload("res://Classes/Tile.gd")

onready var GameServer_ := $"/root/Network/GameServer"
onready var Outline_: Node = get_node("/root/Game/Grid/Outline")
onready var Tiles_: Node = get_node("/root/Game/Grid/Tiles")
onready var TilesPreview_: Node = get_node("/root/Game/Grid/TilesPreview")
onready var Expansions_: Node = get_node("/root/Game/Main/Expansions")
onready var Camera_: Node = get_node("/root/Game/Main/Camera")

#Expansion variables:
var expansion_data := {}
var origin_expansion_cell: Vector2
var origin_mouse_coords: Vector2
var possible_expansions: Dictionary
var in_expansion_selection: bool
var current_expansion_direction: String
	
func _ready() -> void:
	GameServer_.game_container.Game_ = weakref(self)
	#Convert existing data in game container to visual data in the Game scene
	for cell in GameServer_.game_container.map:
		Tiles_.set_cell(cell.x, cell.y, GameServer_.game_container.map[cell].id)
	for outline_center_cell in GameServer_.game_container.outline_center_cells:
		Outline_.add_center_cell(outline_center_cell)
	Outline_.update()
	
	$"GUI/GUI/TopText/Text".text = GameServer_.game_container.top_text
	$"GUI/GUI/BottomText/Text".text = GameServer_.game_container.bottom_text
	$"GUI/GUI/GameButton/Text".text = GameServer_.game_container.game_button_text
	$"/root/Game/GUI/GUI/Timers/TopTimer/TextureRect/TimeIndicator".text = GameServer_.game_container.top_timer_text
	$"/root/Game/GUI/GUI/Timers/BottomTimer/TextureRect/TimeIndicator".text = GameServer_.game_container.bottom_timer_text
	
	if (GameServer_.game_container.game_ended):
		GameServer_.game_container.victory()

func _process(delta: float) -> void:
	if (in_expansion_selection):
		Expansions_.preview_expansion()
		
func _input(event):
	if event is InputEventKey and event.scancode == KEY_SPACE:
		_on_Game_button_clicked()
		
#Signal-function: cell_clicked. Fired when a cell is clicked.
func _on_Game_cell_clicked(clicked_cell: Vector2):
	if (GameServer_.game_container.game_ended):
		return
	if (!GameServer_.game_container.map.has(clicked_cell) || GameServer_.game_container.map[clicked_cell].id != Empty):
		return
	if (GameServer_.game_container.made_any_move):
		return
	if (GameServer_.game_container.turn != GameServer_.game_container.mark):
		return
	GameServer_.game_container.emit_signal("cell_click", clicked_cell)

#Signal-function: cell_right_clicked. Fired when a cell is right clicked.
func _on_Game_cell_right_clicked(clicked_cell: Vector2, released: bool):
	if (GameServer_.game_container.game_ended):
		return
	if (GameServer_.game_container.turn != GameServer_.game_container.mark):
		return
	if (GameServer_.game_container.expansions == 0):
		return
	if (!released and (!GameServer_.game_container.map.has(clicked_cell) || GameServer_.game_container.map[clicked_cell].id != Empty)):
		return
	#If the player is holding right click:
	if (!released):
		Expansions_.preview_expansion_first_time(clicked_cell)
	#If the player released right click, place the expansion
	elif (in_expansion_selection):
		expansion_data.clear()
		Expansions_.place_expansion() #This updated expansion_data with the new expansion tiles
		GameServer_.game_container.emit_signal("release_right_click", expansion_data)
#On Skip/End Turn Button Clicked
func _on_Game_button_clicked() -> void:
	if (GameServer_.game_container.game_ended):
		return
	if (GameServer_.game_container.turn != GameServer_.game_container.mark):
		return
	GameServer_.game_container.emit_signal("game_button_click")
