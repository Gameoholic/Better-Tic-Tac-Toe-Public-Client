extends TileMap

onready var Game_: Node = get_node("/root/Game")
onready var Camera_: Node = get_node("/root/Game/Main/Camera")

func _ready() -> void:
	pass
	
var camera_dragged = false

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if !event.pressed:
			#If the screen is being dragged, don't treat the click as a tile placement
			if camera_dragged == true:
				camera_dragged = false
			else:
				var clicked_cell: Vector2 = world_to_map(event.position + Camera_.position)
				Game_.emit_signal("cell_clicked", clicked_cell)
		
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			var clicked_cell: Vector2 = world_to_map(event.position + Camera_.position)
			Game_.emit_signal("cell_right_clicked", clicked_cell, false)
			
		if event.button_index == BUTTON_RIGHT and !event.pressed:
			var clicked_cell: Vector2 = world_to_map(event.position + Camera_.position)
			Game_.emit_signal("cell_right_clicked", clicked_cell, true)
