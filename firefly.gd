extends CharacterBody2D

# Настройки "Живого" существа
var acceleration = 800.0   # Как быстро разгоняется
var friction = 0.05        # Плавность остановки (чем меньше, тем дольше скользит)
var max_speed = 250.0      # Максимальная скорость

# Переменные для хаоса
var noise = FastNoiseLite.new()
var time = 0.0

func _ready():
	noise.seed = randi()
	noise.frequency = 0.02 # Плавный шум

func _physics_process(delta):
	time += delta
	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	
	# Считаем силу, которая будет толкать огонек
	var force = Vector2.ZERO
	
	# 1. Если мышка рядом — отталкивающая сила (Panic)
	if dist < 200.0:
		force = (global_position - mouse_pos).normalized() * 1200.0
	else:
		# 2. Рандомное "блуждание" (Wander)
		# Шум дает плавные смены направления без резких углов
		var noise_angle = noise.get_noise_1d(time * 50.0) * PI * 2.0
		force = Vector2(cos(noise_angle), sin(noise_angle)) * 400.0
		
	# Применяем силу (физика!)
	velocity += force * delta
	
	# Ограничиваем скорость, чтобы не улетал в космос
	velocity = velocity.limit_length(max_speed)
	
	# Плавное замедление (трение)
	velocity = velocity.lerp(Vector2.ZERO, friction)
	
	move_and_slide()
	
	# Отскок от стен (удар)
	var screen_size = get_viewport_rect().size
	if global_position.x < 50 or global_position.x > screen_size.x - 50:
		velocity.x *= -1.5
	if global_position.y < 50 or global_position.y > screen_size.y - 50:
		velocity.y *= -1.5
	
	# Чтобы не застревал
	global_position = global_position.clamp(Vector2(50, 50), screen_size - Vector2(50, 50))
	
	# Поворот в сторону движения (без резкости)
	if velocity.length() > 10:
		rotation = lerp_angle(rotation, velocity.angle(), 0.1)
