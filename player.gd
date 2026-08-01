extends CharacterBody2D

# --- НАСТРОЙКИ ПЕРСОНАЖА ---
const SPEED = 180.0          # Обычная скорость (бег)
const SLOW_SPEED = 75.0      # Скорость, когда зажат Shift (walk_slow)
const JUMP_VELOCITY = -320.0 # Сила прыжка (с минусом, т.к. вверх по оси Y — это минус)

# Получаем силу гравитации из настроек самого движка
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Ссылки на узлы внутри игрока
@onready var anim_sprite = $AnimatedSprite2D

var is_dead = false # Флажок смерти

func _physics_process(delta):
	# Если персонаж умер, он просто падает вниз и не реагирует на кнопки
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	# 1. ГРАВИТАЦИЯ
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. ПРЫЖОК
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. ДВИЖЕНИЕ ВЛЕВО И ВПРАВО
	var direction = Input.get_axis("move_left", "move_right")
	
	# Проверяем, зажата ли кнопка медленного шага (наш walk_slow)
	var current_speed = SPEED
	if Input.is_action_pressed("walk_slow"):
		current_speed = SLOW_SPEED
		
	if direction != 0:
		velocity.x = direction * current_speed
		
		# Поворачиваем картинку туда, куда идем
		if direction > 0:
			anim_sprite.flip_h = true  # Переворачиваем оригинал, чтобы смотреть вправо
		elif direction < 0:
			anim_sprite.flip_h = false # Оставляем как есть, она и так смотрит влево
			
		# [ЗДЕСЬ ПОТОМ БУДЕТ ЗАПУСК АНИМАЦИИ БЕГА/ШАГА]
	else:
		# Плавная остановка, когда отпускаем клавиши
		velocity.x = move_toward(velocity.x, 0, current_speed)
		
		# [ЗДЕСЬ ПОТОМ БУДЕТ ЗАПУСК АНИМАЦИИ ПОКОЯ (IDLE)]

	# Эта команда применяет все наши расчеты к персонажу
	move_and_slide()

# --- ФУНКЦИЯ СМЕРТИ ---
func die():
	if is_dead: return # Чтобы не умереть дважды
	
	is_dead = true
	velocity.x = 0 # Резко останавливаемся
	print("Игрок умер!")
	# [ЗДЕСЬ ПОТОМ БУДЕТ АНИМАЦИЯ СМЕРТИ И ЭКРАН ВОЗРОЖДЕНИЯ]
