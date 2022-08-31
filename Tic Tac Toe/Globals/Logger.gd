extends Node

enum {Notice, Warning, Alert, Error} #Severities

var lines := []

func _ready() -> void:
	#Rename latest.log to one with a date
	var directory = Directory.new()
	var log_file := File.new()
	if (log_file.file_exists("user://logs/latest.log")):
		log_file.open("user://logs/latest.log", File.READ)
		var file_date: String = log_file.get_as_text().substr(22, 19)
		log_file.close()
		directory.rename("user://logs/latest.log", "user://logs/" + file_date + ".log")
	
	#Create new log file latest.log:
	log_file.open("user://logs/latest.log", File.WRITE)
	log_file.close()
	Logger.log("Date: " + get_date_string())
	Logger.log("Game started on version " + GlobalData.version + ".")
	
	#Start logger timer:
	var logger_timer := Timer.new()
	add_child(logger_timer)
	logger_timer.connect("timeout", self, "_on_Logger_Timer_timeout")
	logger_timer.set_wait_time(1.0)
	logger_timer.set_one_shot(false)
	logger_timer.start()

func _on_Logger_Timer_timeout():
	var log_file := File.new()
	log_file.open("user://logs/latest.log", File.READ_WRITE)
	while (!lines.empty()):
		log_file.seek_end()
		log_file.store_line(lines.pop_front())
	log_file.close()
	

func log(msg: String) -> void:
	var time := OS.get_time()
	var prefix := "[" + get_time_string() + "] LOG: "
	lines.append(prefix + msg)

func error(msg: String, severity: int) -> void:
	var severity_string: String
	match severity:
		Notice: 
			severity_string = "Notice"
		Warning:
			severity_string = "Warning"
		Alert:
			severity_string = "Alert"
		Error:
			severity_string = "Error"
	var prefix := "[" + get_time_string() + "] " + severity_string + ": "
	lines.append(prefix + msg)
	
func get_time_string() -> String:
	var hour_value: int = OS.get_time().hour
	var minute_value: int = OS.get_time().minute
	var second_value: int = OS.get_time().second
	var hour: String = str(hour_value)
	var minute: String = str(minute_value)
	var second: String = str(second_value)	
	if (hour_value < 10):
		hour.insert(0, "0")
	if (minute_value < 10):
		minute = minute.insert(0, "0")
	if (second_value < 10):
		second = second.insert(0, "0")
	return hour + ":" + minute + ":" + second

func get_date_string() -> String:
	var year_value: int = OS.get_date().year
	var month_value: int = OS.get_date().month
	var day_value: int = OS.get_date().day
	var year: String = str(year_value)
	var month: String = str(month_value)
	var day: String = str(day_value)
	if (month_value < 10):
		month = month.insert(0, "0")
	if (day_value < 10):
		day = day.insert(0, "0")
	return year + "-" + month + "-" + day + "_" + get_time_string().replace(":", ".")
