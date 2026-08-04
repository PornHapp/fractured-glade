extends Control

# --- НАСТРОЙКИ ГЛАЗ ---
var fade_time = 5.5 # За сколько секунд глаз плавно появляется и исчезает
var show_time = 3.0 # Сколько секунд глаз "смотрит" на игрока, прежде чем исчезнуть
var min_delay = 0.3 # Минимальная пауза перед появлением нового глаза
var max_delay = 1.0 # Максимальная пауза

var eyes = []

func _ready():
	# Собираем все картинки глаз (дочерние узлы) в один список
	for child in get_children():
		if child is TextureRect or child is Sprite2D:
			# На всякий случай жестко делаем их прозрачными на старте
			child.modulate.a = 0.0
			eyes.append(child)
	
	# Запускаем бесконечный цикл появления
	if eyes.size() > 0:
		_spawn_eyes_loop()

func _spawn_eyes_loop():
	while true: # Этот цикл будет крутиться вечно, пока открыто меню
		# Ждем случайное время перед появлением следующего глаза
		var wait_time = randf_range(min_delay, max_delay)
		await get_tree().create_timer(wait_time).timeout
		
		# Выбираем случайный глаз из списка
		var random_eye = eyes.pick_random()
		
		# Если этот глаз уже светится (его альфа больше 0), 
		# пропускаем шаг, чтобы не ломать ему анимацию
		if random_eye.modulate.a > 0.1:
			continue 
			
		# Запускаем анимацию для выбранного глаза
		_animate_eye(random_eye)

func _animate_eye(eye: CanvasItem):
	var tween = create_tween()
	
	# 1. Плавно появляемся (меняем Альфу на 1.0)
	tween.tween_property(eye, "modulate:a", 1.0, fade_time)
	
	# 2. Ждем (глаз смотрит на нас)
	tween.tween_interval(show_time)
	
	# 3. Плавно исчезаем (меняем Альфу на 0.0)
	tween.tween_property(eye, "modulate:a", 0.0, fade_time)
