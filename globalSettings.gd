extends Node

const SAVE_PATH = "user://global_save.cfg" # Єдиний файл для всього

# --- НАЛАШТУВАННЯ ---
var current_volume_db_index = 0.5
var is_fullscreen = false

# --- ДАНІ ГРАВЦЯ (З твого коду гри) ---
var highscore: int = 0
var total_coins: int = 0  # Гроші
var bought_items: Array = [] # Товари з магазину

var master_bus_index = AudioServer.get_bus_index("Master")

func _ready():
	load_data()

# --- ФУНКЦІЇ ДЛЯ ГРИ ---

# Викликай це, коли гра закінчилась
func save_game_results(new_score: int, earned_coins: int):
	# Оновлюємо гроші
	total_coins += earned_coins
	
	# Оновлюємо рекорд, якщо побили
	if new_score > highscore:
		highscore = new_score
		
	# Зберігаємо все на диск
	save_data()

# --- ФУНКЦІЇ НАЛАШТУВАНЬ ---

func update_volume(value):
	current_volume_db_index = value
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	save_data()

func update_fullscreen(toggled_on):
	is_fullscreen = toggled_on
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_data()

# --- ЗБЕРЕЖЕННЯ ТА ЗАВАНТАЖЕННЯ ---

func save_data():
	var config = ConfigFile.new()
	
	# Секція налаштувань
	config.set_value("Settings", "volume", current_volume_db_index)
	config.set_value("Settings", "fullscreen", is_fullscreen)
	
	# Секція прогресу
	config.set_value("GameData", "highscore", highscore)
	config.set_value("GameData", "coins", total_coins)
	config.set_value("GameData", "bought_items", bought_items)
	
	config.save(SAVE_PATH)

func load_data():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)

	if error == OK:
		# Налаштування
		current_volume_db_index = config.get_value("Settings", "volume", 0.5)
		is_fullscreen = config.get_value("Settings", "fullscreen", false)
		
		# Прогрес
		highscore = config.get_value("GameData", "highscore", 0)
		total_coins = config.get_value("GameData", "coins", 0)
		bought_items = config.get_value("GameData", "bought_items", [])
		
		# Застосовуємо налаштування
		update_volume(current_volume_db_index)
		update_fullscreen(is_fullscreen)
