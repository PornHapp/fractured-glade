class_name AttackState extends State
## Состояние атаки: проигрывает анимацию взаимодействия (interact) и по
## таймеру возвращает управление движению.
##
## Движение во время атаки не блокируется - игрок может двигаться,
## пока анимация еще играет. Имя инструмента передается в сигналы
## attack_started / attack_finished для внешних систем (HUD, звуки).
##
## Скорость повтора атаки (use_time) определяется текущим инструментом
## через ToolItemRegistry. Если инструмент не найден, используется
## fallback_use_time.
##
## При зажатой кнопке атаки состояние продолжается до истечения use_time.
## При отпускании кнопки состояние завершается досрочно.
##
## Визуал: AnimationController.play_interact_force() -> анимация interact.
## Переход: таймер истек ИЛИ кнопка отпущена -> IdleState / RunState /
##          JumpState / FallState.


@export_category("Атака")
## Время между ударами по умолчанию, сек.
## Используется, если текущий инструмент не найден в ToolItemRegistry.
@export var fallback_use_time: float = 0.5


## Имя текущего инструмента. Задается через StateMachine.try_attack().
## Не влияет на анимацию (единая interact), но передается в сигналы
## для внешних систем.
var tool_name: StringName = &""

## Фактическое время между ударами для текущего инструмента, сек.
var use_time: float = 0.5

var _timer: float = 0.0


func enter() -> void:
	# Определяем use_time из ToolItemRegistry
	var tool_item: ToolItem = ToolItemRegistry.get_tool(tool_name)
	if tool_item:
		use_time = tool_item.use_time
	else:
		use_time = fallback_use_time

	_timer = use_time
	state_machine._attack_cooldown = use_time
	animation.play_interact_force()
	player.attack_started.emit(tool_name)


func exit() -> void:
	movement.reset_external_facing()


func physics_update(delta: float) -> void:
	_timer -= delta
	# Завершаем, если таймер истёк ИЛИ кнопка атаки отпущена
	if _timer <= 0.0 or not input.is_attack_held():
		player.attack_finished.emit(tool_name)
		state_machine.transition_to(state_machine.get_movement_target())
