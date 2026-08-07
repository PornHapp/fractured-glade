class_name JumpState extends State
## Состояние подъема: игрок в воздухе, скорость по Y отрицательная (вверх).
##
## Физика в MovementController. Горизонтальное движение продолжается
## (полный контроль в воздухе).
## Визуал: AnimationController показывает анимацию jump.
## Переход: скорость по Y стала ≥ 0 -> FallState.

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)
