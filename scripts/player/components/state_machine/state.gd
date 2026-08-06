class_name State extends Node
## Базовый класс состояния игрока.
##
## Каждое состояние - узел-ребенок StateMachine. Ссылки на компоненты
## игрока выдаются через StateMachine.setup(). Поведение задается
## переопределением enter() / exit() / physics_update().
##
## Доступные ссылки (заполняются автоматически):
##   player      	- корневой узел Player (сигналы, публичный API)
##   state_machine 	- машина состояний (переходы через transition_to)
##   input       	- ввод (direction, jump_pressed/released/attack_pressed)
##   movement    	- физика (velocity, facing, is_on_floor, jump/released)
##   animation   	- анимации (play_interact, play_hurt, play_dead, play)
##   health      	- здоровье (health, is_dead, is_invulnerable)

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