class_name InputHandler extends Node
## Считывает ввод игрока и публикует его в виде состояния и сигналов.
##
## Единственный модуль, который напрямую работает с Input - это упрощает
## перепривязку клавиш и будущую сетевую синхронизацию (команды вместо
## прямых опросов клавиатуры). Источник правды по действиям - InputMap.


# --- Имена действий (совпадают с проектом в project.godot) ---

const ACTION_MOVE_LEFT: StringName = &"move_left"
const ACTION_MOVE_RIGHT: StringName = &"move_right"
const ACTION_JUMP: StringName = &"jump"
const ACTION_ATTACK: StringName = &"attack"


# --- Сигналы ---

## Прыжок нажат (just_pressed).
signal jump_pressed
## Прыжок отпущен (just_released).
signal jump_released
## Нажата кнопка атаки.
signal attack_pressed


# --- Состояние ввода ---

## Направление горизонтального движения: -1 (лево), 0 (покой), 1 (право).
var direction: float = 0.0


# --- Опрос ввода ---

## Опрашивает Input каждый физический такт (вызывается игроком).
func poll() -> void:
	direction = Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)

	if Input.is_action_just_pressed(ACTION_JUMP):
		jump_pressed.emit()
	if Input.is_action_just_released(ACTION_JUMP):
		jump_released.emit()
	if Input.is_action_just_pressed(ACTION_ATTACK):
		attack_pressed.emit()


## Возвращает true, если кнопка атаки зажата (уровневая проверка).
## Используется AttackState для повтора атаки при удержании.
func is_attack_held() -> bool:
	return Input.is_action_pressed(ACTION_ATTACK)
