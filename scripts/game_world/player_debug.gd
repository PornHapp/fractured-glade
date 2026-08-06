class_name PlayerDebug extends Node
## Дебаг-панель Игрока (dev-инструмент).
##
## Во время игры позволяет проверить работу ВСЕХ состояний, дёргая публичные
## методы/сигналы Игрока и меняя ему здоровье клавишами:
##   - 8 — урон (проверить HurtState и мигание при неуязвимости);
##   - 9 — летальный урон (проверить DeadState и анимацию die);
##   - 0 — полное восстановление и воскрешение (возврат к движению).
## Подключается к сигналам Игрока и печатает переходы состояния/HP в консоль.

## Клавиша урона.
const DAMAGE_KEY: int = KEY_8
## Клавиша летального урона (смерть).
const KILL_KEY: int = KEY_9
## Клавиша лечения/воскрешения.
const HEAL_KEY: int = KEY_0

## Урон по клавише 8, HP.
const DEBUG_DAMAGE: int = 20
## Урон по клавише 9 (летальный), HP.
const DEBUG_LETHAL_DAMAGE: int = 9999

## Целевой игрок (задаётся через setup()).
var _player: Player = null


## Принимает ссылку на игрока. Вызывается главной сценой после создания игрока.
## Нет-оп, если игрок не создан (например, сбой загрузки сцены).
## @param player - узел Игрока
func setup(player: Player) -> void:
	if not player:
		push_warning("[PlayerDebug] игрок не получен — панель отключена.")
		return
	if _player:
		_disconnect_current()
	_player = player
	_player.health_changed.connect(_on_health_changed)
	_player.damaged.connect(_on_damaged)
	_player.died.connect(_on_died)
	_player.state_machine.state_changed.connect(_on_state_changed)
	print("[PlayerDebug] подключено к игроку, HP = ", _player.health)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _player == null:
		return
	match event.keycode:
		DAMAGE_KEY:
			_player.take_damage(DEBUG_DAMAGE)
		KILL_KEY:
			_player.take_damage(DEBUG_LETHAL_DAMAGE)
		HEAL_KEY:
			_player.revive()
			print("[PlayerDebug] Игрок воскрешён, HP = ", _player.health)


## Отключается от прежнего игрока (если setup() вызван повторно).
func _disconnect_current() -> void:
	var machine: StateMachine = _player.state_machine
	_player.health_changed.disconnect(_on_health_changed)
	_player.damaged.disconnect(_on_damaged)
	_player.died.disconnect(_on_died)
	machine.state_changed.disconnect(_on_state_changed)


func _on_state_changed(state_name: StringName) -> void:
	print("[PlayerDebug] состояние -> ", state_name)


func _on_health_changed(new_value: int, old_value: int) -> void:
	print("[PlayerDebug] HP ", old_value, " -> ", new_value)


func _on_damaged(amount: int, _new_health: int) -> void:
	print("[PlayerDebug] урон ", amount)


func _on_died() -> void:
	print("[PlayerDebug] ИГРОК УМЕР")
