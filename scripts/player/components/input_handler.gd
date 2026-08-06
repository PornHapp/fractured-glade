class_name InputHandler extends Node
## Считывает ввод игрока и публикует его в виде состояния и сигналов.
## Единственный модуль, который напрямую работает с Input - это упрощает
## перепривязку клавиш и будущую сетевую синхронизацию (команды вместо
## прямых опросов клавиатуры). Источник правды по действиям - InputMap.

## Прыжок нажат (just_pressed).
signal jump_pressed
## Прыжок отпущен (just_released).
signal jump_released
## Нажата кнопка атаки.
signal attack_pressed

## Направление горизонтального движения из Input.get_axis: -1, 0 или 1.
var direction: float = 0.0


## Опрашивает Input каждый физический такт (вызывается игроком).
func poll() -> void:
	direction = Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	if Input.is_action_just_released("jump"):
		jump_released.emit()
	if Input.is_action_just_pressed("attack"):
		attack_pressed.emit()