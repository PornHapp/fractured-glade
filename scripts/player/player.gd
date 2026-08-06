class_name Player extends CharacterBody2D

## Главный скрипт игрока — составной корень (facade).
##
## Собирает компоненты-узлы, связывает их сигналами и делегирует задачи.
## Вся логика вынесена в модули:
##   - InputHandler (ввод)
##   - MovementController (физика движения)
##   - StateMachine с узлами-состояниями
##   - AnimationController (анимации)
##   - HealthComponent (здоровье)
## Здесь остаются публичный контракт для внешних систем
## (сигналы, методы) и порядок вызова компонентов.


# --- СИГНАЛЫ (публичный контракт для внешних систем: HUD, бой, хотбар) ---
## Атака началась (проигрывается анимация взаимодействия).
## @param tool_name - имя инструмента (передаётся наружу как есть, без привязки к enum)
signal attack_started(tool_name: StringName)
## Атака закончилась (анимация отыграна, можно атаковать снова).
signal attack_finished(tool_name: StringName)
## Здоровье изменилось.
signal health_changed(new_value: int, old_value: int)
## Игрок получил урон.
signal damaged(amount: int, new_health: int)
## Игрок умер.
signal died


# --- ССЫЛКИ НА КОМПОНЕНТЫ ---
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var input_handler: InputHandler = $InputHandler
@onready var movement_controller: MovementController = $MovementController
@onready var animation_controller: AnimationController = $AnimationController
@onready var health_component: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	# Выдаем компонентам ссылки друг на друга
	animation_controller.setup(anim_sprite)
	movement_controller.setup(self, input_handler)
	state_machine.setup(self, input_handler, movement_controller, animation_controller, health_component)
	state_machine.start()

	# Ввод -> движение / атака
	input_handler.jump_pressed.connect(movement_controller.on_jump_pressed)
	input_handler.jump_released.connect(movement_controller.on_jump_released)
	input_handler.attack_pressed.connect(_on_attack_pressed)

	# Здоровье -> состояние и визуал
	health_component.damaged.connect(state_machine.try_hurt)
	health_component.died.connect(state_machine.on_dead)
	health_component.invulnerability_changed.connect(animation_controller.set_invulnerable_visual)

	# Ре-эмит публичных сигналов здоровья
	health_component.health_changed.connect(health_changed.emit)
	health_component.damaged.connect(damaged.emit)
	health_component.died.connect(died.emit)


func _physics_process(delta: float) -> void:
	input_handler.poll()
	health_component.update(delta)
	state_machine.update(delta)
	movement_controller.update(delta, not health_component.is_dead)
	animation_controller.update(
		state_machine.current_state.name,
		movement_controller.facing,
		absf(movement_controller.velocity.x)
	)


## Обработчик нажатия атаки: пытаемся начать атаку текущим инструментом.
## Внешние системы (хотбар) устанавливают current_tool перед вызовом.
func _on_attack_pressed() -> void:
	state_machine.try_attack(current_tool)


# --- ПУБЛИЧНЫЙ API ---

## Текущий инструмент. Устанавливается внешней системой (хотбар).
## Используется при нажатии кнопки атаки и для вызова play_interact().
var current_tool: StringName = &"default"


## Начинает атаку выбранным инструментом. Удар и любая атака проигрывают
## единую анимацию "Взаимодействовать".
## @param tool_name - имя инструмента (любое StringName, без привязки к enum)
## @emits attack_started(tool_name), attack_finished(tool_name)
func play_attack(tool_name: StringName = current_tool) -> void:
	state_machine.try_attack(tool_name)


## Проигрывает анимацию "Взаимодействовать": добыча блока, установка
## блока/предмета и любая атака используют одну и ту же анимацию.
## Вызывается внешними системами (главная сцена при изменении блоков).
func play_interact() -> void:
	state_machine.try_attack(current_tool)


## Наносит игроку урон с учетом окна неуязвимости.
## @param amount - количество урона
## @emits health_changed(new, old), damaged(amount, new_health), died
func take_damage(amount: int) -> void:
	health_component.take_damage(amount)


## Обрабатывает смерть игрока.
## @emits died
func die() -> void:
	health_component.die()


## Полностью восстанавливает игрока и возвращает его из состояния смерти
## к движению. Используется возрождением и отладкой (PlayerDebug).
## @emits health_changed(max, old)
func revive() -> void:
	health_component.reset()
	state_machine.revive()


## Текущее здоровье (для HUD и внешних систем).
var health: int:
	get:
		return health_component.health