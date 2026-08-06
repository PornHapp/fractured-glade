class_name JumpState extends State
## Состояние подъёма (jump): игрок в воздухе, скорость по Y
## отрицательная (движется вверх). Физика в MovementController.
##
## Визуал: AnimationController показывает анимацию jump.
## Переход: скорость по Y стала ≥ 0 → FallState.
## Примечание: горизонтальное движение продолжается (полный контроль
## в воздухе — Terraria-стиль).

func physics_update(_delta: float) -> void:
	var target: StringName = state_machine.get_movement_target()
	if target != name:
		state_machine.transition_to(target)