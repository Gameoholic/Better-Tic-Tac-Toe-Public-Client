extends ColorRect

const tutorial_messages := [
	"Welcome to Better Tic Tac Toe!\nIn this game, you and your opponent take turns placing a mark in one of the cells of the grid, similarly to a standard game of Tic Tac Toe. However, as you will see later, there are additional actions you can take on your turn.\nThe most common way to win is to make a continuous line of three cells with your mark, either vertically, horizontally or diagonally.\nThere's a camera! Try moving around.",

	"On the left side of the screen you will see your mark, this time we're X. \nLet's place X in the middle by clicking on the middle cell.", 
	
	"Great! Don't forget to end your turn by clicking the 'End Turn' button.",

	"It's now my turn so I'll place O here. \nI'll now introduce you to a new type of tile you can place, the Expansion tile.\nThe Expansion tile can be placed by either player on their turn. It blocks the cell, and expands the board relative to its location on the 3x3 grid it's on.",

	"Now switch your tile to an Expansion tile. You can do this by pressing the button highlighted on the screen.",

	"Now preview an expansion by holding an empty cell. Release to place it, or drag your finger to the 'Cancel' button to cancel it.",

	"The board has now expanded in the direction relative to where you placed it on the board. Tiles cannot be placed in the same cell as an Expansion tile. Don't forget to end your turn by pressing the 'End Turn' button.",

	"You can place your mark and use an expansion on the same turn, but you CANNOT use an expansion and then place your mark.",

	"You start the game with 2 expansion tiles. You can check how many expansions you have available in the left side of the screen.\nYou may skip your turn to gain an expansion tile. You cannot skip your turn if you have 3 expansion tiles available.",
	
	"I skipped my turn. You can place more than one expansion tile on your turn, provided you have them available. I have given you 3 expansion tiles. Place your mark, and then try using all of them!",
	
	"Those are all the important rules! I'll now go through a few special rules and edge cases.",
	
	"If you place an expansion tile in the middle of a 3x3 grid, it won't expand anywhere, it'll only block the cell it's on.",
	
	"In the case that an expansion tile belongs to two 3x3 grids and can expand in two different direction, you will be able to select which direction to expand in. Try placing an expansion here and drag to see the different directions you can expand in. [TO BE IMPLEMENTED, IGNORE FOR NOW. SORRY]",
	
	"There are no draws in Better Tic Tac Toe. If you block the last cell, you lose. To avoid abusal of this rule, you cannot skip your turn if there is only one cell left in the entire grid.",
	
	"Make sure to keep close attention to your timer. The top one indicates how much time you have left, and the bottom how much your opponent has left. It will only go down when it's your turn, similarly to chess. In a standard game of Better Tic Tac Toe, each player starts with 3 minutes and receives 2 seconds per turn played.",
	
	"And that's it! I've left you the board to experiment with expansions, but you will not be able to place your mark or end your turn. Feel free to leave the tutorial now and start a match."
]
const max_tutorial_progress: int = len(tutorial_messages)

var progress := 1

func set_progress(local_progress: int) -> void:
	progress = local_progress
	$"Control/Label".text = tutorial_messages[progress - 1]
	if (progress == 1):
		$"Control/Back".visible = false
	else:
		$"Control/Back".visible = true
	if (progress == max_tutorial_progress):
		$"Control/Next".visible = false
	else:
		$"Control/Next".visible = true
	get_parent().on_tutorial_progressed(progress)	

func set_next_visible(state: bool) -> void:
	$"Control/Next".visible = state

func _on_Back_button_pressed():
	var label: Label = $"Control/Back/Label"
	label.rect_position.y = 0 + 12
	
func _on_Back_button_released():
	var label: Label = $"Control/Back/Label"
	label.rect_position.y = 0
	set_progress(progress - 1)	

func _on_Back_button_left_area():
	var label: Label = $"Control/Back/Label"
	label.rect_position.y = 0

func _on_Next_button_pressed():
	var label: Label = $"Control/Next/Label"
	label.rect_position.y = 0 + 12

func _on_Next_button_released():
	var label: Label = $"Control/Next/Label"
	label.rect_position.y = 0
	set_progress(progress + 1)
	
func _on_Next_button_left_area():
	var label: Label = $"Control/Next/Label"
	label.rect_position.y = 0

