extends LineEdit

func _input(event: InputEvent):
	if (has_focus() and event is InputEventMouseButton and !get_global_rect().has_point(event.position)):
		release_focus()


func _on_Password_text_changed(new_text):
	#Input validation:
	var allowed_characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~`!@#$%^&*()_-+=|?/><.,\\"
	for character in text:
		if (!character in allowed_characters):
			var cached_caret_pos := caret_position
			var text_pool_array := text.split(character, true, 1)
			text = text_pool_array[0] + text_pool_array[1]
			caret_position = cached_caret_pos - 1
	$"%LoginError".visible = false
	
