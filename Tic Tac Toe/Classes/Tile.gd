extends Node
class_name Tile

enum {O, X, Expansion, Empty}

var id: int
var is_center_of_local_grid: bool


func _init(param_id:int = Empty, param_center:bool = false):
	id = param_id
	is_center_of_local_grid = param_center

func to_dictionary() -> Dictionary:
	return {"id": id, "is_center_of_local_grid": is_center_of_local_grid}

static func from_dictionary(args: Dictionary) -> Tile:
	return load("res://Classes/Tile.gd").new(args.id, args.is_center_of_local_grid)

#todo: don't load every time lol. see message posted by me in godot discord
