extends Node

# Шлях до файлу збереження (user:// - це спеціальна папка користувача на ПК)
const SAVE_PATH = "user://settings.cfg"

# Змінні
var current_volume_db_index = 0.5
var is_fullscreen = false

var master_bus_index = AudioServer.get_bus_index("Master")

func _ready():
	# При запуску гри пробуємо завантажити файл
	load_settings()

# --- ФУНКЦІЇ ЗМІНИ ТА ЗБЕРЕЖЕННЯ ---

func update_volume(value):
	current_volume_db_index = value
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
	# Зберігаємо одразу після зміни
	save_settings()

func update_fullscreen(toggled_on):
	is_fullscreen = toggled_on
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Зберігаємо одразу після зміни
	save_settings()

# --- ЛОГІКА РОБОТИ З ФАЙЛОМ ---

func save_settings():
	var config = ConfigFile.new()
	
	# Записуємо дані у секції (Section, Key, Value)
	config.set_value("Audio", "volume", current_volume_db_index)
	config.set_value("Display", "fullscreen", is_fullscreen)
	
	# Зберігаємо файл на диск
	config.save(SAVE_PATH)

func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)

	# Якщо файл успішно завантажився (він існує)
	if error == OK:
		# Читаємо значення (або беремо стандартні, якщо їх немає)
		current_volume_db_index = config.get_value("Audio", "volume", 0.5)
		is_fullscreen = config.get_value("Display", "fullscreen", false)
		
		# Одразу застосовуємо те, що прочитали
		update_volume(current_volume_db_index)
		update_fullscreen(is_fullscreen)
