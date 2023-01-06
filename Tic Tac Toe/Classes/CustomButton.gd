extends TextureButton
class_name CustomButton

export (bool) var enabled := true #Whether the button can be pressed. If it has the highest priority, it will ignore other buttons.
export (int) var priority = 5 #The button with the highest priority will be clicked
export (String) var sound = "click" #The sound that will be played upon button release

signal button_pressed
signal button_released
signal button_left_area
signal mouse_hover
signal mouse_stop_hover

var normal_texture: Texture
var pressed_texture: Texture

func _ready() -> void:
	disabled = true
	normal_texture = texture_normal
	pressed_texture = texture_pressed	
	add_to_group("CUSTOM_BUTTONS")

func on_pressed() -> void:
	texture_normal = pressed_texture
	CustomButtons.track_button_for_leave_area(self)
	emit_signal("button_pressed")

func on_released() -> void:
	texture_normal = normal_texture
	CustomButtons.untrack_button_for_leave_area(self)
	if (enabled):
		AudioPlayer.play_sound(sound)
	emit_signal("button_released")

func on_left_area() -> void:
	texture_normal = normal_texture
	emit_signal("button_left_area")

func on_mouse_hover() -> void:
	CustomButtons.track_button_for_mouse_stop_hover(self)
	emit_signal("mouse_hover")

func on_mouse_stop_hover() -> void:
	emit_signal("mouse_stop_hover")

func set_texture(texture_type: String, texture: Texture) -> void:
	match texture_type:
		"normal":
			normal_texture = texture
			texture_normal = normal_texture
		"pressed":
			pressed_texture = texture
			texture_pressed = pressed_texture
