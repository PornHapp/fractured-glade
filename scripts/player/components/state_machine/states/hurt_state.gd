class_name HurtState extends State
## Состояние получения урона: краткая анимация hurt, затем возврат к движению.
## Окно неуязвимости (длится дольше) управляется HealthComponent, мигание
## спрайта — AnimationController по сигналу invulnerability_changed.

## Длительность анимации получения урона, сек.
const HURT_DURATION: float = 0.25

var _timer: float = 0.0


func enter() -> void:
	_timer = HURT_DURATION
	animation.play_hurt()


func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to(state_machine.get_movement_target())