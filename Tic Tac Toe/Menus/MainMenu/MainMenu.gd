extends Control

var menu_origin_size: Vector2
#onready var tween: Tween = $Tween
onready var bottom_bar_outline := $"CanvasLayer/BottomBar/Background/Outline"
#onready var bottom_bar_title:= $"CanvasLayer/BottomBar/Background/Title"

func _ready() -> void:
	menu_origin_size = get_viewport_rect().size
	$"PlayMenu/VBoxContainer/Version".text = "v" + GlobalData.version
	$"PlayMenu/VBoxContainer/Username".text = GlobalData.displayname
	$"PlayMenu/VBoxContainer/ServerDetails".text = "Server: " + str(GlobalData.gameserver_port)

#func move_to_menu(menu: String):
#	match menu:
#		"stats_menu":
#			#Camera:
#			tween.interpolate_property($Camera, "offset", $Camera.offset, Vector2(-menu_origin_size.x, 0), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#			#Outline:
#			tween.interpolate_property(bottom_bar_outline, "rect_position", bottom_bar_outline.rect_position, Vector2(150, bottom_bar_outline.rect_position.y), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#			#Title:
#			bottom_bar_title.rect_position = Vector2(125, bottom_bar_title.rect_position.y)
#			bottom_bar_title.text = "Stats"
#			tween.interpolate_property(bottom_bar_title, "modulate:a", 0, 1, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#		"customize_menu":
#			#Camera:
#			tween.interpolate_property($Camera, "offset", $Camera.offset, Vector2(menu_origin_size.x, 0), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#			#Outline:
#			tween.interpolate_property(bottom_bar_outline, "rect_position", bottom_bar_outline.rect_position, Vector2(450, bottom_bar_outline.rect_position.y), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#			#Title:
#			bottom_bar_title.rect_position = Vector2(425, bottom_bar_title.rect_position.y)
#			bottom_bar_title.text = "Customize"
#			tween.interpolate_property(bottom_bar_title, "modulate:a", 0, 1, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#		"play_menu":
#			#Camera:
#			tween.interpolate_property($Camera, "offset", $Camera.offset, Vector2(0, 0), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#			#Outline:
#			tween.interpolate_property(bottom_bar_outline, "rect_position", bottom_bar_outline.rect_position, Vector2(300, bottom_bar_outline.rect_position.y), 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#			#Title:
#			bottom_bar_title.rect_position = Vector2(275, bottom_bar_title.rect_position.y)
#			bottom_bar_title.text = "Play"
#			tween.interpolate_property(bottom_bar_title, "modulate:a", 0, 1, 0.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
#	tween.start()
	


#func _on_Customize_pressed() -> void:
#	move_to_menu("customize_menu")
#
#
#func _on_Play_pressed() -> void:
#	move_to_menu("play_menu")
#
#
#func _on_Stats_pressed() -> void:
#	move_to_menu("stats_menu")
	
	

#updateon resize()

#Called when a game is found
func on_game_found() -> void:
	$"PlayMenu/LookingForGame/Label".text = "Game Found!"
	$"PlayMenu/MiddleButtons/HBoxContainer/Play/Label".text = "Loading..."
	$"PlayMenu/MiddleButtons/HBoxContainer/Play".disabled = true
	$"PlayMenu/MiddleButtons/HBoxContainer/Play".texture_disabled = load("res://Assets/menu_button_gray_pressed.png")
