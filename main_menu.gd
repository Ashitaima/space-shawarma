extends Control

@onready var titel = $Titel 
@onready var promo_panel = %PromoPanel
@onready var promo_list = %PromoList

var speed = 2.0
var height = 10.0
var time = 0.0
var title_start_y = 0.0
var is_bouncing = false

var master_bus_index = AudioServer.get_bus_index("Master")

func _ready():
	$Settings_Panel.visible = false
	get_tree().paused = false
	
	$Settings_Panel/VBoxContainer/Volume_Slider.value = GlobalSettings.current_volume_db_index
	$Settings_Panel/VBoxContainer/Fullscreen_Checkbox.button_pressed = GlobalSettings.is_fullscreen
	%Btn_MyPromos.pressed.connect(_on_promos_pressed)
	%PromoPanel/Btn_ClosePromos.pressed.connect(func(): promo_panel.visible = false)
	
	# Налаштування для тексту
	if titel: # Запобіжник
		title_start_y = titel.position.y

# Анімація тексту 
func _process(delta):
	if not titel: return # Якщо тексту немає, просто ігноруємо
	
	time += delta 
	
	if is_bouncing:
		return
		
	var offset = sin(time * speed) * height
	titel.position.y = title_start_y + offset


func _on_titel_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_bouncing:
			return 
			
		is_bouncing = true 
		var tween = create_tween()
		
		# Провалюємо текст
		tween.tween_property(titel, "position:y", titel.position.y + 10, 0.1)
		
		# Пружинимо назад
		var expected_y = title_start_y + sin(time * speed) * height
		tween.tween_property(titel, "position:y", expected_y, 0.2).set_trans(Tween.TRANS_BOUNCE)
		
		# Знову дозволяємо плавати
		tween.tween_callback(func(): is_bouncing = false)



func _on_btn_Start_pressed():
	# Завантажує сцену з грою
	get_tree().change_scene_to_file("res://Scenes/game_level.tscn")

func _on_btn_Shop_pressed():
	get_tree().change_scene_to_file("res://Scenes/shop.tscn")
	
func _on_btn_My_Promos_pressed():
	$PromoPanel.visible = true

func _on_btn_Settings_pressed():
	$Settings_Panel.visible = true
	
func _on_btn_Exit_pressed():
	get_tree().quit()

# Кнопка "Назад" в налаштуваннях
func _on_btn_back_pressed():
	$Settings_Panel.visible = false

# Гучність
func _on_volume_slider_value_changed(value):
	# Передаємо зміну в глобальний скрипт
	GlobalSettings.update_volume(value)

# Повний екран
func _on_fullscreen_check_toggled(toggled_on):
	GlobalSettings.update_fullscreen(toggled_on)

func _on_promos_pressed():
	promo_panel.visible = true
	
	#Очищаємо список від старих записів (щоб не дублювалися)
	for child in promo_list.get_children():
		child.queue_free()
		
	#Якщо кодів ще немає
	if GlobalSettings.earned_promos.is_empty():
		var lbl = Label.new()
		lbl.text = "Ти ще не виграв жодного промокоду. Грай краще!"
		promo_list.add_child(lbl)
		return
		

	for code in GlobalSettings.earned_promos:
		var line_edit = LineEdit.new()
		line_edit.text = code
		line_edit.editable = false #Забороняємо змінювати код
		line_edit.custom_minimum_size = Vector2(200, 40)
		promo_list.add_child(line_edit)
