class_name State extends Node
## Базовый класс состояния игрока.
##
## Каждое состояние — узел-ребёнок StateMachine. Ссылки на компоненты игрока
## выдаются через StateMachine.setup(). Поведение задаётся переопределением
## enter() / exit() / physics_update().

var player: Player
var state_machine: StateMachine
var input: InputHandler
var movement: MovementController
var animation: AnimationController
var health: HealthComponent


## Вызывается при входе в состояние.
func enter() -> void:
	pass


## Вызывается при выходе из состояния.
func exit() -> void:
	pass


## Вызывается каждый физический такт, пока состояние активно.
## @param _delta - время такта, сек
func physics_update(_delta: float) -> void:
	pass