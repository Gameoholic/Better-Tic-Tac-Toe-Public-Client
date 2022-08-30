extends Node

var version := "0.1.0"
var connection_ip: String
var connection_port: int
var displayname: String
var gameserver_port: int
var inappropriate_words: Array

func _ready() -> void:
	#Check if required files exist, if not, create them:
	var contents := {"version": version}
	
	var directory = Directory.new()
	if (!directory.dir_exists("user//Data")):
		directory.make_dir("user://Data")
	
	var data_file := File.new()
	if (!data_file.file_exists("user://Data/data.json")):
		data_file.open("user://Data/data.json", File.WRITE)
		contents.connection_ip = "157.90.151.85"
		contents.connection_port = "1911"
		data_file.store_line(JSON.print(contents, "\t"))
		data_file.close()
	
	var login_data_file := File.new()
	if (!login_data_file.file_exists("user://Data/login_data.json")):
		login_data_file.open("user://Data/login_data.json", File.WRITE)
		contents = {"username": "", "auth_token": ""}
		login_data_file.store_line(JSON.print(contents, "\t"))
		login_data_file.close()
	
	#Read data from files:
	data_file.open("user://Data/data.json", File.READ)
	var file_json := JSON.parse(data_file.get_as_text())
	#version is viewonly, shouldn't be changed.
	connection_ip = file_json.result.connection_ip
#	connection_ip = "127.0.0.1"
	connection_port = int(file_json.result.connection_port)
	data_file.close()
	
	#Read inappropriate words file:
	var inappropriate_words_file := File.new()
	inappropriate_words_file.open("res://Data/inappropriate_words.txt", File.READ)
	while (!inappropriate_words_file.eof_reached()):
		inappropriate_words.append(inappropriate_words_file.get_line())
	inappropriate_words_file.close()
