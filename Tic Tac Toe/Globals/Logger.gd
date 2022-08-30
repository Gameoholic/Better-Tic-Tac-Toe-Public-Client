extends Node

enum {Notice, Warning, Alert, Error} #Severities

var lines := []

func _ready() -> void:
	#Start logger timer:
	var logger_timer := Timer.new()
	add_child(logger_timer)
	logger_timer.connect("timeout", self, "_on_Logger_Timer_timeout")
	logger_timer.set_wait_time(1.0)
	logger_timer.set_one_shot(false)
	logger_timer.start()

func _on_Logger_Timer_timeout():
	var log_file := File.new()
	log_file.open("user://logs/godot.log", File.READ_WRITE)
	log_file.seek_end()
	while (!lines.empty()):
		log_file.store_line(lines.pop_front())
	log_file.close()

func log(msg: String) -> void:
	var time := OS.get_time()
	var prefix := "[" + str(time.hour) + ":" + str(time.minute) + ":" + str(time.second) + "] LOG: "
	lines.append(prefix + msg)


func error(msg: String, severity: int) -> void:
	var time := OS.get_time()
	var prefix := "[" + str(time.hour) + ":" + str(time.minute) + ":" + str(time.second) + "] ERROR: "
	lines.append(prefix + msg)
	
