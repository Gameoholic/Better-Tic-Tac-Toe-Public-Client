extends Camera2D

var events = {}

onready var Tiles_: Node = get_node("/root/Game/Grid/Tiles")

func _ready() -> void:
	position = Vector2(-350, -350)


func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)
	if event is InputEventScreenDrag:
		Tiles_.camera_dragged = true
		events[event.index] = event
		if events.size() == 1:
			position += event.relative.rotated(rotation) * zoom.x * -1
			
			
