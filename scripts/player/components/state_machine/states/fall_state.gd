class_name FallState extends State
## Состояние падения: игрок в воздухе, скорость по Y неотрицательная (вниз).
##
## Физика в MovementController. Койот-таймер в MovementController
## позволяет прыгнуть еще 0.1 сек после схода с края.
## Визуал: AnimationController показывает анимацию fall.
## Переход: приземлился -> IdleState / RunState (по вводу).

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)
