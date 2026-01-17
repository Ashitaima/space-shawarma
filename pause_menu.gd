extends Control

# УВАГА: Перевір, чи файл називається "Shop.tscn" чи "shop.tscn" у твоїй папці!
# Я поставив з великої літери, як ми робили раніше.
var shop_scene_resource = preload("res://shop.tscn")

func _ready():
	visible = false
	# Налаштування повзунків
	$Settings_Panel/VBoxContainer/Volume_Slider.value = GlobalSettings.current_volume_db_index
	$Settings_Panel/VBoxContainer/Fullscreen_Checkbox.button_pressed = GlobalSettings.is_fullscreen

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state == true:
		show_main_buttons()

# --- Допоміжні функції ---

func show_main_buttons():
	$VMenu.visible = true
	$Settings_Panel.visible = false

func show_settings():
	$VMenu.visible = false
	$Settings_Panel.visible = true

# --- Сигнали кнопок ---

func _on_btn_Main_Menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn") # Перевір назву файлу меню!
	
func _on_btn_resume_pressed():
	toggle_pause()

func _on_btn_settings_pressed():
	show_settings()

func _on_btn_back_pressed(): 
	show_main_buttons()

func _on_btn_quit_pressed():
	get_tree().quit()

# --- ЛОГІКА МАГАЗИНУ ---

func _on_btn_shop_pressed():
	print("Кнопка Магазину в паузі натиснута!") # <--- ПЕРЕВІРКА
	
	# Створюємо магазин
	var shop_instance = shop_scene_resource.instantiate()
	add_child(shop_instance)
	
	# Ховаємо меню паузи
	$VMenu.visible = false
	
	# Чекаємо закриття магазину
	shop_instance.tree_exited.connect(_on_shop_closed)

func _on_shop_closed():
	print("Магазин закрито, повертаємо меню")
	show_main_buttons()

# --- Налаштування ---

func _on_volume_slider_value_changed(value):
	GlobalSettings.update_volume(value)

func _on_fullscreen_check_toggled(toggled_on):
	GlobalSettings.update_fullscreen(toggled_on)
