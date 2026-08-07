class_name StateMachine extends Node
## Управляет переходами между состояниями игрока.
##
## Состояния - узлы-дети этого компонента (наследники State). Имена узлов
## должны совпадать с константами STATE_* ниже. Текущее состояние делегирует
## физику в physics_update(), а при завершении действия возвращается
## к движению через get_movement_target().


# --- Имена состояний (совпадают с именами узлов в сцене) ---

const STATE_IDLE: StringName = &"IdleState"
const STATE_RUN: StringName = &"RunState"
const STATE_JUMP: StringName = &"JumpState"
const STATE_FALL: StringName = &"FallState"
const STATE_ATTACK: StringName = &"AttackState"
const STATE_HURT: StringName = &"HurtState"
const STATE_DEAD: StringName = &"DeadState"


# --- Сигнал ---

## Имя активного состояния изменилось (для отладки и HUD).
signal state_changed(state_name: StringName)


# --- Внутреннее состояние ---

var current_state: State = null
var _states: Dictionary = {}  # StringName -> State
var _input: InputHandler
var _movement: MovementController


# --- Инициализация ---

## Собирает дочерние узлы-состояния в словарь.
func _ready() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child


## Выдает состояниям ссылки на игрока и его компоненты.
func setup(player: Player, input: InputHandler, movement: MovementController, animation: AnimationController, health: HealthComponent) -> void:
	_input = input
	_movement = movement
	for state in _states.values():
		state.player = player
		state.state_machine = self
		state.input = input
		state.movement = movement
		state.animation = animation
		state.health = health


## Переводит машину в начальное состояние.
func start() -> void:
	transition_to(get_movement_target())


# --- Обновление ---

## Делегирует физический такт текущему состоянию.
## @param delta - время такта, сек
func update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


# --- Переходы ---

## Переходит в состояние по имени. Нет-оп, если состояние неизвестно
## или уже является текущим.
## @param state_name - имя состояния (константы STATE_*)
func transition_to(state_name: StringName) -> void:
	if not _states.has(state_name):
		return
	var next: State = _states[state_name]
	if next == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = next
	current_state.enter()
	state_changed.emit(current_state.name)


## Возвращает состояние движения по текущим условиям
## (пол, скорость по Y, направление ввода). Используется состояниями
## для самопереходов и для выхода из действий.
func get_movement_target() -> StringName:
	if not _movement.is_on_floor():
		return STATE_FALL if _movement.velocity.y >= 0.0 else STATE_JUMP
	if _input.direction != 0.0:
		return STATE_RUN
	return STATE_IDLE


# --- Выход из действий ---

## Пытается начать атаку. Возвращает false, если игрок занят
## (атака/урон/смерть).
## @param tool_name - имя инструмента (любое StringName)
func try_attack(tool_name: StringName) -> bool:
	if current_state.name in [STATE_ATTACK, STATE_HURT, STATE_DEAD]:
		return false
	var attack_state := _states[STATE_ATTACK] as AttackState
	attack_state.tool_name = tool_name
	transition_to(STATE_ATTACK)
	return true


## Переводит игрока в состояние урона (вызывается по сигналу health.damaged).
## Может прервать атаку, но не смерть.
## @param _amount - размер урона (не используется, но сигнал передает 2 аргумента)
## @param _new_health - здоровье после урона
func try_hurt(_amount: int, _new_health: int) -> void:
	if current_state.name == STATE_DEAD:
		return
	transition_to(STATE_HURT)


## Переводит игрока в состояние смерти (вызывается по сигналу health.died).
func on_dead() -> void:
	transition_to(STATE_DEAD)


## Возвращает игрока из состояния смерти в подходящее состояние движения.
## Используется возрождением и отладкой. Нет-оп, если игрок не мертв.
func revive() -> void:
	if current_state == _states[STATE_DEAD]:
		transition_to(get_movement_target())
