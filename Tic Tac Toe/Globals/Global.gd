extends Node

func _ready() -> void:
	OS.center_window() 
	process_priority = 10000
	
func _unhandled_input(event):
	if (event is InputEventKey and event.scancode == KEY_F11):
		if event.pressed:
			var is_fullscreen: bool = OS.window_fullscreen
			OS.window_fullscreen = !is_fullscreen
			#Update data.json with F11 preference
			var data_file := File.new()
			data_file.open("user://Data/data.json", File.READ_WRITE)
			var data_file_contents: Dictionary = JSON.parse(data_file.get_as_text()).result
			data_file_contents.f11 = !is_fullscreen
			data_file.store_line(JSON.print(data_file_contents, "\t"))
			data_file.close()

