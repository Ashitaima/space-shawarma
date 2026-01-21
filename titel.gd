extends Label 

# НАЛАШТУВАННЯ
var speed = 2.0      # Як швидко рухається
var height = 10.0    # Амплітуда (на скільки пікселів вгору/вниз)

# Внутрішні змінні
var start_y = 0.0
var time = 0.0

func _ready():
	# Запам'ятовуємо початкову позицію, щоб не відлетів назавжди
	start_y = position.y

func _process(delta):
	time += delta
	
	# ФОРМУЛА Синусоїда
	# sin() видає значення від -1 до 1
	# Ми множимо це на height, щоб отримати від -10 до 10
	var offset = sin(time * speed) * height
	
	# Застосовуємо нову позицію
	position.y = start_y + offset
