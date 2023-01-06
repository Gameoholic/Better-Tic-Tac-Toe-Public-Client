extends Node

signal scene_finished_changing

var MainMenu_path := "res://Menus/MainMenu/MainMenu.tscn"
var BootScreen_path := "res://Menus/BootScreen/BootScreen.tscn"
var LoginScreen_path := "res://Menus/LoginScreen.tscn"
var Game_path := "res://Game/Game.tscn"

var BootScreen: Node setget ,get_boot_screen
var LoginScreen: Node setget ,get_login_screen
var Game: Node setget ,get_game
var MainMenu: Node setget ,get_main_menu
var current_scene: Node setget ,get_current_scene

var transferred_scene_data: Dictionary = {"first_run": true} #has element first_run during first run of default scene
var changing_scenes := false
var fade_in: bool


	
func change_scene(path: String, scene_data: Dictionary = {}, local_fade_in: bool = true) -> void:
	CustomButtons.disable()
	changing_scenes = true
	fade_in = local_fade_in
	transferred_scene_data = scene_data
	current_scene = get_tree().current_scene
	
	#Fade out anim:
	var transition_overlay := ColorRect.new()
	var transition_tween := Tween.new()
	if (current_scene.name == "Game"):
		current_scene.get_node("GUI").add_child(transition_overlay)
	elif (current_scene.name == "LoginScreen"):
		current_scene.get_node("CanvasLayer").add_child(transition_overlay)
	elif (current_scene.name == "MainMenu"):
		current_scene.get_node("CanvasLayer2").add_child(transition_overlay)
	else:	
		current_scene.add_child(transition_overlay)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP	
	transition_overlay.rect_size = OS.get_real_window_size()
	transition_overlay.color = Color(0, 0, 0, 0)
	current_scene.add_child(transition_tween)
	transition_tween.interpolate_property(transition_overlay, "color", transition_overlay.color, Color(0, 0, 0, 1), 0.5, transition_tween.TRANS_CUBIC, transition_tween.EASE_OUT)
	transition_tween.start()
	yield(get_tree().create_timer(0.5), "timeout")
	
	current_scene.clean_up_scene()
	if (!current_scene.cleaned_up):
		yield(current_scene, "scene_cleaned_up")
	get_tree().change_scene(path)

func on_scene_loaded() -> void: #Called by new scene when it is ready
	if (!changing_scenes):
		return
	current_scene = get_tree().current_scene
	
	#Fade in anim:
	if (fade_in):
		var transition_overlay := ColorRect.new()
		var transition_tween := Tween.new()
		if (current_scene.name == "Game"):
			current_scene.get_node("GUI").add_child(transition_overlay)
		elif (current_scene.name == "LoginScreen"):
			current_scene.get_node("CanvasLayer").add_child(transition_overlay)
		elif (current_scene.name == "MainMenu"):
			current_scene.get_node("CanvasLayer2").add_child(transition_overlay)
		else:	
			current_scene.add_child(transition_overlay)
		transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_overlay.rect_size = OS.get_real_window_size()
		transition_overlay.color = Color(0, 0, 0, 1)
		current_scene.add_child(transition_tween)
		transition_tween.interpolate_property(transition_overlay, "color", transition_overlay.color, Color(0, 0, 0, 0), 0.5, transition_tween.TRANS_CUBIC, transition_tween.EASE_IN)
		transition_tween.start()
	changing_scenes = false	

func get_current_scene() -> Node:
	return get_tree().current_scene
	
func has_login_screen() -> bool:
	return get_tree().current_scene.name == "LoginScreen"

func get_login_screen() -> Node:
	if (!has_login_screen()):
		Logger.error("Couldn't return LoginScreen node, current scene is " + get_tree().current_scene.name + ".", Logger.ERROR)
		return null
	return get_tree().current_scene

func has_game() -> bool:
	return get_tree().current_scene.name == "Game"

func get_game() -> Node:
	if (!has_game()):
		Logger.error("Couldn't return Game node, current scene is " + get_tree().current_scene.name + ".", Logger.ERROR)
		return null
	return get_tree().current_scene

func has_main_menu() -> bool:
	return get_tree().current_scene.name == "MainMenu"

func get_main_menu() -> Node:
	if (!has_main_menu()):
		Logger.error("Couldn't return MainMenu node, current scene is " + get_tree().current_scene.name + ".", Logger.ERROR)
		return null
	return get_tree().current_scene

func has_boot_screen() -> bool:
	return get_tree().current_scene.name == "BootScreen"
	
func get_boot_screen() -> Node:
	if (!has_boot_screen()):
		Logger.error("Couldn't return BootScreen node, current scene is " + get_tree().current_scene.name + ".", Logger.ERROR)
		return null
	return get_tree().current_scene
