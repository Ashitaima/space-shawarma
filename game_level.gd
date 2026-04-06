extends Control

# Структура клієнта
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

# дані гри
var current_stack: Array = [] 
var slots: Array[CustomerSlot] = [] 
var score: int = 0
var is_game_over: bool = false
var spawn_timer: float = 0.0 


var customer_types = [
	{ "name": "Бабуся", "patience": 40.0, "pay": 25 },  
	{ "name": "Студент", "patience": 30.0, "pay": 45 }, 
	{ "name": "Бізнесмен", "patience": 20.0, "pay": 70 } 
]


var ingredients_list = ["Лаваш", "М'ясо", "Соус", "Огірок", "Помідор", "Сир"]
var customer_faces_list = ["👽", "🤖", "🐙", "👨‍🚀", "👾", "👺", "🤠", "🧛"]


#@onready var label_dish = $TableArea/CurrentDishLabel
@onready var label_highscore = $HighscoreLabel
@onready var label_coins = $CoinsLabel 
@onready var btn_trash = $Btn_Trash
@onready var btn_finish_game = $Btn_Finish_Game 
@onready var btn_restart = $Btn_Restart
@onready var btn_ingame_shop = $Btn_InGameShop

@onready var plate_container = $TableArea/PlateContainer


var ingredient_icons = {
	"Лаваш": preload("res://icons/lavash.png"),
	"М'ясо": preload("res://icons/cooked_meat.png"),
	"Соус": preload("res://icons/sauce.png"),
	"Огірок": preload("res://icons/cucumber.png"),
	"Помідор": preload("res://icons/tomato.png"),
	"Сир": preload("res://icons/cheese.png")
}
var qte_active = false       #  QTE ----------------------
var qte_speed = 100.0  # Швидкість руху курсора
var qte_direction = 1  # 1 - вправо, -1 - вліво

@onready var qte_panel = $QTEMiniGame
@onready var qte_cursor = $QTEMiniGame/QTE_Cursor
@onready var qte_target = $QTEMiniGame/QTE_Target
@onready var qte_bg = $QTEMiniGame/QTE_Bg

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
	$IngredientsArea/Btn_Lavash.pressed.connect(func(): add_ingredient("Лаваш"))
	$IngredientsArea/Btn_Meat.pressed.connect(_on_meat_button_pressed)
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
				
		if qte_active:       # Логіка для QTE ----
		# Рухаємо курсор
			qte_cursor.position.x += qte_speed * delta * qte_direction
		
		# Відбиваємося від країв фону
			if qte_cursor.position.x >= qte_bg.size.x - qte_cursor.size.x:
				qte_direction = -1
			elif qte_cursor.position.x <= 0:
				qte_direction = 1

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
	update_visual_plate() #Оновлює тарілку після кліку  --------------------------

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
		update_visual_plate()
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
		score -= 20
		if score < 0: score = 0
		show_floating_text("-10", Color.RED, slot.root_node.global_position)
		update_ui()

func _on_trash_pressed():
	current_stack.clear()
	update_ui()
	update_visual_plate()

func update_ui():
	#var dish_text = " + ".join(current_stack)  # Покищо не потрібно, замість цього є update_visual_plate
	#label_dish.text = "На столі: " + dish_text
	
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
	$IngredientsArea/Btn_Lavash.text = "Лаваш (" + str(GlobalSettings.ingredient_counts["Лаваш"]) + ")"
	$IngredientsArea/Btn_Lavash.disabled = GlobalSettings.ingredient_counts["Лаваш"] <= 0
	
	$IngredientsArea/Btn_Meat.text = "М'ясо (" + str(GlobalSettings.ingredient_counts["М'ясо"]) + ")"
	$IngredientsArea/Btn_Meat.disabled = GlobalSettings.ingredient_counts["М'ясо"] <= 0
	
	$IngredientsArea/Btn_Sauce.text = "Соус (" + str(GlobalSettings.ingredient_counts["Соус"]) + ")"
	$IngredientsArea/Btn_Sauce.disabled = GlobalSettings.ingredient_counts["Соус"] <= 0
	
	$IngredientsArea/Btn_Cucumber.text = "Огірок (" + str(GlobalSettings.ingredient_counts["Огірок"]) + ")"
	$IngredientsArea/Btn_Cucumber.disabled = GlobalSettings.ingredient_counts["Огірок"] <= 0
	
	$IngredientsArea/Btn_Tomato.text = "Помідор (" + str(GlobalSettings.ingredient_counts["Помідор"]) + ")"
	$IngredientsArea/Btn_Tomato.disabled = GlobalSettings.ingredient_counts["Помідор"] <= 0
	
	$IngredientsArea/Btn_Cheese.text = "Сир (" + str(GlobalSettings.ingredient_counts["Сир"]) + ")"
	$IngredientsArea/Btn_Cheese.disabled = GlobalSettings.ingredient_counts["Сир"] <= 0

func _on_ingame_shop_pressed():
	# Ставимо гру на паузу
	get_tree().paused = true 
	
	var shop_scene = preload("res://Scenes/shop.tscn")
	var shop_instance = shop_scene.instantiate()
	add_child(shop_instance)
	
	# Коли магазин закриється (зробить queue_free) пауза знімається
	shop_instance.tree_exited.connect(func(): 
		get_tree().paused = false
		update_ingredients_ui() # Оновлюємо кнопки після покупок
	)
	
func update_visual_plate():
	# 1. Очищаємо стіл від старих іконок (щоб вони не нашаровувалися)
	for child in plate_container.get_children():
		child.queue_free()
		
	# 2. Перебираємо наш current_stack і малюємо нові іконки
	for item_name in current_stack:
		var icon = TextureRect.new()
		icon.texture = ingredient_icons[item_name]
		#icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT_CENTERED # Щоб картинки не деформувалися
		icon.custom_minimum_size = Vector2(64, 64) # Задай розмір іконки (зміни під свої потреби)
		
		# Додаємо картинку в контейнер (він сам поставить її в ряд)
		plate_container.add_child(icon)
		
		
func _on_meat_button_pressed():                    # логіка  QTE ---------
	if is_game_over or qte_active: return
	
	# Перевіряємо, чи взагалі є м'ясо в запасах, перш ніж починати різати
	if GlobalSettings.ingredient_counts["М'ясо"] <= 0:
		show_floating_text("Закінчилось!", Color.RED, $IngredientsArea.global_position)
		return
	
	# Показуємо панель і вмикаємо рух
	qte_panel.visible = true
	qte_active = true
	qte_cursor.position.x = 0 # Починаємо з лівого краю
	
	
func _input(event):
	if is_game_over: return
	
	# Якщо міні-гра активна і гравець клікнув ЛІВУ кнопку миші
	if qte_active and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# одразу вимикаємо QTE
		qte_active = false
		qte_panel.visible = false
		
		# знаходимо центр курсора
		var cursor_center = qte_cursor.position.x + (qte_cursor.size.x / 2.0)
		
		# знаходимо межі зеленої зони (початок і кінець)
		var target_start = qte_target.position.x
		var target_end = qte_target.position.x + qte_target.size.x
		
		# перевірка чи потрапив курсор в зону
		if cursor_center >= target_start and cursor_center <= target_end:
			show_floating_text("Ідеально!", Color.GREEN, $IngredientsArea.global_position)
			
			# Віднімаємо 1 м'ясо з запасів і кладемо на стіл
			GlobalSettings.ingredient_counts["М'ясо"] -= 1
			current_stack.append("М'ясо")
			
			# Оновлюємо весь інтерфейс
			update_ui()
			update_ingredients_ui()
			update_visual_plate()
			
			# можна буде додати тут якісь бонуси при успішному
			
		else:
			show_floating_text("Криво!", Color.RED, $IngredientsArea.global_position)
