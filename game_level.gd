extends Control

# --- ДАНІ ГРИ ---
var current_stack: Array = []
var target_order: Array = []
var score: int = 0
var is_game_over: bool = false

# --- ЗБЕРЕЖЕНІ ДАНІ (PERSISTENT DATA) ---
var highscore: int = 0
var total_coins: int = 0  # <--- НОВЕ: Загальні гроші гравця

# --- КОМБО І СКЛАДНІСТЬ ---
var combo_multiplier: int = 0
var difficulty_multiplier: float = 1.0
const SAVE_PATH = "user://space_shawarma_v2.save" # Змінив ім'я файлу для нової версії

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
@onready var label_coins = $CoinsLabel # <--- НОВЕ: Не забудьте створити це в сцені!

func _ready():
	load_game_data() # Завантажуємо і рекорд, і монети
	update_ui()      # Оновлюємо текст монет
	
	# Підключення кнопок
	$IngredientsArea/Btn_Pita.pressed.connect(func(): add_ingredient("🫓 Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(func(): add_ingredient("🥩 М'ясо"))
	$IngredientsArea/Btn_Sauce.pressed.connect(func(): add_ingredient("🌶️ Соус"))
	$IngredientsArea/Btn_Cucumber.pressed.connect(func(): add_ingredient("🥒 Огірок"))
	$IngredientsArea/Btn_Tomato.pressed.connect(func(): add_ingredient("🍅 Помідор"))
	$IngredientsArea/Btn_Cheese.pressed.connect(func(): add_ingredient("🧀 Сир"))
	
	btn_serve.pressed.connect(_on_serve_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_trash.pressed.connect(_on_trash_pressed)
	
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
	
	progress_patience.value = 100
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
	
	if score > highscore:
		label_highscore.text = "Рекорд: " + str(score)
	
	# Оновлюємо лейбл монет
	# Якщо гра йде, показуємо загальні + поточні зароблені, або просто загальні
	label_coins.text = "🪙 " + str(total_coins)

# --- НОВА СИСТЕМА ЗБЕРЕЖЕННЯ ---

func save_game_data():
	# Ми формуємо словник з усіма даними
	var save_data = {
		"highscore": highscore,
		"coins": total_coins
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data) # store_var зберігає будь-яку структуру даних
		file.close()

func load_game_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = file.get_var() # get_var читає структуру
		file.close()
		
		# Перевіряємо, чи це правильні дані (словник)
		if data is Dictionary:
			highscore = data.get("highscore", 0)
			total_coins = data.get("coins", 0)
		else:
			# Якщо старий файл або помилка - скидаємо
			highscore = 0
			total_coins = 0
	
	label_highscore.text = "Рекорд: " + str(highscore)
	label_coins.text = "🪙 " + str(total_coins)

func game_over():
	is_game_over = true
	
	# --- НАРАХУВАННЯ МОНЕТ ---
	# Конвертуємо бали в монети. 1 бал = 1 монета (або змініть формулу)
	var coins_earned = score
	total_coins += coins_earned
	
	save_game_data() # Зберігаємо все
	
	label_order.text = "ГРУ ЗАКІНЧЕНО!\nЗароблено: +" + str(coins_earned) + " монет"
	label_coins.text = "🪙 " + str(total_coins) # Оновлюємо вигляд гаманця
	
	btn_serve.disabled = true
	btn_restart.visible = true
	label_combo.text = ""
