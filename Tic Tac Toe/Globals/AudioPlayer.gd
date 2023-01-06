extends Node

#Preload all sounds:
const s_click = preload("res://Assets/Sounds/click.wav")
const s_match_found = preload("res://Assets/Sounds/match_found.wav")
const s_expansion = preload("res://Assets/Sounds/expansion.wav")
const s_your_turn = preload("res://Assets/Sounds/your_turn.wav")
const s_end_turn = preload("res://Assets/Sounds/end_turn.wav")
const s_skip_turn = preload("res://Assets/Sounds/skip_turn.wav")
const s_win = preload("res://Assets/Sounds/win.wav")
const s_lose = preload("res://Assets/Sounds/lose.wav")
const s_place1 = preload("res://Assets/Sounds/place1.wav")
const s_place2 = preload("res://Assets/Sounds/place2.wav")
const s_place3 = preload("res://Assets/Sounds/place3.wav")
const s_boot = preload("res://Assets/Sounds/boot.wav")
const s_pencil_stroke = preload("res://Assets/Sounds/pencil_stroke.wav")
const s_paper_tear = preload("res://Assets/Sounds/paper_tear.wav")

const sound_map := {
	"click": s_click,
	"match_found": s_match_found,
	"expansion": s_expansion,
	"your_turn": s_your_turn,
	"end_turn": s_end_turn,
	"skip_turn": s_skip_turn,
	"win": s_win,
	"lose": s_lose,
	"boot": s_boot,
	"pencil_stroke": s_pencil_stroke,
	"paper_tear": s_paper_tear,
	"place": [s_place1, s_place2, s_place3],
	"error": s_expansion
}


func _ready() -> void:
	randomize()

#Plays sound and returns audio stream player node name. If the sound has variants and the variant index is not specified, will play a random one.
func play_sound(sound_name: String, variant_index: int = -1) -> String:
	var audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	var random_number := randi()
	audio_stream_player.name = "audio_" + sound_name + str(random_number)
	#return ""
	if (sound_name in sound_map):
		if (typeof(sound_map[sound_name]) == TYPE_ARRAY):
			if (variant_index >= 0 and variant_index < len(sound_map[sound_name])):
				audio_stream_player.stream = sound_map[sound_name][variant_index]
			else:
				audio_stream_player.stream = sound_map[sound_name][randi() % len(sound_map[sound_name])]		
		else:
			audio_stream_player.stream = sound_map[sound_name]
		audio_stream_player.play()
		audio_stream_player.connect("finished", audio_stream_player, "queue_free")
	else:
		Logger.error("Couldn't play sound '" + sound_name + "'.", Logger.ALERT)
		audio_stream_player.queue_free()
		return ""
	return audio_stream_player.name
	
