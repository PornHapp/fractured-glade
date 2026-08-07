class_name AttackState extends State
## Состояние атаки: проигрывает анимацию взаимодействия (interact) и по
## таймеру возвращает управление движению. Движение во время атаки не
## блокируется - игрок может двигаться, пока анимация еще играет.
##
## Вызывается из StateMachine.try_attack() с именем инструмента.
## tool_name передается наружу через сигналы attack_started / attack_finished
## для внешних систем (HUD, звуки, частицы).
##
## Визуал: AnimationController.play_interact() - анимация interact.
## Переход: таймер истек →IdleState / RunState / JumpState / FallState.

## Длительность анимации атаки, сек.
const ATTACK_DURATION: float = 0.4

## Имя текущего инструмента. Задается через StateMachine.try_attack().
## Не влияет на анимацию (единая interact), но передается в сигналы
## для внешних систем.
var tool_name: StringName = &""

var _timer: float = 0.0


func enter() -> void:
	_timer = ATTACK_DURATION
	# Единая анимация взаимодействия: добыча, установка и атака используют ее.
	animation.play_interact()
	player.attack_started.emit(tool_name)


func exit() -> void:
	movement.reset_external_facing()


func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		player.attack_finished.emit(tool_name)
		state_machine.transition_to(state_machine.get_movement_target())