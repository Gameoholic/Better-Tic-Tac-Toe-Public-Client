extends Node

var enabled := false
var tracked_buttons_for_leave_area := []
var tracked_buttons_for_mouse_stop_hover := []
var tracked_buttons_for_mouse_down := []

func _process(delta: float) -> void:
	if (!enabled):
		return
	track_buttons_for_leave_area()
	track_buttons_for_mouse_hover()
	track_buttons_for_mouse_stop_hover()

func _input(event: InputEvent) -> void:
	if (!enabled):
		return
	track_buttons_for_input(event)

func track_buttons_for_leave_area() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#For each button, check if the mouse is in its area
	for tracked_button in tracked_buttons_for_leave_area:
		var button_pos: Vector2 = tracked_button.get_global_transform_with_canvas().get_origin()
		var node_size = tracked_button.rect_size * tracked_button.get_global_transform_with_canvas().get_scale()
		#Check if mouse is outside of tracked button's area
		if (not (mouse_pos.x >= button_pos.x and mouse_pos.x <= button_pos.x + node_size.x and mouse_pos.y >= button_pos.y && mouse_pos.y < button_pos.y + node_size.y)):
			tracked_button.on_left_area()
			tracked_buttons_for_leave_area.erase(tracked_button)

func track_buttons_for_mouse_hover() -> void:
	var selected_button: CustomButton	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#For each button, check if the mouse is in its area
	
	#Property related:
	var max_priority := 0
	for custom_button in get_tree().get_nodes_in_group("CUSTOM_BUTTONS"):
		if (tracked_buttons_for_mouse_stop_hover.has(custom_button)):
			return
		var button_pos: Vector2 = custom_button.get_global_transform_with_canvas().get_origin()
		var node_size = custom_button.rect_size * custom_button.get_global_transform_with_canvas().get_scale()
		#Check if mouse is in tracked button's area
		if (mouse_pos.x >= button_pos.x and mouse_pos.x <= button_pos.x + node_size.x and mouse_pos.y >= button_pos.y && mouse_pos.y < button_pos.y + node_size.y and custom_button.visible):
			if (custom_button.priority > max_priority):
				max_priority = custom_button.priority
				selected_button = custom_button
	#If a button was found:
	if (selected_button != null and selected_button.enabled):
		selected_button.on_mouse_hover()

func track_buttons_for_mouse_stop_hover() -> void:
	var selected_button: CustomButton		
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#For each button, check if the mouse is in its area
	
	#Property related:
	var max_priority := 0
	for tracked_button in tracked_buttons_for_mouse_stop_hover:
		var button_pos: Vector2 = tracked_button.get_global_transform_with_canvas().get_origin()
		var node_size = tracked_button.rect_size * tracked_button.get_global_transform_with_canvas().get_scale()
		#Check if mouse is outside of tracked button's area
		if (!(mouse_pos.x >= button_pos.x and mouse_pos.x <= button_pos.x + node_size.x and mouse_pos.y >= button_pos.y && mouse_pos.y < button_pos.y + node_size.y) and tracked_button.visible):
			if (tracked_button.priority > max_priority):
				max_priority = tracked_button.priority
				selected_button = tracked_button
	#If a button was found:
	if (selected_button != null and selected_button.enabled):
		tracked_buttons_for_mouse_stop_hover.erase(selected_button)
		tracked_buttons_for_mouse_down.erase(selected_button)
		selected_button.on_mouse_stop_hover()

func track_buttons_for_input(event: InputEvent) -> void:
	var selected_button: CustomButton
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#For each button, check if the mouse is in its area
	
	#Property related:
	var max_priority := 0
	for custom_button in get_tree().get_nodes_in_group("CUSTOM_BUTTONS"):
		#Position related:
		var button_pos: Vector2 = custom_button.get_global_transform_with_canvas().get_origin()
		var node_size = custom_button.rect_size * custom_button.get_global_transform_with_canvas().get_scale()
		#Position check:
		if (mouse_pos.x >= button_pos.x and mouse_pos.x <= button_pos.x + node_size.x and mouse_pos.y >= button_pos.y && mouse_pos.y < button_pos.y + node_size.y and custom_button.visible):
			if (custom_button.priority > max_priority):
				max_priority = custom_button.priority
				selected_button = custom_button
	
	#If a button was found:
	if (selected_button != null and selected_button.enabled):
		if (event is InputEventScreenTouch):
			if (event.pressed):
				tracked_buttons_for_mouse_down.append(selected_button)
				selected_button.on_pressed()
			if (!event.pressed and tracked_buttons_for_mouse_down.has(selected_button)):
				tracked_buttons_for_mouse_down.erase(selected_button)
				selected_button.on_released()

func track_button_for_leave_area(button: CustomButton) -> void:
	tracked_buttons_for_leave_area.append(button)
func untrack_button_for_leave_area(button: CustomButton) -> void:
	tracked_buttons_for_leave_area.erase(button)
func track_button_for_mouse_stop_hover(button: CustomButton) -> void:
	tracked_buttons_for_mouse_stop_hover.append(button)

func enable() -> void:
	enabled = true
func disable() -> void:
	enabled = false
	tracked_buttons_for_leave_area.clear()
	tracked_buttons_for_mouse_stop_hover.clear()
func set_enabled(status: bool) -> void:
	enabled = status
	if (!enabled):
		tracked_buttons_for_leave_area.clear()
		tracked_buttons_for_mouse_stop_hover.clear()

#Recursive method caller that sets the status for all buttons in the tree individually. status is whether enabled
func set_enabled_individually_for_all_buttons(status: int) -> void:
	set_buttons_enabled_recursive(get_tree().get_root(), status)
	
func set_buttons_enabled_recursive(node: Node, status: int) -> void:
	if (node is CustomButton):
		node.enabled = status

	for child in node.get_children():
		set_buttons_enabled_recursive(child, status)

