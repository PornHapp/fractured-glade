class_name RunState extends State
## Состояние движения: игрок на полу и двигается (ввод не нулевой).
##
## Физика целиком в MovementController - здесь только отслеживание
## перехода в IdleState / JumpState / FallState.
## Визуал: walk (при обычной скорости) или run (при превышении
## run_speed_threshold).

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)
