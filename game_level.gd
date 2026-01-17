extends Control

# --- ДАНІ ПОТОЧНОЇ ГРИ ---
var current_stack: Array = []
var target_order: Array = []
var score: int = 0
var is_game_over: bool = false

# --- КОМБО І СКЛАДНІСТЬ ---
var combo_multiplier: int = 0
var difficulty_multiplier: float = 1.0

# --- ЕФЕКТИ ---
var shake_strength: float = 0.0

# --- НАЛАШТУВАННЯ ---
var ingredients_list = [
	"🫓 Лаваш", "🥩 М'ясо", "🌶️ Соус", 
	"🥒 Огірок", "🍅 Помідор", "🧀 Сир"
]
var customer_faces_list = ["👽", "🤖", "🐙", "👨‍🚀", "👾", "👺", "🤠", "🧛"]

# --- ПОСИЛАННЯ (NODES) ---
@onready var label_dish = $TableArea/CurrentDishLabel
@onready var label_order = $CustomerArea/OrderLabel
@onready var progress_patience = $CustomerArea/PatienceBar
@onready var btn_serve = $Btn_Serve
@onready var btn_restart = $Btn_Restart
@onready var label_highscore = $HighscoreLabel
@onready var label_combo = $ComboLabel
@onready var label_face = $CustomerArea/CustomerFace
@onready var btn_trash = $Btn_Trash
@onready var label_coins = $CoinsLabel 

# 1. НОВЕ: Посилання на кнопку завершення (перевір ім'я в сцені!)
@onready var btn_finish_game = $Btn_Finish_Game 

func _ready():
	# Оновлюємо інтерфейс, беручи дані з GlobalSettings
	update_ui()
	
	# Підключення кнопок інгредієнтів
	$IngredientsArea/Btn_Pita.pressed.connect(func(): add_ingredient("🫓 Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(func(): add_ingredient("🥩 М'ясо"))
	$IngredientsArea/Btn_Sauce.pressed.connect(func(): add_ingredient("🌶️ Соус"))
	$IngredientsArea/Btn_Cucumber.pressed.connect(func(): add_ingredient("🥒 Огірок"))
	$IngredientsArea/Btn_Tomato.pressed.connect(func(): add_ingredient("🍅 Помідор"))
	$IngredientsArea/Btn_Cheese.pressed.connect(func(): add_ingredient("🧀 Сир"))
	
	# Підключення основних кнопок
	btn_serve.pressed.connect(_on_serve_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_trash.pressed.connect(_on_trash_pressed)
	
	# 2. НОВЕ: Підключаємо кнопку завершення гри
	btn_finish_game.pressed.connect(_on_finish_game_pressed)
	
	btn_restart.visible = false
	label_combo.text = "" 
	
	new_customer()

func _process(delta):
	if is_game_over: return
	
	progress_patience.value -= delta * 10 * difficulty_multiplier
	
	if progress_patience.value < 30:
		label_face.modulate = label_face.modulate.lerp(Color(1, 0, 0), delta * 2)
	else:
		label_face.modulate = label_face.modulate.lerp(Color.WHITE, delta * 2)

	if progress_patience.value <= 0:
		game_over()
		
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, 5.0 * delta)
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

func _on_trash_pressed():
	if is_game_over or current_stack.is_empty(): return
	current_stack.clear()
	if score > 0: score -= 5
	apply_shake(5.0)
	update_ui()

func new_customer():
	current_stack.clear()
	target_order.clear()
	
	label_face.text = customer_faces_list.pick_random()
	label_face.modulate = Color.WHITE
	
	var order_size = randi_range(3, 5)
	target_order.append("🫓 Лаваш")
	var fillings = ingredients_list.duplicate()
	fillings.erase("🫓 Лаваш")
	
	for i in range(order_size - 1):
		target_order.append(fillings.pick_random())
	
	# --- ЛОГІКА БОНУСУ (З магазину) ---
	var start_patience = 100
	
	if "time_upgrade" in GlobalSettings.bought_items:
		start_patience = 150 # Бонус часу
		# print("Бонус часу активний!")
	
	progress_patience.value = start_patience
	# --------------------------
	
	difficulty_multiplier += 0.05 
	update_ui()

func _on_serve_pressed():
	if is_game_over: return
	
	if current_stack == target_order:
		combo_multiplier += 1
		var bonus = (combo_multiplier - 1) * 5
		score += 10 + bonus
		visual_feedback(true)
		show_combo_effect()
		animate_serving_dish()
		new_customer()
	else:
		if combo_multiplier > 1:
			show_combo_break_effect()
		combo_multiplier = 0
		label_combo.text = ""
		visual_feedback(false)
		apply_shake(15.0)
		progress_patience.value -= 25
		current_stack.clear()
		update_ui()

func _on_restart_pressed():
	get_tree().reload_current_scene()

# 3. НОВЕ: Функція для кнопки завершення
func _on_finish_game_pressed():
	if is_game_over: return
	# Просто викликаємо Game Over, ніби час вийшов, але зберігаємо очки
	game_over()

# --- ВІЗУАЛ ---

func apply_shake(strength: float):
	shake_strength = strength

func animate_serving_dish():
	var flying_label = label_dish.duplicate()
	add_child(flying_label)
	flying_label.position = label_dish.position
	flying_label.z_index = 10 
	var tween = create_tween()
	tween.tween_property(flying_label, "position", flying_label.position + Vector2(300, -200), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(flying_label, "modulate:a", 0.0, 0.5)
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
	var dish_text = " + ".join(current_stack) 
	var order_text = "  ".join(target_order)
	label_dish.text = "На столі: " + dish_text
	label_order.text = "Клієнт хоче: " + order_text + "\n\nРахунок: " + str(score)
	
	if score > GlobalSettings.highscore:
		label_highscore.text = "Рекорд: " + str(score)
	else:
		label_highscore.text = "Рекорд: " + str(GlobalSettings.highscore)
	
	var display_coins = GlobalSettings.total_coins + score
	label_coins.text = "🪙 " + str(display_coins)

func game_over():
	is_game_over = true
	
	# Конвертуємо бали поточної сесії в монети
	var coins_earned = score
	
	# Відправляємо дані в "Банк"
	GlobalSettings.save_game_results(score, coins_earned)
	
	label_order.text = "ГРУ ЗАКІНЧЕНО!\nЗароблено: +" + str(coins_earned) + " монет"
	label_coins.text = "🪙 " + str(GlobalSettings.total_coins)
	
	# 4. НОВЕ: Ховаємо кнопку завершення та вимикаємо стіл
	btn_finish_game.visible = false
	btn_serve.disabled = true
	btn_restart.visible = true
	label_combo.text = ""
