extends Node

func _ready() -> void:
	OS.center_window() 
	process_priority = 10000
	
func _unhandled_input(event):
	if (event is InputEventKey and event.scancode == KEY_F11):
		if event.pressed:
			OS.window_fullscreen = !OS.window_fullscreen

