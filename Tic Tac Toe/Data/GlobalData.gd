extends Node

const version := "0.3.1"
var latest_version := "" #Will be "" unless there's a newer version available
#const connection_ip := "127.0.0.1"
const connection_ip := "78.47.101.58"
const connection_port := 1918
var displayname: String
var account_already_logged_on_time: int #If its value isn't 0, then the account is logged into from another device. Stores time when it logged in.
var gameserver_port: int
var gameserver_name: String
var inappropriate_words: Array
#LoginScreen.gd authentication:
var username: String
var auth_token: String
#Preferences:
var game_mode_pref: String
#Testing:
var test_music: bool

func _ready() -> void:
	#Check if required files exist, if not, create them:
	#Data dir:
	var directory = Directory.new()
	if (!directory.dir_exists("user://Data")):
		directory.make_dir("user://Data")
	#Data file:
	#Create file if it doesn't exist:
	var data_file := File.new()
	if (!data_file.file_exists("user://Data/data.json")):
		data_file.open("user://Data/data.json", File.WRITE)
		data_file.store_line(JSON.print({}, "\t"))
		data_file.close()
	#Read file contents:
	data_file.open("user://Data/data.json", File.READ)
	var data_file_contents: Dictionary = JSON.parse(data_file.get_as_text()).result
	data_file.close()
	#Modify file contents:
	data_file.open("user://Data/data.json", File.WRITE) #This removes all previous file data	
	#Create arguments with default parameters if they don't exist:
	if (!data_file_contents.has("f11")):
		data_file_contents["f11"] = true
	if (!data_file_contents.has("mode")):
		data_file_contents["mode"] = "classic"
	if (!data_file_contents.has("test_music")):
		data_file_contents["test_music"] = false
	#Remove old, unneeded arguments created by old versions:
	data_file_contents.erase("version")
	data_file_contents.erase("connection_ip")
	data_file_contents.erase("connection_port")	
	#Store changes if there are any:
	data_file.store_line(JSON.print(data_file_contents, "\t"))
	data_file.close()
	#Login Data file:
	#Create file if it doesn't exist:
	var login_data_file := File.new()	
	if (!login_data_file.file_exists("user://Data/login_data.json")):
		login_data_file.open("user://Data/login_data.json", File.WRITE)
		login_data_file.store_line(JSON.print({}, "\t"))
		login_data_file.close()
	#Read file contents:
	login_data_file.open("user://Data/login_data.json", File.READ)
	var login_data_file_contents: Dictionary = JSON.parse(login_data_file.get_as_text()).result
	login_data_file.close()
	#Modify file contents:
	login_data_file.open("user://Data/login_data.json", File.WRITE) #This removes all previous file data	
	#Create arguments with default parameters if they don't exist:
	if (!login_data_file_contents.has("username")):
		login_data_file_contents["username"] = ""
	if (!login_data_file_contents.has("auth_token")):
		login_data_file_contents["auth_token"] = ""
	#Store changes if there are any:
	login_data_file.store_line(JSON.print(login_data_file_contents, "\t"))
	login_data_file.close()
	#Read data from files:
	
	#Data file:
	data_file.open("user://Data/data.json", File.READ)
	data_file_contents = JSON.parse(data_file.get_as_text()).result
	OS.window_fullscreen = data_file_contents["f11"]
	game_mode_pref = data_file_contents["mode"]
	test_music = data_file_contents["test_music"]
	data_file.close()
	
	#Login data file:
	login_data_file.open("user://Data/login_data.json", File.READ)
	login_data_file_contents = JSON.parse(login_data_file.get_as_text()).result
	username = login_data_file_contents.username
	auth_token = login_data_file_contents.auth_token
	login_data_file.close()
	
	#Read inappropriate words file:
	var inappropriate_words_file := File.new()
	inappropriate_words_file.open("res://Data/inappropriate_words.txt", File.READ)
	while (!inappropriate_words_file.eof_reached()):
		inappropriate_words.append(inappropriate_words_file.get_line())
	inappropriate_words_file.close()
