extends Control

func _ready():
	visible = false
	# На старті налаштовуємо повзунки з глобальних налаштувань
	$Settings_Panel/VBoxContainer/Volume_Slider.value = GlobalSettings.current_volume_db_index
	$Settings_Panel/VBoxContainer/Fullscreen_Checkbox.button_pressed = GlobalSettings.is_fullscreen

func _input(event):
	# Якщо натиснули ESC (ui_cancel)
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state == true:
		# Коли відкриваємо паузу - завжди показуємо кнопки і ховаємо налаштування
		show_main_buttons()

# --- Допоміжні функції для перемикання ---

func show_main_buttons():
	$VMenu.visible = true
	$Settings_Panel.visible = false

func show_settings():
	$VMenu.visible = false
	$Settings_Panel.visible = true

# --- Сигнали кнопок ---

func _on_btn_Main_Menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _on_btn_resume_pressed():
	toggle_pause()

func _on_btn_settings_pressed(): # Це ваша нова кнопка в списку
	show_settings()

func _on_btn_back_pressed(): # Це кнопка "Назад" всередині панелі
	show_main_buttons()

func _on_btn_quit_pressed():
	get_tree().quit()

# --- Сигнали налаштувань (Ті самі, що були) ---

func _on_volume_slider_value_changed(value):
	GlobalSettings.update_volume(value)

func _on_fullscreen_check_toggled(toggled_on):
	GlobalSettings.update_fullscreen(toggled_on)
