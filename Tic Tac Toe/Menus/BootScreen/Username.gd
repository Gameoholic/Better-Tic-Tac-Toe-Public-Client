extends LineEdit

var boot_screen: Node

func _ready() -> void:
	boot_screen = Scenes.BootScreen

func _input(event: InputEvent):
	if (has_focus() and event is InputEventMouseButton and !get_global_rect().has_point(event.position)):
		release_focus()

func _on_LineEdit_text_changed(new_text: String):
	#Input validation:
	var allowed_characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for character in text:
		if (!character in allowed_characters):
			var cached_caret_pos := caret_position
			var text_pool_array := text.split(character, true, 1)
			text = text_pool_array[0] + text_pool_array[1]
			caret_position = cached_caret_pos - 1
	$"%LoginError".visible = false
	if (boot_screen.phase == boot_screen.PhaseType.ACCOUNT_LOGGING_IN_INPUT):
		return
	$"TextContainer/Warning".visible = true
	$"TextContainer/HBoxContainer/Proceed".visible = true
	$"%PlayedBefore".visible = false
	$"%Error".visible = false
	get_parent().text = "Welcome to Better Tic Tac Toe!\nPlease pick a username for yourself."
	boot_screen.username_confirmed = false
		
	if (text == ""):
		$"%PlayedBefore".visible = true
		$"TextContainer/Warning".visible = false
		$"TextContainer/HBoxContainer/Proceed".visible = false
		$"TextContainer/Error".visible = false
