class_name IdleState extends State
## Состояние покоя (idle): игрок стоит на полу, горизонтальный ввод
## отсутствует. Физика движения целиком в MovementController — здесь
## только отслеживание перехода в RunState / JumpState / FallState.
##
## Визуал: AnimationController показывает анимацию idle (покой).
## Переход: если появился ввод → RunState, если прыжок → JumpState.

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)