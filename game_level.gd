extends Control

# --- ДАНІ ГРИ ---
var current_stack: Array = []
var target_order: Array = []
var score: int = 0
var highscore: int = 0
var is_game_over: bool = false

# --- КОМБО І СКЛАДНІСТЬ ---
var combo_multiplier: int = 0
var difficulty_multiplier: float = 1.0
const SAVE_PATH = "user://space_shawarma.save"

# --- ЕФЕКТИ (Тряска) ---
var shake_strength: float = 0.0

# --- НАЛАШТУВАННЯ (З ЕМОДЗІ) ---
# Ми використовуємо ці точні назви для генерації та перевірки
var ingredients_list = [
	"🫓 Лаваш", 
	"🥩 М'ясо", 
	"🌶️ Соус", 
	"🥒 Огірок", 
	"🍅 Помідор", 
	"🧀 Сир"
]

# --- ПОСИЛАННЯ (NODES) ---
@onready var label_dish = $TableArea/CurrentDishLabel
@onready var label_order = $CustomerArea/OrderLabel
@onready var progress_patience = $CustomerArea/PatienceBar
@onready var btn_serve = $Btn_Serve
@onready var btn_restart = $Btn_Restart
@onready var label_highscore = $HighscoreLabel
@onready var label_combo = $ComboLabel

func _ready():
	load_highscore()
	
	# 1. Підключаємо кнопки до нових назв з ЕМОДЗІ
	# Важливо: Назви тут мають співпадати зі списком ingredients_list
	$IngredientsArea/Btn_Pita.pressed.connect(func(): add_ingredient("🫓 Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(func(): add_ingredient("🥩 М'ясо"))
	$IngredientsArea/Btn_Sauce.pressed.connect(func(): add_ingredient("🌶️ Соус"))
	
	# Додаткові інгредієнти
	$IngredientsArea/Btn_Cucumber.pressed.connect(func(): add_ingredient("🥒 Огірок"))
	$IngredientsArea/Btn_Tomato.pressed.connect(func(): add_ingredient("🍅 Помідор"))
	$IngredientsArea/Btn_Cheese.pressed.connect(func(): add_ingredient("🧀 Сир"))
	
	btn_serve.pressed.connect(_on_serve_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	
	btn_restart.visible = false
	label_combo.text = "" 
	
	new_customer()

func _process(delta):
	if is_game_over: return
	
	# 1. Логіка терпіння
	progress_patience.value -= delta * 10 * difficulty_multiplier
	if progress_patience.value <= 0:
		game_over()
		
	# 2. Логіка тряски екрану (Shake)
	if shake_strength > 0:
		# Зменшуємо силу тряски з часом (lerp)
		shake_strength = lerp(shake_strength, 0.0, 5.0 * delta)
		# Зсуваємо весь екран випадково
		self.position = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		self.position = Vector2.ZERO

# --- МЕХАНІКА ---

func add_ingredient(item_name: String):
	if is_game_over: return
	current_stack.append(item_name)
	update_ui()
	
	# Маленький звук/ефект при додаванні можна додати тут

func new_customer():
	current_stack.clear()
	target_order.clear()
	
	var order_size = randi_range(3, 5)
	
	# Завжди Лаваш (використовуємо назву з емодзі!)
	target_order.append("🫓 Лаваш")
	
	# Начинка (все крім Лаваша)
	var fillings = ingredients_list.duplicate()
	fillings.erase("🫓 Лаваш")
	
	for i in range(order_size - 1):
		target_order.append(fillings.pick_random())
	
	progress_patience.value = 100
	difficulty_multiplier += 0.05 
	
	update_ui()

func _on_serve_pressed():
	if is_game_over: return
	
	if current_stack == target_order:
		# --- УСПІХ ---
		combo_multiplier += 1
		var bonus = (combo_multiplier - 1) * 5
		score += 10 + bonus
		
		visual_feedback(true)
		show_combo_effect()
		
		# Запускаємо анімацію видачі перед тим, як очистити UI
		animate_serving_dish()
		
		new_customer()
	else:
		# --- ПОМИЛКА ---
		if combo_multiplier > 1:
			show_combo_break_effect()
		combo_multiplier = 0
		label_combo.text = ""
		
		visual_feedback(false)
		apply_shake(15.0) # <--- ТРЯСЕМО ЕКРАН!
		
		progress_patience.value -= 25
		current_stack.clear()
		update_ui()

func _on_restart_pressed():
	get_tree().reload_current_scene()

# --- ВІЗУАЛ ТА ЕФЕКТИ ---

func apply_shake(strength: float):
	shake_strength = strength

func animate_serving_dish():
	# 1. Створюємо копію лейбла, який буде летіти
	var flying_label = label_dish.duplicate()
	add_child(flying_label)
	
	# Позиція така ж, як у оригіналу (щоб гравець не помітив підміни)
	flying_label.position = label_dish.position
	# Робимо його поверх усього
	flying_label.z_index = 10 
	
	# 2. Налаштовуємо анімацію (Tween)
	var tween = create_tween()
	# Летить вправо і вгору (до клієнта) за 0.5 сек
	tween.tween_property(flying_label, "position", flying_label.position + Vector2(300, -200), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# Одночасно зникає (прозорість -> 0)
	tween.parallel().tween_property(flying_label, "modulate:a", 0.0, 0.5)
	
	# 3. Видаляємо копію після завершення
	tween.tween_callback(flying_label.queue_free)

func show_combo_effect():
	if combo_multiplier > 1:
		label_combo.text = "COMBO x" + str(combo_multiplier) + "!"
		label_combo.scale = Vector2(1.5, 1.5)
		label_combo.modulate = Color.YELLOW
		
		var tween = create_tween()
		tween.tween_property(label_combo, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
	else:
		label_combo.text = ""

func show_combo_break_effect():
	label_combo.text = "COMBO LOST..."
	label_combo.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(label_combo, "modulate:a", 0.0, 1.0)

func visual_feedback(is_success: bool):
	var tween = create_tween()
	if is_success:
		self.modulate = Color(0.6, 1.0, 0.6)
	else:
		self.modulate = Color(1.0, 0.6, 0.6)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func update_ui():
	# ЗМІНА: Використовуємо " + " для столу та пробіли для замовлення
	# Було: "\n".join(...)
	var dish_text = " + ".join(current_stack) 
	var order_text = "  ".join(target_order)
		
	# ЗМІНА: Прибираємо переноси рядків після "На столі:" та "Клієнт хоче:"
	# Щоб текст йшов в один рядок відразу за двокрапкою
	label_dish.text = "На столі: " + dish_text
	label_order.text = "Клієнт хоче: " + order_text + "\n\nРахунок: " + str(score)
	
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
	label_combo.text = ""
