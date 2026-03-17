extends Control

# --- СТРУКТУРА КЛІЄНТА ---
class CustomerSlot:
	var root_node: Node
	var face: Label # Поки що Label (смайлики)
	var order_label: Label
	var patience_bar: ProgressBar
	var btn_give: Button
	
	var is_active: bool = false
	var target_order: Array = []
	var info: Dictionary = {}
	var time_left: float = 0.0
	var max_time: float = 0.0

# --- ДАНІ ГРИ ---
var current_stack: Array = [] 
var slots: Array[CustomerSlot] = [] 
var score: int = 0
var is_game_over: bool = false
var spawn_timer: float = 0.0 

# --- БАЛАНС ---
var customer_types = [
	{ "name": "Бабуся", "patience": 45.0, "pay": 50 },  
	{ "name": "Студент", "patience": 30.0, "pay": 80 }, 
	{ "name": "Бізнесмен", "patience": 20.0, "pay": 150 } 
]

# --- НАЛАШТУВАННЯ ---
var ingredients_list = ["Лаваш", "М'ясо", "Соус", "Огірок", "Помідор", "Сир"]
var customer_faces_list = ["👽", "🤖", "🐙", "👨‍🚀", "👾", "👺", "🤠", "🧛"]

# --- ПОСИЛАННЯ (NODES) ---
@onready var label_dish = $TableArea/CurrentDishLabel
@onready var label_highscore = $HighscoreLabel
@onready var label_coins = $CoinsLabel 
@onready var btn_trash = $Btn_Trash
@onready var btn_finish_game = $Btn_Finish_Game 
@onready var btn_restart = $Btn_Restart
@onready var btn_ingame_shop = $Btn_InGameShop

func _ready():
	GlobalSettings.reset_ingredients()
	
	#ініціалізація слотів
	for i in range(1, 4): 
		var path = "CustomersContainer/Slot" + str(i)
		
		if has_node(path):
			var slot_node = get_node(path)
			var new_slot = CustomerSlot.new()
			new_slot.root_node = slot_node
			
			# Отримуємо посилання
			new_slot.face = slot_node.get_node("Face")
			new_slot.order_label = slot_node.get_node("OrderLabel")
			new_slot.patience_bar = slot_node.get_node("PatienceBar")
			new_slot.btn_give = slot_node.get_node("Btn_Give")
			
			#Автопереніс тексту
			new_slot.order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
			new_slot.btn_give.pressed.connect(_on_customer_clicked.bind(i-1))
			
			# Ховаємо слот
			new_slot.root_node.modulate.a = 0.0 
			new_slot.btn_give.disabled = true   
			
			slots.append(new_slot) #Виведення в консоль для перевірки чи все викликається
			print("Слот підключено: ", path)
		else:
			print("ПОМИЛКА: Не знайдено вузол " + path + ". Перевір назву в сцені!")

	print("Всього знайдено слотів: ", slots.size()) 

	update_ui()
	
	# Підключення кнопок інгредієнтів
	$IngredientsArea/Btn_Pita.pressed.connect(func(): add_ingredient("Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(func(): add_ingredient("М'ясо"))
	$IngredientsArea/Btn_Sauce.pressed.connect(func(): add_ingredient("Соус"))
	$IngredientsArea/Btn_Cucumber.pressed.connect(func(): add_ingredient("Огірок"))
	$IngredientsArea/Btn_Tomato.pressed.connect(func(): add_ingredient("Помідор"))
	$IngredientsArea/Btn_Cheese.pressed.connect(func(): add_ingredient("Сир"))
	
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_trash.pressed.connect(_on_trash_pressed)
	btn_finish_game.pressed.connect(_on_finish_game_pressed)
	btn_restart.visible = false
	
	btn_ingame_shop.pressed.connect(_on_ingame_shop_pressed)
	update_ingredients_ui()
	
	spawn_customer()

func _process(delta):
	if is_game_over: return
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_customer()
		spawn_timer = randf_range(5.0, 10.0) 
	
	for slot in slots:
		if slot.is_active:
			slot.time_left -= delta
			slot.patience_bar.value = slot.time_left
			
			var percent = slot.time_left / slot.max_time
			if percent < 0.3:
				slot.patience_bar.modulate = Color.RED
			elif percent < 0.5:
				slot.patience_bar.modulate = Color.YELLOW
			else:
				slot.patience_bar.modulate = Color.GREEN
			
			if slot.time_left <= 0:
				customer_leaves(slot, false)

func spawn_customer():
	var free_slot = null
	for slot in slots:
		if not slot.is_active:
			free_slot = slot
			break
	
	if free_slot == null: return
		
	free_slot.is_active = true
	free_slot.root_node.modulate.a = 1.0 # Робимо видимим
	free_slot.btn_give.disabled = false  # Вмикаємо кнопку
	
	free_slot.info = customer_types.pick_random()
	free_slot.face.text = customer_faces_list.pick_random()
	free_slot.face.modulate = Color.WHITE
	
	var time = free_slot.info["patience"]
	if "time_upgrade" in GlobalSettings.bought_items:
		time += 10.0
		
	free_slot.max_time = time
	free_slot.time_left = time
	free_slot.patience_bar.max_value = time
	free_slot.patience_bar.value = time
	
	generate_order(free_slot)
	update_slot_ui(free_slot)

func generate_order(slot):
	slot.target_order.clear()
	var order_size = randi_range(3, 5)
	slot.target_order.append("Лаваш")
	
	var fillings = ingredients_list.duplicate()
	fillings.erase("Лаваш")
	
	for i in range(order_size - 1):
		slot.target_order.append(fillings.pick_random())

func add_ingredient(item_name: String):
	if is_game_over: return
	
	# Перевіряємо чи є продукт
	if GlobalSettings.ingredient_counts[item_name] <= 0:
		show_floating_text("Закінчилось!", Color.RED, $IngredientsArea.global_position)
		return
		
	# Віднімаємо 1 продукт
	GlobalSettings.ingredient_counts[item_name] -= 1
	current_stack.append(item_name)
	update_ui()
	update_ingredients_ui() # Оновлюємо цифри на кнопках

func _on_customer_clicked(slot_index: int):
	# print("Натиснуто на слот №", slot_index)
	if is_game_over: return
	
	var slot = slots[slot_index]
	
	if not slot.is_active: return
		
	# Робимо копії масивів, щоб не зламати порядок відображення на екрані
	var stack_copy = current_stack.duplicate()
	var target_copy = slot.target_order.duplicate()
	
	if stack_copy == target_copy:  #Динамічне оновлення грошей
		var money = calculate_money(slot)
		score += money
		GlobalSettings.total_coins += money
	
	# Сортуємо обидві копії (порядок не має значення)
	stack_copy.sort()
	target_copy.sort()
	
	# Порівнюємо відсортовані копії
	if stack_copy == target_copy:
	
		var money = calculate_money(slot)
		score += money
		show_floating_text("+" + str(money), Color.GREEN, slot.root_node.global_position)
		
		# Передаємо true, бо успіх
		customer_leaves(slot, true)
		
		current_stack.clear()
		update_ui()
	else:
		show_floating_text("Не те!", Color.RED, slot.root_node.global_position)
		slot.time_left -= 5.0

func calculate_money(slot) -> int:
	var money = slot.info["pay"]
	if slot.time_left < (slot.max_time * 0.5):
		money = int(money * 0.7) 
	return money


func customer_leaves(slot, success: bool):

	slot.is_active = false
	
	# Ховаємо слот
	slot.root_node.modulate.a = 0.0 
	slot.btn_give.disabled = true
	
	if success:
		# Якщо успіх - прискорюємо появу наступного
		# Якщо до наступного ще довго (> 2 сек), то він прийде через 0.5-1.5 сек
		if spawn_timer > 2.0:
			spawn_timer = randf_range(0.5, 1.5)
	else:
		# Якщо провал/пішов сам
		score -= 10
		if score < 0: score = 0
		show_floating_text("-10", Color.RED, slot.root_node.global_position)
		update_ui()

func _on_trash_pressed():
	current_stack.clear()
	update_ui()

func update_ui():
	var dish_text = " + ".join(current_stack) 
	label_dish.text = "На столі: " + dish_text
	
	if score > GlobalSettings.highscore:
		label_highscore.text = "Рекорд: " + str(score)
	else:
		label_highscore.text = "Рекорд: " + str(GlobalSettings.highscore)
	
	label_coins.text = "🪙 " + str(GlobalSettings.total_coins)

func update_slot_ui(slot):
	var order_text = "  ".join(slot.target_order)
	slot.order_label.text = order_text

func show_floating_text(text: String, color: Color, pos: Vector2):
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.z_index = 20
	add_child(lbl)
	lbl.global_position = pos + Vector2(20, 20)
	
	var tween = create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tween.tween_callback(lbl.queue_free)

func _on_finish_game_pressed():
	if is_game_over: return
	game_over()

func _on_restart_pressed():
	get_tree().reload_current_scene()

func game_over():
	is_game_over = true
	GlobalSettings.save_game_results(score, score)
	btn_finish_game.visible = false
	btn_restart.visible = true
	
func update_ingredients_ui():
	# Оновлюємо текст кнопок, щоб показувати залишок, і вимикаємо їх, якщо 0
	$IngredientsArea/Btn_Pita.text = "Лаваш (" + str(GlobalSettings.ingredient_counts["Лаваш"]) + ")"
	$IngredientsArea/Btn_Pita.disabled = GlobalSettings.ingredient_counts["Лаваш"] <= 0
	
	$IngredientsArea/Btn_Meat.text = "М'ясо (" + str(GlobalSettings.ingredient_counts["М'ясо"]) + ")"
	$IngredientsArea/Btn_Meat.disabled = GlobalSettings.ingredient_counts["М'ясо"] <= 0
	
	$IngredientsArea/Btn_Sauce.text = "Соус (" + str(GlobalSettings.ingredient_counts["Соус"]) + ")"
	$IngredientsArea/Btn_Sauce.disabled = GlobalSettings.ingredient_counts["Соус"] <= 0
	
	$IngredientsArea/Btn_Cucumber.text = "Огірок (" + str(GlobalSettings.ingredient_counts["Огірок"]) + ")"
	$IngredientsArea/Btn_Cucumber.disabled = GlobalSettings.ingredient_counts["М'ясо"] <= 0
	
	$IngredientsArea/Btn_Tomato.text = "Помідор (" + str(GlobalSettings.ingredient_counts["Лаваш"]) + ")"
	$IngredientsArea/Btn_Tomato.disabled = GlobalSettings.ingredient_counts["Лаваш"] <= 0
	
	$IngredientsArea/Btn_Cheese.text = "Сир (" + str(GlobalSettings.ingredient_counts["М'ясо"]) + ")"
	$IngredientsArea/Btn_Cheese.disabled = GlobalSettings.ingredient_counts["М'ясо"] <= 0

func _on_ingame_shop_pressed():
	# Ставимо гру на паузу
	get_tree().paused = true 
	
	var shop_scene = preload("res://shop.tscn")
	var shop_instance = shop_scene.instantiate()
	add_child(shop_instance)
	
	# Коли магазин закриється (зробить queue_free) пауза знімається
	shop_instance.tree_exited.connect(func(): 
		get_tree().paused = false
		update_ingredients_ui() # Оновлюємо кнопки після покупок
	)
