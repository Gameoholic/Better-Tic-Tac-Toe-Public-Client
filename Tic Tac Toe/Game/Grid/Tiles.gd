extends TileMap

onready var CameraNode: Node = Scenes.Game.get_node("Main/Camera")

var camera_dragged = false

func _unhandled_input(event):
	if (event is InputEventScreenTouch):
		#If the screen is being dragged, don't treat the click as a tile placement
		if (!event.pressed and camera_dragged == true):
			camera_dragged = false
		else:
			var clicked_cell: Vector2 = world_to_map(event.position + CameraNode.position)				
			match Scenes.Game.cell_selection_mode:
				"tile":
					if (!event.pressed):
						Scenes.Game.emit_signal("cell_clicked", clicked_cell)
				"expansion":
					if (event.pressed):
						Scenes.Game.emit_signal("cell_right_clicked", clicked_cell, false)
					if (!event.pressed):
						Scenes.Game.emit_signal("cell_right_clicked", clicked_cell, true)
		
	if (event is InputEventMouseButton):
		if (event.button_index == BUTTON_RIGHT):
			var clicked_cell: Vector2 = world_to_map(event.position + CameraNode.position)
			if (event.pressed):
				Scenes.Game.emit_signal("cell_right_clicked", clicked_cell, false)
			if (!event.pressed):
				Scenes.Game.emit_signal("cell_right_clicked", clicked_cell, true)
