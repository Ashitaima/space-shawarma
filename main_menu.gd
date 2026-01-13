extends Control

func _on_btn_Start_pressed():
	# Завантажує сцену з грою
	get_tree().change_scene_to_file("res://game_level.tscn")

func _on_btn_Shop_pressed():
	get_tree().change_scene_to_file("res://Shop.tscn")

func _on_btn_Settings_pressed():
	print("Відкриваємо налаштування") 

func _on_btn_Exit_pressed():
	get_tree().quit()
