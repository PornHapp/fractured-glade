class_name HurtState extends State
## Состояние получения урона: краткая анимация hurt, затем возврат к движению.
##
## Окно неуязвимости (длится дольше) управляется HealthComponent,
## мигание спрайта - AnimationController по сигналу invulnerability_changed.
##
## Визуал: AnimationController.play_hurt() -> анимация hurt.
## Переход: таймер истек -> IdleState / RunState / JumpState / FallState.


@export_category("Hurt")
## Длительность анимации получения урона, сек.
@export var hurt_duration: float = 0.25

var _timer: float = 0.0


func enter() -> void:
	_timer = hurt_duration
	animation.cancel_interact()
	animation.play_hurt()


func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to(state_machine.get_movement_target())
