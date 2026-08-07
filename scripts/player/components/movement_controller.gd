class_name MovementController extends Node
## Физика движения игрока: горизонталь, гравитация и прыжок.
##
## Работает с velocity тела игрока (родителя) и вызывает move_and_slide().
## Не читает Input - состояние ввода приходит из InputHandler.
##
## Параметры настраиваются из инспектора по категориям:
##   Движение - скорость, ускорение, трение, гравитация
##   Прыжок - прыжок, койот-таймер, буфер нажатия, переменная высота


# --- Движение ---

@export_category("Движение")
## Базовая скорость движения, px/с. Соответствует анимации idle.
## Увеличивается speed_multiplier'ом от внешних факторов (артефакты, баффы).
@export var move_speed: float = 150.0
## Множитель скорости от внешних факторов (артефакты, дебаффы).
## Влияет на выбор анимации idle/run в AnimationController.
@export var speed_multiplier: float = 1.0
## Ускорение на земле, px/с².
@export var ground_acceleration: float = 1600.0
## Трение на земле (когда ввод не зажат), px/с².
@export var ground_friction: float = 1600.0
## Ускорение в воздухе, px/с² (Terraria: полный контроль горизонтали).
@export var air_acceleration: float = 1200.0
## Торможение в воздухе, px/с² (минимальное, скорость сохраняется).
@export var air_friction: float = 300.0
## Терминальная скорость падения, px/с.
@export var max_fall_speed: float = 420.0


# --- Прыжок ---

@export_category("Прыжок")
## Скорость прыжка, px/с (минус = вверх).
@export var jump_velocity: float = -320.0
## Доля подъема при резком отпускании кнопки прыжка (переменная высота).
## 0.5 = при отпускании вертикальная скорость умножается на 0.5.
@export var jump_cut_multiplier: float = 0.5
## Койот-таймер: время (сек) после схода с края, когда прыжок еще возможен.
@export var coyote_time: float = 0.1
## Буфер прыжка: время (сек), в течение которого нажатие прыжка запоминается.
@export var jump_buffer_time: float = 0.12


# --- Внутреннее состояние ---

## Направление взгляда: 1 = вправо, -1 = влево.
var facing: int = 1

## Оставшееся койот-окно, сек.
var coyote_timer: float = 0.0
## Оставшееся время буфера прыжка, сек.
var jump_buffer_timer: float = 0.0

## Флаг: внешний facing активен (face_toward). Пока активен,
## _update_horizontal_movement() не перезаписывает facing вводом.
var _external_facing_active: bool = false

## Тело игрока (родитель).
var body: CharacterBody2D
## Ввод игрока.
var input: InputHandler

## Гравитация из настроек проекта (physics/2d/default_gravity).
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)


## Скорость тела (для чтения состояниями и анимацией).
var velocity: Vector2:
	get:
		return body.velocity


# --- Инициализация ---

## Привязывает ссылки на тело и ввод. Вызывается игроком в _ready().
func setup(player_body: CharacterBody2D, input_handler: InputHandler) -> void:
	body = player_body
	input = input_handler


# --- Обновление ---

## Обновляет физику движения. Вызывается каждый физический такт.
## @param delta - время такта, сек
## @param can_move - false при смерти: только гравитация, без ввода
func update(delta: float, can_move: bool) -> void:
	if can_move:
		_update_jump(delta)
		_update_horizontal_movement(delta)
	_update_gravity(delta)
	body.move_and_slide()


# --- Обработчики сигналов ввода ---

## Запоминает нажатие прыжка для буфера.
func on_jump_pressed() -> void:
	jump_buffer_timer = jump_buffer_time


## Обрезает подъем при отпускании кнопки (переменная высота).
func on_jump_released() -> void:
	if body.velocity.y < 0.0:
		body.velocity.y *= jump_cut_multiplier


## true, если игрок стоит на полу.
func is_on_floor() -> bool:
	return body.is_on_floor()


## Обнуляет горизонтальную скорость (вызывается при смерти).
func stop_horizontal() -> void:
	body.velocity.x = 0.0


# --- Управление направлением взгляда ---

## Поворачивает спрайт в сторону мировой точки.
## Используется при взаимодействии (добыча, установка блока).
## Активирует _external_facing_active - ввод не перезаписывает facing.
## @param target_position - мировые координаты цели
func facing_toward(target_position: Vector2) -> void:
	if target_position.x < body.global_position.x:
		facing = -1
	elif target_position.x > body.global_position.x:
		facing = 1
	_external_facing_active = true


## Сбрасывает флаг внешнего facing.
## Вызывается при завершении или отмене взаимодействия.
func reset_external_facing() -> void:
	_external_facing_active = false


# --- Внутренняя физика ---

## Прыжок с буфером нажатия и койот-таймером.
func _update_jump(delta: float) -> void:
	# Буфер: нажатие (из on_jump_pressed) убывает со временем
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	# Койот-таймер: стоим на полу - окно полноценное, иначе убывает
	if body.is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	# Прыжок: буфер нажат и стоим (или еще в койот-окне)
	if jump_buffer_timer > 0.0 and (body.is_on_floor() or coyote_timer > 0.0):
		body.velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


## Горизонтальное движение с ускорением/трением (полный контроль в воздухе).
func _update_horizontal_movement(delta: float) -> void:
	var current_speed: float = move_speed * speed_multiplier
	var acceleration: float = ground_acceleration if body.is_on_floor() else air_acceleration
	var friction: float = ground_friction if body.is_on_floor() else air_friction

	if input.direction != 0.0:
		body.velocity.x = move_toward(body.velocity.x, input.direction * current_speed, acceleration * delta)
		if not _external_facing_active:
			facing = int(sign(input.direction))
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, friction * delta)


## Применяет гравитацию и ограничивает скорость падения.
func _update_gravity(delta: float) -> void:
	if not body.is_on_floor():
		body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)
