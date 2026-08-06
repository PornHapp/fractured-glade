class_name AttackState extends State
## Состояние атаки: проигрывает анимацию удара выбранным инструментом и по
## таймеру возвращает управление движению. Движение во время атаки
## не блокируется - это поведение сохранено из старого скрипта.

## Длительность анимации атаки, сек.
const ATTACK_DURATION: float = 0.4

## Инструмент текущей атаки. Задаётся через StateMachine.try_attack().
var tool: Player.ToolType = Player.ToolType.SWORD

var _timer: float = 0.0


func enter() -> void:
	_timer = ATTACK_DURATION
	# Единая анимация взаимодействия: добыча, установка и атака используют её.
	animation.play_interact()
	player.attack_started.emit(tool)


func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		player.attack_finished.emit(tool)
		state_machine.transition_to(state_machine.get_movement_target())