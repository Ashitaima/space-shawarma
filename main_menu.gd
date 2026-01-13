extends Control

func _on_btn_Start_pressed():
	# Завантажує сцену з грою
	get_tree().change_scene_to_file("res://game_level.tscn")

func _on_btn_Shop_pressed():
	get_tree().change_scene_to_file("res://Shop.tscn")

func _on_btn_Settings_pressed():
	$Settings_Panel.visible = true
	
func _on_btn_Exit_pressed():
	get_tree().quit()
	

var master_bus_index = AudioServer.get_bus_index("Master")

func _ready():
	$Settings_Panel.visible = false
	get_tree().paused = false
	
	$Settings_Panel/VBoxContainer/Volume_Slider.value = GlobalSettings.current_volume_db_index
	$Settings_Panel/VBoxContainer/Fullscreen_Checkbox.button_pressed = GlobalSettings.is_fullscreen


# --- Кнопка "Назад" в налаштуваннях ---
func _on_btn_back_pressed():
	$Settings_Panel.visible = false

# --- Логіка ГУЧНОСТІ ---
func _on_volume_slider_value_changed(value):
	# Передаємо зміну в глобальний скрипт
	GlobalSettings.update_volume(value)

# --- Логіка ПОВНИЙ ЕКРАН ---
# Коли клацаємо чекбокс
func _on_fullscreen_check_toggled(toggled_on):
	GlobalSettings.update_fullscreen(toggled_on)
