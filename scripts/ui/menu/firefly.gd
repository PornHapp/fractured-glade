extends CharacterBody2D

# Настройки поведения
@export var base_speed = 200.0
@export var max_speed = 400.0
@export var acceleration = 400.0
@export var friction = 0.95

# Расстояния для реакций
@export var mouse_panic_distance = 250.0  # Расстояние до мыши для паники
@export var wall_avoid_distance = 80.0   # Расстояние до стены для избегания

# Переменные движения
var current_direction = Vector2.ZERO
var target_direction = Vector2.ZERO
var time = 0.0
var state = "wander"  # wander, panic, explore, circle

# Шум для плавных изменений
var noise = FastNoiseLite.new()
var wander_angle = 0.0
var state_timer = 0.0
var state_duration = 0.0

# Для круговых движений
var circle_center = Vector2.ZERO
var circle_angle = 0.0
var circle_radius = 50.0
var circle_speed = 1.0

# Для резких рывков
var burst_timer = 0.0
var burst_direction = Vector2.ZERO

func _ready():
	noise.seed = randi()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	wander_angle = randf() * PI * 2
	current_direction = Vector2(cos(wander_angle), sin(wander_angle))
	target_direction = current_direction
	
	# Случайное начальное состояние
	change_state()

func _physics_process(delta):
	time += delta
	
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	var dist_to_mouse = to_mouse.length()
	
	# === ОБНОВЛЯЕМ СОСТОЯНИЕ ===
	state_timer += delta
	if state_timer > state_duration:
		change_state()
	
	# === ПОВЕДЕНИЕ В ЗАВИСИМОСТИ ОТ СОСТОЯНИЯ ===
	var desired_direction = Vector2.ZERO
	var speed = base_speed
	
	match state:
		"panic":
			# === ПАНИКА ОТ МЫШИ ===
			if dist_to_mouse < mouse_panic_distance:
				var flee_angle = to_mouse.angle() + PI
				# Добавляем хаос в убегание
				var chaos = noise.get_noise_1d(time * 3.0) * 0.5
				flee_angle += chaos
				desired_direction = Vector2(cos(flee_angle), sin(flee_angle))
				
				# Скорость зависит от близости мыши
				var panic_factor = 1.0 - (dist_to_mouse / mouse_panic_distance)
				speed = lerp(base_speed, max_speed, panic_factor * 0.8 + 0.2)
			else:
				# Если мышь далеко - возвращаемся к блужданию
				change_state()
				desired_direction = get_wander_direction(delta)
		
		"circle":
			# === ДВИЖЕНИЕ ПО КРУГУ ===
			circle_angle += delta * circle_speed * randf_range(0.8, 1.2)
			var circle_dir = Vector2(cos(circle_angle), sin(circle_angle))
			desired_direction = circle_dir
			speed = base_speed * randf_range(0.8, 1.2)
			
			# Иногда выходим из круга
			if randf() < delta * 0.3:
				change_state()
		
		"explore":
			# === ИССЛЕДОВАНИЕ С РЕЗКИМИ РЫВКАМИ ===
			burst_timer += delta
			if burst_timer > randf_range(0.3, 1.0):
				burst_timer = 0.0
				# Резкая смена направления
				var angle = randf() * PI * 2
				burst_direction = Vector2(cos(angle), sin(angle))
				speed = max_speed * randf_range(0.7, 1.0)
			else:
				# Плавное движение к цели рывка
				var to_burst = burst_direction - current_direction
				desired_direction = current_direction.lerp(burst_direction, delta * 2.0).normalized()
				speed = base_speed * randf_range(0.8, 1.2)
			
			if randf() < delta * 0.2:
				change_state()
		
		"wander":
			# === СВОБОДНОЕ БЛУЖДАНИЕ ===
			desired_direction = get_wander_direction(delta)
			speed = base_speed * randf_range(0.7, 1.0)
			
			# Иногда переходим в другие состояния
			if randf() < delta * 0.1:
				change_state()
	
	# === РЕАКЦИЯ НА МЫШЬ (в любом состоянии, если близко) ===
	if dist_to_mouse < mouse_panic_distance:
		state = "panic"
		state_timer = 0.0
		state_duration = randf_range(1.0, 3.0)
		
		var flee_angle = to_mouse.angle() + PI
		var chaos = noise.get_noise_1d(time * 3.0) * 0.5
		flee_angle += chaos
		desired_direction = Vector2(cos(flee_angle), sin(flee_angle))
		var panic_factor = 1.0 - (dist_to_mouse / mouse_panic_distance)
		speed = lerp(base_speed, max_speed, panic_factor * 0.8 + 0.2)
	
	# === ПЛАВНЫЙ ПОВОРОТ ===
	var rotation_speed = 5.0
	current_direction = current_direction.lerp(desired_direction, delta * rotation_speed).normalized()
	
	# === ПРИМЕНЯЕМ ДВИЖЕНИЕ ===
	var target_velocity = current_direction * speed
	velocity = velocity.lerp(target_velocity, delta * acceleration / 100.0)
	
	# Трение
	velocity *= friction
	
	if velocity.length() < 1.0:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# === ПЛАВНЫЙ УХОД ОТ СТЕН (без отскока) ===
	var screen_size = get_viewport_rect().size
	var wall_margin = wall_avoid_distance
	
	# Проверяем расстояние до стен
	var to_left = global_position.x
	var to_right = screen_size.x - global_position.x
	var to_top = global_position.y
	var to_bottom = screen_size.y - global_position.y
	
	# Если близко к стене - плавно отворачиваем
	var wall_force = Vector2.ZERO
	
	if to_left < wall_margin:
		wall_force.x = 1.0 * (1.0 - to_left / wall_margin)
	if to_right < wall_margin:
		wall_force.x = -1.0 * (1.0 - to_right / wall_margin)
	if to_top < wall_margin:
		wall_force.y = 1.0 * (1.0 - to_top / wall_margin)
	if to_bottom < wall_margin:
		wall_force.y = -1.0 * (1.0 - to_bottom / wall_margin)
	
	if wall_force.length() > 0.1:
		# Плавно отворачиваем от стены
		var wall_direction = wall_force.normalized()
		var avoid_strength = 0.3
		current_direction = current_direction.lerp(wall_direction, avoid_strength).normalized()
		
		# Немного замедляемся у стены
		if velocity.length() > base_speed * 0.5:
			velocity *= 0.98
	
	# === НЕ ДАЕМ ВЫЙТИ ЗА ГРАНИЦЫ (мягкое удержание) ===
	var soft_margin = 20.0
	if global_position.x < soft_margin:
		global_position.x = soft_margin
		current_direction.x = abs(current_direction.x)
	if global_position.x > screen_size.x - soft_margin:
		global_position.x = screen_size.x - soft_margin
		current_direction.x = -abs(current_direction.x)
	if global_position.y < soft_margin:
		global_position.y = soft_margin
		current_direction.y = abs(current_direction.y)
	if global_position.y > screen_size.y - soft_margin:
		global_position.y = screen_size.y - soft_margin
		current_direction.y = -abs(current_direction.y)
	
	# === ПОВОРОТ (след за движением) ===
	if velocity.length() > 10.0:
		var target_rotation = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, 0.2)

func change_state():
	# Случайная смена состояния
	var states = ["wander", "circle", "explore"]
	
	# Исключаем panic из случайного выбора (он включается от мыши)
	var new_state = states[randi() % states.size()]
	
	# Не меняем на panic случайно
	if new_state != "panic":
		state = new_state
		state_timer = 0.0
		state_duration = randf_range(2.0, 6.0)
		
		# Настройка параметров для разных состояний
		match state:
			"circle":
				circle_center = global_position
				circle_angle = randf() * PI * 2
				circle_radius = randf_range(30, 80)
				circle_speed = randf_range(0.5, 1.5)
			"explore":
				burst_timer = 0.0
				burst_direction = Vector2(cos(randf() * PI * 2), sin(randf() * PI * 2))
			"wander":
				# Ничего особенного
				pass

func get_wander_direction(delta):
	# Плавное блуждание с шумом
	var noise_val = noise.get_noise_1d(time * 1.5) * 2.0
	wander_angle += delta * (1.0 + noise_val) * 0.5
	
	# Случайные импульсы
	if randf() < delta * 0.2:
		wander_angle += (randf() - 0.5) * 1.0
	
	return Vector2(cos(wander_angle), sin(wander_angle)).normalized()
