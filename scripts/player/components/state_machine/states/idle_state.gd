class_name IdleState extends State
## Состояние покоя: игрок стоит на полу, горизонтальный ввод отсутствует.
## Физика не обрабатывается — она целиком в MovementController; здесь только
## слежение за переходом в более подходящее состояние движения.

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)