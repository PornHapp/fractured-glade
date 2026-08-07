class_name DeadState extends State
## Состояние смерти: игрок не реагирует на ввод и просто падает.
## Горизонтальная скорость обнуляется, движение переходит в gravity-only
## (MovementController с can_move == false).
##
## При летальном уроне сначала коротко проигрывается "боль" (hurt), и только
## затем - смерть (die): порядок всегда "HurtState -> DeadState", даже когда
## damaged и died прилетают в одном такте.

## Длительность "боли" перед смертью, сек (совпадает с HurtState).
const HURT_DURATION: float = 0.25

## Таймер "боли" перед анимацией смерти, сек.
var _hurt_timer: float = 0.0
## Смерть уже проиграна (защита от повторного play каждый такт).
var _death_played: bool = false


func enter() -> void:
	movement.stop_horizontal()
	_hurt_timer = HURT_DURATION
	_death_played = false
	animation.cancel_interact()
	animation.play_hurt()


func physics_update(delta: float) -> void:
	if _death_played:
		return
	_hurt_timer -= delta
	if _hurt_timer <= 0.0:
		_death_played = true
		animation.play_dead()
		## TODO(Полина): [ЗДЕСЬ ПОТОМ БУДЕТ ЭКРАН ВОЗРОЖДЕНИЯ]