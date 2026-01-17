extends Control


var price_time_upgrade = 50


@onready var label_coins = $CoinsLabel
@onready var btn_buy_time = $Btn_Buy_Time
@onready var btn_back = $Btn_Back
@onready var btn_reset = $Btn_Reset

func _ready():
	update_ui()
	
	btn_back.pressed.connect(_on_back_pressed)
	btn_buy_time.pressed.connect(_on_buy_time_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)

# --- Оновлення інтерфейсу ---
func update_ui():
	label_coins.text = "Гроші: " + str(GlobalSettings.total_coins)
	
	# Логіка кнопки товару
	if "time_upgrade" in GlobalSettings.bought_items:
		btn_buy_time.text = "ВЖЕ КУПЛЕНО"
		btn_buy_time.disabled = true
		btn_buy_time.modulate = Color(0.5, 0.5, 0.5)
	else:
		btn_buy_time.text = "Купити + 50% до терпіння - " + str(price_time_upgrade)
		btn_buy_time.disabled = false # Вмикаємо назад (для ресету)
		
		if GlobalSettings.total_coins < price_time_upgrade:
			btn_buy_time.modulate = Color(1, 0.5, 0.5)
		else:
			btn_buy_time.modulate = Color.WHITE

func _on_back_pressed():
	# Перевіряємо, яка сцена зараз головна
	if get_tree().current_scene.name == "Shop":
		# Варіант A: Магазин відкрито з Головного Меню (як окрему сцену)
		get_tree().change_scene_to_file("res://main_menu.tscn")
	else:
		# Варіант B: Магазин відкрито поверх гри (як вікно)
		queue_free() # Просто видаляємо вікно магазину, гра залишається під ним

func _on_buy_time_pressed():
	if GlobalSettings.total_coins >= price_time_upgrade:
		GlobalSettings.total_coins -= price_time_upgrade
		GlobalSettings.bought_items.append("time_upgrade")
		GlobalSettings.save_data()
		update_ui()
	else:
		print("Не вистачає грошей!")

func _input(event):
	# Якщо натиснули ESC
	if event.is_action_pressed("ui_cancel"):
		# Викликаємо ту саму функцію, що і кнопка "Назад"
		_on_back_pressed()
		
		# ВАЖЛИВО: Кажемо Godot, що ми "з'їли" це натискання.
		# Щоб воно не пішло далі до Меню Паузи.
		get_viewport().set_input_as_handled()
		
		
# Функція повного скидання
func _on_reset_pressed():
	# Очищаємо список покупок
	GlobalSettings.bought_items.clear()
	
	# Обнуляємо гроші(можна виставити що потрібно)
	GlobalSettings.total_coins = 0
	
	GlobalSettings.save_data()
	
	# Оновлюємо вигляд магазину (кнопка покупки знову стане активною)
	update_ui()
	print("Прогрес скинуто!")
