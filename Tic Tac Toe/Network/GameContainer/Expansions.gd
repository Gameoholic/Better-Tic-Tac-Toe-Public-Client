extends Node

enum {O, X, Expansion, Empty}
enum {Top, Bottom, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight}

onready var Game_: Node = get_node("/root/Game")
onready var Tiles_: Node = get_node("/root/Game/Grid/Tiles")
onready var TilesPreview_: Node = get_node("/root/Game/Grid/TilesPreview")
onready var Outline_: Node = get_node("/root/Game/Grid/Outline")
onready var Camera_: Node = get_node("/root/Game/Main/Camera")


#Returns whether the tile exists and is a center
func check_tile_for_center(pos: Vector2) -> bool:
	if (!Game_.game_container.map.has(pos)):
		return false
	if (Game_.game_container.map[pos].is_center_of_local_grid):
		return true
	return false
	
"""	
Returns a Dictionary containing tiles that would be generated around a given center tile.
The keys represent the positions of tiles, the values are the tiles.
This essentially "runs" generate_grid_around_center() without actually generating the grid, and returns the tiles that would have been generated.
"""	
func get_generated_grid_tiles(center: Vector2) -> Dictionary:
	var grid: Dictionary = {}
	
	for i in range(-1 + center.x, 2 + center.x, 1):
		for j in range(-1 + center.y, 2 + center.y, 1):
			var pos = Vector2(i, j)
			if (!Game_.game_container.map.has(pos)):
				var tile: Tile
				#If the tile is in the center of the new grid:
				if (pos == center):
					tile = Tile.new(Empty, true)
				#If it isn't:
				else:
					tile = Tile.new(Empty, false)
				grid[pos] = tile
	return grid

"""
Returns a dictionary where the keys are directions, and the values
are Tile dictionaries of possible grid expansions, where the keys represent the positions of tiles, and the values are the tiles. {Direction0: {(x0,y0):Tile0, (x1,y1):Tile1, ...}, ...}
Takes the position of the expansion tile as a parameter.
"""
func get_possible_expansions(expansion_pos: Vector2) -> Dictionary:
	var possible_expansions = {}
	var adjacent_center_directions: Array = get_adjacent_center_tiles(expansion_pos)
	
	#If the expansion is in the center of a grid:
	if (Game_.game_container.map.has(expansion_pos) and Game_.game_container.map[expansion_pos].is_center_of_local_grid):
		possible_expansions["Center"] = {}
	
	for adjacent_center_direction in adjacent_center_directions:
		var tiles_of_direction: Dictionary = {}
		match adjacent_center_direction:
			"Above":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x, expansion_pos.y + 1))
			"Below":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x, expansion_pos.y - 1))
			"Right":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x - 1, expansion_pos.y))
			"Left":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x + 1, expansion_pos.y))
			"TopLeft":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x + 1, expansion_pos.y + 1))
			"TopRight":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x - 1, expansion_pos.y + 1))
			"BottomLeft":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x + 1, expansion_pos.y - 1))
			"BottomRight":
				tiles_of_direction = get_generated_grid_tiles(Vector2(expansion_pos.x - 1, expansion_pos.y - 1))
		possible_expansions[adjacent_center_direction] = tiles_of_direction
	return possible_expansions

"""
Returns array of directions of adjacent center tiles relative to a given position of a tile (parameter). 
Ex: "TopRight" means the center is in the top-right relative to the given tile.
"""
func get_adjacent_center_tiles(pos: Vector2) -> Array:
	var adjacent_center_tiles = []
	if (check_tile_for_center(Vector2(pos.x, pos.y - 1))):
		adjacent_center_tiles.append("Above")
	if (check_tile_for_center(Vector2(pos.x, pos.y + 1))):
		adjacent_center_tiles.append("Below")
	if (check_tile_for_center(Vector2(pos.x + 1, pos.y))):
		adjacent_center_tiles.append("Right")
	if (check_tile_for_center(Vector2(pos.x - 1, pos.y))):
		adjacent_center_tiles.append("Left")
	if (check_tile_for_center(Vector2(pos.x - 1, pos.y + 1))):
		adjacent_center_tiles.append("BottomLeft")
	if (check_tile_for_center(Vector2(pos.x + 1, pos.y + 1))):
		adjacent_center_tiles.append("BottomRight")
	if (check_tile_for_center(Vector2(pos.x - 1, pos.y - 1))):
		adjacent_center_tiles.append("TopLeft")
	if (check_tile_for_center(Vector2(pos.x + 1, pos.y - 1))):
		adjacent_center_tiles.append("TopRight")
	return adjacent_center_tiles

#Runs when player releases right click on a cell
func place_expansion() -> void:
	Game_.in_expansion_selection = false
	Game_.game_container.place_tile(Game_.origin_expansion_cell, Expansion)
	Game_.game_container.place_tiles(Game_.possible_expansions[Game_.current_expansion_direction])

	for possible_expansion_cell in Game_.possible_expansions[Game_.current_expansion_direction]:
		if (Game_.possible_expansions[Game_.current_expansion_direction][possible_expansion_cell].is_center_of_local_grid):
			Game_.game_container.queued_outline_center_cells.append(possible_expansion_cell)
		
	TilesPreview_.clear()

#Runs when player holds right click on a cell
func preview_expansion_first_time(clicked_cell: Vector2) -> void:
	Game_.in_expansion_selection = true
	Game_.origin_expansion_cell = clicked_cell
	Game_.origin_mouse_coords = get_viewport().get_mouse_position()
	Game_.possible_expansions = get_possible_expansions(Game_.origin_expansion_cell)
	Game_.current_expansion_direction = Game_.possible_expansions.keys()[0]
	#Show preview of expansion:
	TilesPreview_.set_cell(Game_.origin_expansion_cell.x, Game_.origin_expansion_cell.y, Expansion)
	for possible_expansion_pos in Game_.possible_expansions.values()[0]:
		var tile_pos = Vector2(possible_expansion_pos.x, possible_expansion_pos.y)
		TilesPreview_.set_cell(tile_pos.x, tile_pos.y, Empty)

func preview_expansion() -> void:
	var original_mouse_pos: Vector2 = Game_.origin_mouse_coords
	var current_mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var cell_size: Vector2 = Tiles_.cell_size
	var expansion_cell: Vector2 = Tiles_.world_to_map(current_mouse_pos + Camera_.position)
	var expansion_cell_pos = Vector2(int(original_mouse_pos.x / 64) * 64, int(original_mouse_pos.y / 64) * 64)
	var expansion_center_pos = Vector2(expansion_cell_pos.x + cell_size.x / 2, expansion_cell_pos.y + cell_size.y / 2) #Center of expansion cell
	
	var distance: float = current_mouse_pos.distance_to(expansion_center_pos)
	if (distance == 0):
		return
	var leg: float = abs(expansion_center_pos.y - current_mouse_pos.y)
	var angle: float = (asin(leg/distance)) * (180 / PI)
#		print(angle)
	
	var quadrant: int
	var direction: String
	if (current_mouse_pos.x > expansion_center_pos.x and current_mouse_pos.y < expansion_center_pos.y):
		quadrant = 1
		if (angle < 30):
			direction = "Left"
		elif (angle < 60):
			direction = "BottomLeft"
		else:
			direction = "Bottom"
	elif (current_mouse_pos.x < expansion_center_pos.x and current_mouse_pos.y < expansion_center_pos.y):
		quadrant = 2
		if (angle < 30):
			direction = "Right"
		elif (angle < 60):
			direction = "BottomRight"
		else:
			direction = "Bottom"
	elif (current_mouse_pos.x < expansion_center_pos.x and current_mouse_pos.y > expansion_center_pos.y):
		quadrant = 3
		if (angle < 30):
			direction = "Right"
		elif (angle < 60):
			direction = "TopRight"
		else:
			direction = "Top"
	elif (current_mouse_pos.x > expansion_center_pos.x and current_mouse_pos.y > expansion_center_pos.y):
		quadrant = 4
		if (angle < 30):
			direction = "Left"
		elif (angle < 60):
			direction = "TopLeft"
		else:
			direction = "Top"
			
	#Check if player hovers over expansion cell:
	if (current_mouse_pos.x > expansion_cell_pos.x and current_mouse_pos.x < expansion_cell_pos.x + cell_size.x and current_mouse_pos.y > expansion_cell_pos.y and current_mouse_pos.y < expansion_cell_pos.y + cell_size.y):
		direction = "Center"
	
#		print(quadrant)
#		print(direction)
	if (Game_.possible_expansions.has(direction)):
		Game_.current_expansion_direction = direction
	
	#Show preview of expansion:
	if (Game_.possible_expansions.has(direction)):
		TilesPreview_.clear()
		TilesPreview_.set_cell(Game_.origin_expansion_cell.x, Game_.origin_expansion_cell.y, Expansion)
		for possible_expansion_pos in Game_.possible_expansions[direction]:
			var tile_pos = Vector2(possible_expansion_pos.x, possible_expansion_pos.y)
			TilesPreview_.set_cell(tile_pos.x, tile_pos.y, Empty)
	
