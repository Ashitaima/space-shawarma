extends Control

var price_time_upgrade = 50

@onready var label_coins = $CoinsLabel
@onready var btn_buy_time = $Btn_Buy_Time
@onready var btn_back = $Btn_Back
@onready var btn_reset = $Btn_Reset

@onready var btn_buy_meat = $Btn_Buy_Meat
@onready var btn_buy_pita = $Btn_Buy_Pita
@onready var btn_buy_sauce = $Btn_Buy_Sauce
@onready var btn_buy_cucumber = $Btn_Buy_Cucumber
@onready var btn_buy_tomato = $Btn_Buy_Tomato
@onready var btn_buy_cheese = $Btn_Buy_Cheese

func _ready():
	update_ui()
	
	btn_back.pressed.connect(_on_back_pressed)
	btn_buy_time.pressed.connect(_on_buy_time_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	
	btn_buy_meat.pressed.connect(func(): buy_ingredient("М'ясо"))
	btn_buy_pita.pressed.connect(func(): buy_ingredient("Лаваш"))
	btn_buy_sauce.pressed.connect(func(): buy_ingredient("Соус"))
	btn_buy_cucumber.pressed.connect(func(): buy_ingredient("Огірок"))
	btn_buy_tomato.pressed.connect(func(): buy_ingredient("Помідор"))
	btn_buy_cheese.pressed.connect(func(): buy_ingredient("Сир"))

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
			
	btn_buy_meat.text = "Купити м'ясо (" + str(GlobalSettings.ingredient_prices["М'ясо"]) + " 🪙) | Є: " + str(GlobalSettings.ingredient_counts["М'ясо"])
	btn_buy_pita.text = "Купити лаваш (" + str(GlobalSettings.ingredient_prices["Лаваш"]) + " 🪙) | Є: " + str(GlobalSettings.ingredient_counts["Лаваш"])
	btn_buy_sauce.text = "Купити соус (" + str(GlobalSettings.ingredient_prices["Соус"]) + " 🪙) | Є: " + str(GlobalSettings.ingredient_counts["Соус"])
	btn_buy_cucumber.text = "Купити огірок (" + str(GlobalSettings.ingredient_prices["Огірок"]) + " 🪙) | Є: " + str(GlobalSettings.ingredient_counts["Огірок"])
	btn_buy_tomato.text = "Купити помідор (" + str(GlobalSettings.ingredient_prices["Помідор"]) + " 🪙) | Є: " + str(GlobalSettings.ingredient_counts["Помідор"])
	btn_buy_cheese.text = "Купити сир (" + str(GlobalSettings.ingredient_prices["Сир"]) + " 🪙) | Є: " + str(GlobalSettings.ingredient_counts["Сир"])

func _on_back_pressed():
	# Перевіряємо, яка сцена зараз головна
	if get_tree().current_scene.name == "Shop":
		get_tree().change_scene_to_file("res://main_menu.tscn")
	else:
		queue_free()

func _on_buy_time_pressed():
	if GlobalSettings.total_coins >= price_time_upgrade:
		GlobalSettings.total_coins -= price_time_upgrade
		GlobalSettings.bought_items.append("time_upgrade")
		GlobalSettings.save_data()
		update_ui()
	else:
		print("Не вистачає грошей!")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

		_on_back_pressed()
		
func buy_ingredient(item_name: String):
	var price = GlobalSettings.ingredient_prices[item_name]
	
	if GlobalSettings.total_coins >= price:
		GlobalSettings.total_coins -= price
		GlobalSettings.ingredient_counts[item_name] += 1
		GlobalSettings.save_data()
		update_ui()
	else:
		print("Не вистачає грошей на " + item_name)
		
		
# Функція повного скидання
func _on_reset_pressed():
	# Очищаємо список покупок
	GlobalSettings.bought_items.clear()
	
	# Обнуляємо гроші (можна тут виставити скільки потрібно)
	GlobalSettings.total_coins = 0
	
	GlobalSettings.save_data()
	
	# Оновлюємо вигляд магазину (кнопка покупки знову стане активною)
	update_ui()
	print("Прогрес скинуто!")
