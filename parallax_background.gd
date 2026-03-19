#Скрипт для прокрутки фону в головному меню
extends ParallaxBackground

var scroll_speed = 50 # Швидкість руху 

func _process(delta):
	# Віднімаємо координати по осі X, щоб фон постійно їхав справа наліво
	scroll_offset.x -= scroll_speed * delta
