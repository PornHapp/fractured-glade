class_name RunState extends State
## Состояние бега: игрок на полу и двигается (горизонтальный ввод != 0).
## Физика в MovementController; здесь только переходы между состояниями.

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)