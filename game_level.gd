extends Control

# --- ДАНІ ГРИ ---
var current_stack: Array = []
var target_order: Array = []
var score: int = 0
var highscore: int = 0
var is_game_over: bool = false

# --- НОВЕ: Система Комбо ---
var combo_multiplier: int = 0  # Скільки підряд вгадали

# --- Складність ---
var difficulty_multiplier: float = 1.0
const SAVE_PATH = "user://space_shawarma.save"

# --- НАЛАШТУВАННЯ ---
# Розширений список інгредієнтів
var ingredients_list = ["Лаваш", "М'ясо", "Соус", "Огірок", "Помідор", "Сир"]

# --- ПОСИЛАННЯ (NODES) ---
@onready var label_dish = $TableArea/CurrentDishLabel
@onready var label_order = $CustomerArea/OrderLabel
@onready var progress_patience = $CustomerArea/PatienceBar
@onready var btn_serve = $Btn_Serve
@onready var btn_restart = $Btn_Restart
@onready var label_highscore = $HighscoreLabel # Переконайтесь, що він є в сцені
@onready var label_combo = $ComboLabel       # НОВЕ: Лейбл для комбо

func _ready():
	load_highscore()
	
	# 1. Підключаємо кнопки (Старі + Нові)
	$IngredientsArea/Btn_Pita.pressed.connect(func(): add_ingredient("Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(func(): add_ingredient("М'ясо"))
	$IngredientsArea/Btn_Sauce.pressed.connect(func(): add_ingredient("Соус"))
	
	# НОВІ КНОПКИ (Переконайтесь, що створили їх у сцені!)
	$IngredientsArea/Btn_Cucumber.pressed.connect(func(): add_ingredient("Огірок"))
	$IngredientsArea/Btn_Tomato.pressed.connect(func(): add_ingredient("Помідор"))
	$IngredientsArea/Btn_Cheese.pressed.connect(func(): add_ingredient("Сир"))
	
	btn_serve.pressed.connect(_on_serve_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	
	# Ховаємо зайве на старті
	btn_restart.visible = false
	label_combo.text = "" 
	
	new_customer()

func _process(delta):
	if is_game_over: return
	
	progress_patience.value -= delta * 10 * difficulty_multiplier
	
	if progress_patience.value <= 0:
		game_over()

# --- МЕХАНІКА ---

func add_ingredient(item_name: String):
	if is_game_over: return
	current_stack.append(item_name)
	update_ui()

func new_customer():
	current_stack.clear()
	target_order.clear()
	
	# Збільшуємо розмір замовлення, бо інгредієнтів стало більше (від 3 до 5)
	var order_size = randi_range(3, 5)
	
	# 1. Завжди Лаваш
	target_order.append("Лаваш")
	
	# 2. Вибираємо начинку (БЕЗ Лаваша)
	var fillings = ingredients_list.duplicate()
	fillings.erase("Лаваш")
	
	for i in range(order_size - 1):
		target_order.append(fillings.pick_random())
	
	progress_patience.value = 100
	difficulty_multiplier += 0.05 
	
	update_ui()

func _on_serve_pressed():
	if is_game_over: return
	
	if current_stack == target_order:
		# --- УСПІХ (COMBO UP) ---
		combo_multiplier += 1
		
		# Базова нагорода (10) + Бонус за комбо (5 * комбо)
		var bonus = (combo_multiplier - 1) * 5
		score += 10 + bonus
		
		visual_feedback(true)
		show_combo_effect() # Показуємо анімацію комбо
		new_customer()
	else:
		# --- ПОМИЛКА (COMBO RESET) ---
		if combo_multiplier > 1:
			show_combo_break_effect() # Ефект "Розбите комбо"
			
		combo_multiplier = 0
		label_combo.text = "" # Ховаємо напис
		
		visual_feedback(false)
		progress_patience.value -= 25
		current_stack.clear()
		update_ui()

func _on_restart_pressed():
	get_tree().reload_current_scene()

# --- ВІЗУАЛ ---

func show_combo_effect():
	if combo_multiplier > 1:
		label_combo.text = "COMBO x" + str(combo_multiplier) + "!"
		
		# Анімація "підстрибування" тексту
		label_combo.scale = Vector2(1.5, 1.5)
		var tween = create_tween()
		tween.tween_property(label_combo, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
		label_combo.modulate = Color.YELLOW # Золотий колір
	else:
		label_combo.text = ""

func show_combo_break_effect():
	label_combo.text = "COMBO LOST..."
	label_combo.modulate = Color.RED
	
	var tween = create_tween()
	# Текст зникає (прозорість -> 0) за 1 секунду
	tween.tween_property(label_combo, "modulate:a", 0.0, 1.0)

func visual_feedback(is_success: bool):
	var tween = create_tween()
	if is_success:
		self.modulate = Color(0.6, 1.0, 0.6) # Зеленуватий
	else:
		self.modulate = Color(1.0, 0.6, 0.6) # Червонуватий
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func update_ui():
	var dish_text = ", ".join(current_stack)
	var order_text = ", ".join(target_order)
		
	label_dish.text = "На столі:\n" + dish_text
	label_order.text = "Клієнт хоче:\n" + order_text + "\n\nРахунок: " + str(score)
	
	if score > highscore:
		label_highscore.text = "Рекорд: " + str(score)

func save_highscore():
	if score > highscore:
		highscore = score
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_32(highscore)
			file.close()

func load_highscore():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		highscore = file.get_32()
		file.close()
	if label_highscore:
		label_highscore.text = "Рекорд: " + str(highscore)

func game_over():
	is_game_over = true
	save_highscore()
	label_order.text = "ГРУ ЗАКІНЧЕНО!\nРахунок: " + str(score)
	btn_serve.disabled = true
	btn_restart.visible = true
	label_combo.text = "" # Ховаємо комбо в кінці
