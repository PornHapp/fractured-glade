class_name Player extends CharacterBody2D

## Главный скрипт Игрока

## В дальнейшем будет разделен на специализированные классы игрока
## Рефакторинг пока не проводился
## Классы не выделены
## @experimental: Этот класс пока не отражает MVP.


# --- СИГНАЛЫ ---
## Атака началась (проигрывается свайп инструмента).
signal attack_started(tool: ToolType)
## Атака закончилась (анимация отыграна, можно атаковать снова).
signal attack_finished(tool: ToolType)
## Здоровье изменилось.
signal health_changed(new_value: int, old_value: int)
## Игрок получил урон.
signal damaged(amount: int, new_health: int)
## Игрок умер.
signal died

# --- ПЕРЕЧИСЛЕНИЯ ---
## Тип инструмента для анимации удара.
enum ToolType { SWORD, PICKAXE, AXE }

# --- КОНСТАНТЫ АНИМАЦИЙ ---
const ANIM_DEFAULT: StringName = &"default"
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_JUMP: StringName = &"jump"
const ANIM_FALL: StringName = &"fall"
const ANIM_HURT: StringName = &"hurt"
const ANIM_ATTACK_SWORD: StringName = &"attack_sword"
const ANIM_ATTACK_PICKAXE: StringName = &"attack_pickaxe"
const ANIM_ATTACK_AXE: StringName = &"attack_axe"

## Длительность анимации атаки, сек.
const ATTACK_DURATION: float = 0.4
## Длительность анимации получения урона, сек.
const HURT_DURATION: float = 0.25

## true - исходник спрайта смотрит вправо (спека). Пока стоит старый плейсхолдер
## (смотрит влево), держим false, чтобы не зеркалить его. После прихода новых
## спрайтов переключить на true.
const SOURCE_FACES_RIGHT: bool = false

# --- НАСТРОЙКИ ДВИЖЕНИЯ ---
@export_category("Movement")
## Скорость бега.
@export var run_speed: float = 180.0
## Скорость медленного шага (Shift / walk_slow).
@export var slow_speed: float = 75.0
## Ускорение на земле.
@export var ground_acceleration: float = 1600.0
## Трение на земле (когда ввод не зажат).
@export var ground_friction: float = 1600.0
## Ускорение в воздухе (Terraria: полный контроль горизонтали).
@export var air_acceleration: float = 1200.0
## Торможение в воздухе (минимальное, скорость сохраняется).
@export var air_friction: float = 300.0
## Терминальная скорость падения.
@export var max_fall_speed: float = 420.0

# --- НАСТРОЙКИ ПРЫЖКА ---
@export_category("Jump")
## Скорость прыжка (минус = вверх).
@export var jump_velocity: float = -320.0
## Доля подъема при резком отпускании прыжка (переменная высота).
@export var jump_cut_multiplier: float = 0.5
## Койот-таймер: время после схода с края, когда прыжок еще возможен, сек.
@export var coyote_time: float = 0.1
## Буфер прыжка: время, в течение которого нажатие прыжка запоминается, сек.
@export var jump_buffer_time: float = 0.12

# --- НАСТРОЙКИ БОЯ / ЗДОРОВЬЯ ---
@export_category("Combat")
## Максимальное здоровье.
@export var max_health: int = 100
## Время неуязвимости после получения урона, сек.
@export var invulnerability_time: float = 1.0

# --- ССЫЛКИ НА УЗЛЫ ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- СОСТОЯНИЕ ---
## Сила гравитации из настроек движка.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
## Текущее здоровье.
var health: int = max_health
## Флажок смерти.
var is_dead: bool = false
## Направление взгляда: 1 = вправо, -1 = влево.
var facing: int = 1

# Таймеры-счетчики (обновляются в _physics_process, синхронны с физикой)
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var invulnerability_timer: float = 0.0
var last_attack_tool: ToolType = ToolType.SWORD

var is_attacking: bool = false
var is_hurt: bool = false
var is_invulnerable: bool = false


func _ready() -> void:
	health = max_health
	# Стартуем с idle, чтобы не было проскока в "fall" на первом кадре
	_play_animation(ANIM_IDLE)


func _physics_process(delta: float) -> void:
	# Если персонаж умер, он просто падает и не реагирует на кнопки
	if is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return

	_handle_jump(delta)
	_handle_horizontal_movement(delta)
	_apply_gravity(delta)

	# Атака: пока всегда мечом, хотбар подключит свой инструмент позже
	if Input.is_action_just_pressed("attack"):
		play_attack(ToolType.SWORD)

	_update_action_timers(delta)

	# Эта команда применяет все наши расчеты к персонажу
	move_and_slide()

	# Зеркалим спрайт по направлению взгляда
	anim_sprite.flip_h = _should_flip()

	_update_animation()


# --- ДВИЖЕНИЕ ---

## Прыжок с буфером, койот-таймером и переменной высотой.
func _handle_jump(delta: float) -> void:
	# Буфер: запоминаем нажатие прыжка на короткое время
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	# Койот-таймер: стоим на полу - окно полноценное, иначе убывает
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# Прыжок: буфер нажат и стоим (или еще в койот-окне)
	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0):
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Переменная высота: рано отпустили прыжок - обрезаем подъем
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


## Горизонтальное движение с ускорением/трением (полный контроль в воздухе).
func _handle_horizontal_movement(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var current_speed: float = slow_speed if Input.is_action_pressed("walk_slow") else run_speed
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration
	var friction: float = ground_friction if is_on_floor() else air_friction

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
		facing = signi(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


## Применяет гравитацию и ограничивает скорость падения.
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


## Обновляет таймеры атаки, урона и неуязвимости.
func _update_action_timers(delta: float) -> void:
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false
			attack_finished.emit(last_attack_tool)

	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			is_hurt = false

	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			anim_sprite.modulate.a = 1.0


# --- АНИМАЦИИ ---

## Резолвер анимаций: действие (атака/урон) не перебивается движением.
func _update_animation() -> void:
	if is_dead or is_attacking or is_hurt:
		return
	if not is_on_floor():
		_play_animation(ANIM_FALL if velocity.y >= 0.0 else ANIM_JUMP)
	elif absf(velocity.x) > 1.0:
		_play_animation(ANIM_WALK)
	else:
		_play_animation(ANIM_IDLE)


## Воспроизводит анимацию с фолбэком: запрошенная -> idle -> default.
## @param anim - имя анимации из контракта
func _play_animation(anim: StringName) -> void:
	var frames: SpriteFrames = anim_sprite.sprite_frames
	if not frames:
		return
	var target: StringName = anim
	if not frames.has_animation(target):
		target = ANIM_IDLE if frames.has_animation(ANIM_IDLE) else ANIM_DEFAULT
	if frames.has_animation(target) and anim_sprite.animation != target:
		anim_sprite.play(target)


## true, если спрайт нужно отзеркалить по горизонтали (зависит от конвенции исходника).
func _should_flip() -> bool:
	if SOURCE_FACES_RIGHT:
		return facing < 0
	return facing > 0


# --- АТАКА / УРОН ---

## Начинает атаку выбранным инструментом.
## @param tool - тип инструмента (SWORD, PICKAXE, AXE)
## @emits attack_started(tool), attack_finished(tool)
func play_attack(tool: ToolType) -> void:
	if is_dead or is_attacking or is_hurt:
		return
	is_attacking = true
	last_attack_tool = tool
	attack_timer = ATTACK_DURATION
	_play_animation(_attack_anim_for(tool))
	attack_started.emit(tool)


## Возвращает имя анимации удара для инструмента.
func _attack_anim_for(tool: ToolType) -> StringName:
	match tool:
		ToolType.SWORD:
			return ANIM_ATTACK_SWORD
		ToolType.PICKAXE:
			return ANIM_ATTACK_PICKAXE
		ToolType.AXE:
			return ANIM_ATTACK_AXE
	return ANIM_ATTACK_SWORD


## Наносит игроку урон с учетом окна неуязвимости.
## @param amount - количество урона
## @emits health_changed(new, old), damaged(amount, new_health), died
func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable:
		return
	var old_health: int = health
	health = maxi(health - amount, 0)
	health_changed.emit(health, old_health)
	if health <= 0:
		die()
		return
	is_invulnerable = true
	invulnerability_timer = invulnerability_time
	is_hurt = true
	hurt_timer = HURT_DURATION
	anim_sprite.modulate.a = 0.5  # мигание во время неуязвимости
	_play_animation(ANIM_HURT)
	damaged.emit(amount, health)


# --- СМЕРТЬ ---

## Обрабатывает смерть игрока.
## @emits died
func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity.x = 0.0
	died.emit()
	# [ЗДЕСЬ ПОТОМ БУДЕТ АНИМАЦИЯ СМЕРТИ И ЭКРАН ВОЗРОЖДЕНИЯ]
