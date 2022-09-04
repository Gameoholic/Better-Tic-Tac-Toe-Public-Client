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
			update_data_file("f11", !is_fullscreen)

func update_data_file(key: String, value) -> void:
	var data_file := File.new()
	data_file.open("user://Data/data.json", File.READ)
	var data_file_contents: Dictionary = JSON.parse(data_file.get_as_text()).result
	data_file_contents[key] = value
	data_file.close()
	data_file.open("user://Data/data.json", File.WRITE)
	data_file.store_line(JSON.print(data_file_contents, "\t"))
	data_file.close()
