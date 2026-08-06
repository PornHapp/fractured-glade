class_name JumpState extends State
## Состояние подъёма: игрок в воздухе, скорость по Y отрицательная.
## Физика в MovementController; здесь только переходы между состояниями.

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)