extends Control

@onready var start_button = $StartButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	# УВАГА: Тут має бути точна назва твого файлу з рівнем!
	# Судячи з твого скріншоту, він називається "game_level.tscn"
	get_tree().change_scene_to_file("res://game_level.tscn")
