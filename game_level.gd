extends Control

# --- ДАНІ ГРИ ---
var current_stack: Array = []   # Що ми вже поклали (наприклад ["Лаваш", "М'ясо"])
var target_order: Array = []    # Що хоче клієнт
var score: int = 0
var is_game_over: bool = false

# --- НАЛАШТУВАННЯ ---
# Список можливих інгредієнтів. Має співпадати з тим, що ми передаємо в кнопках.
var ingredients_list = ["Лаваш", "М'ясо", "Соус"]

# --- ПОСИЛАННЯ НА ЕЛЕМЕНТИ (Nodes) ---
# @onready означає "знайди ці об'єкти, як тільки гра запуститься"
@onready var label_dish = $TableArea/CurrentDishLabel
@onready var label_order = $CustomerArea/OrderLabel
@onready var progress_patience = $CustomerArea/PatienceBar
@onready var btn_serve = $Btn_Serve

func _ready():
	# 1. Підключаємо кнопки інгредієнтів
	# Ми шукаємо кнопки вручну або через сигнал. Зробимо просто:
	$IngredientsArea/Btn_Pita.pressed.connect(func(): add_ingredient("Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(func(): add_ingredient("М'ясо"))
	$IngredientsArea/Btn_Sauce.pressed.connect(func(): add_ingredient("Соус"))
	
	# 2. Підключаємо кнопку видачі
	btn_serve.pressed.connect(_on_serve_pressed)
	
	# 3. Створюємо перше замовлення
	new_customer()

func _process(delta):
	if is_game_over: return
	
	# Зменшуємо терпіння клієнта
	progress_patience.value -= delta * 10 # Швидкість падіння (чим більше число, тим швидше)
	
	if progress_patience.value <= 0:
		game_over()

# --- МЕХАНІКА ---

func add_ingredient(item_name: String):
	if is_game_over: return
	
	# Додаємо в масив
	current_stack.append(item_name)
	update_ui()

func new_customer():
	# Очищаємо стіл
	current_stack.clear()
	target_order.clear()
	
	# Генеруємо випадкове замовлення (від 2 до 4 інгредієнтів)
	var order_size = randi_range(2, 4)
	
	# Завжди починаємо з Лаваша (логічно для шаурми)
	target_order.append("Лаваш")
	
	# Додаємо решту випадково
	for i in range(order_size - 1):
		target_order.append(ingredients_list.pick_random())
	
	# Скидаємо таймер терпіння (наприклад, 100 одиниць)
	progress_patience.value = 100
	update_ui()
	print("Новий клієнт! Хоче: ", target_order)

func _on_serve_pressed():
	if is_game_over: return
	
	# Перевірка: чи співпадають масиви?
	if current_stack == target_order:
		print("Ідеально! +10 балів")
		score += 10
		new_customer() # Наступний клієнт
	else:
		print("Фу! Це не те! (Штраф часу)")
		progress_patience.value -= 25 # Караємо зменшенням часу
		# Можна очистити стіл, щоб гравець почав заново
		current_stack.clear()
		update_ui()

func update_ui():
	var dish_text = ", ".join(current_stack)
	var order_text = ", ".join(target_order)
		
	label_dish.text = "На столі:\n" + dish_text
	label_order.text = "Клієнт хоче:\n" + order_text + "\n\nРахунок: " + str(score)

func game_over():
	is_game_over = true
	label_order.text = "ГРУ ЗАКІНЧЕНО!\nФінальний рахунок: " + str(score)
	btn_serve.disabled = true
