extends Camera2D

var events := {}

onready var Tiles: Node = Scenes.Game.get_node("Main/Camera/Grid/Tiles")
onready var Game: Node = Scenes.Game

var camera_speed_threshold := 50000

func _ready() -> void:
	position = Vector2(-350, -350)

func _unhandled_input(event):
	if (event is InputEventScreenTouch):
		if (event.pressed):
			events[event.index] = event
		else:
			events.erase(event.index)
	if (event is InputEventScreenDrag):
		#Should only drag camera if not clicking cells, or if pass camera speed threshold
		var cell_position = Tiles.world_to_map(event.position + position)
		var cell_exists: bool = Tiles.get_cell(cell_position.x, cell_position.y) != -1
		if ((event.speed.length_squared() > camera_speed_threshold || !cell_exists) && !Game.in_expansion_selection):
			Tiles.camera_dragged = true
			events[event.index] = event
			if (events.size() == 1):
				position += event.relative.rotated(rotation) * zoom.x * -1
			
			
