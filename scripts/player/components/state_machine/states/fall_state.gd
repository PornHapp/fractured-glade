class_name FallState extends State
## Состояние падения (fall): игрок в воздухе, скорость по Y
## неотрицательная (движется вниз или стоит на месте в воздухе).
## Физика в MovementController.
##
## Визуал: AnimationController показывает анимацию fall.
## Переход: приземлился на пол → IdleState / RunState (по вводу).
## Примечание: койот-таймер в MovementController позволяет прыгнуть
## ещё 0.1 сек после схода с края.

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)