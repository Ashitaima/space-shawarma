extends Node

# Попередньо завантажуємо звуки в пам'ять (заміни шляхи на свої файли)
var sfx_success_qte = preload("res://music/Satisfying,_bright,__#4.mp3")
var sfx_click = preload("res://music/click_sound.mp3")
var sfx_cut = preload("res://music/A_single,_sharp,_cri_#2.mp3")
var sfx_error = preload("res://music/deny_sound.mp3")

func play_sfx(stream: AudioStream, start_time: float = 0.0):
	if not stream: return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	
	# Передаємо час у функцію play()
	player.play(start_time)
	
	player.finished.connect(func(): player.queue_free())
