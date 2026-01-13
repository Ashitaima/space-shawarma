extends Control

func _ready():
	visible = false 

func _input(event):
	# Якщо натиснули ESC (ui_cancel)
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	# Перемикаємо стан паузи (була true стане false і навпаки)
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	# Показуємо або ховаємо це меню
	visible = new_pause_state

# Не забудьте підключити сигнал pressed від кнопки "Продовжити" до цього скрипта!
func _on_btn_Resume_pressed():
	toggle_pause()

func _on_btn_Exit_pressed():
	get_tree().quit()


func _on_btn_Main_Menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
