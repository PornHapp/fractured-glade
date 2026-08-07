class_name InputHandler extends Node
## Считывает ввод игрока и публикует его в виде состояния и сигналов.
##
## Единственный модуль, который напрямую работает с Input - это упрощает
## перепривязку клавиш и будущую сетевую синхронизацию (команды вместо
## прямых опросов клавиатуры). Источник правды по действиям - InputMap.


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
	## FIXME(Влад): избавиться от хардкода
	direction = Input.get_axis("move_left", "move_right")

	## FIXME(Влад): избавиться от хардкода
	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	## FIXME(Влад): избавиться от хардкода
	if Input.is_action_just_released("jump"):
		jump_released.emit()
	## FIXME(Влад): избавиться от хардкода
	if Input.is_action_just_pressed("attack"):
		attack_pressed.emit()
