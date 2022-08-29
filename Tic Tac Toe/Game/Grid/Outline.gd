extends Node2D

onready var Tiles_: Node = get_node("/root/Game/Grid/Tiles")

var cell_size: Vector2
var all_outlines: Array = [] #Array containing dictionaries that describe line properties

var outline_color: Color = Color.black
var outline_width: float = 3.0

func _ready():
	cell_size = Tiles_.cell_size
	add_center_cell(Vector2(0, 0))

func add_center_cell(center_cell: Vector2) -> void:
	#Add outline to outlines list:
	var center_coords = Tiles_.map_to_world(center_cell)
	#Right Outline:
	all_outlines.append({"from": Vector2(center_coords.x + cell_size.x * 2, center_coords.y - cell_size.y), "to": Vector2(center_coords.x + cell_size.x * 2, center_coords.y + cell_size.y * 2)})
	#Left Outline:
	all_outlines.append({"from": Vector2(center_coords.x - cell_size.x, center_coords.y - cell_size.y), "to": Vector2(center_coords.x - cell_size.x, center_coords.y + cell_size.y * 2)})
	#Top Outline:
	all_outlines.append({"from": Vector2(center_coords.x - cell_size.x, center_coords.y - cell_size.y), "to": Vector2(center_coords.x + cell_size.x * 2, center_coords.y - cell_size.y)})
	#Bottom Outline:
	all_outlines.append({"from": Vector2(center_coords.x - cell_size.x, center_coords.y + cell_size.y * 2), "to": Vector2(center_coords.x + cell_size.x * 2, center_coords.y + cell_size.y * 2)})

func _draw():
	#Redraw all outlines:
	for outline in all_outlines:
		draw_line(outline["from"], outline["to"], outline_color, outline_width)
	
