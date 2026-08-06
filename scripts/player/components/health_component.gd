class_name HealthComponent extends Node
## Здоровье игрока, окно неуязвимости и смерть. Чистая логика без визуала:
## анимации и мигание обрабатывает AnimationController через сигналы,
## переход в состояния - StateMachine.

## Здоровье изменилось.
signal health_changed(new_value: int, old_value: int)
## Игрок получил урон.
signal damaged(amount: int, new_health: int)
## Игрок умер.
signal died
## Окно неуязвимости началось или закончилось.
signal invulnerability_changed(is_invulnerable: bool)

# --- НАСТРОЙКИ БОЯ ---
@export_category("Combat")
## Максимальное здоровье.
@export var max_health: int = 100
## Время неуязвимости после получения урона, сек.
@export var invulnerability_time: float = 1.0

## Текущее здоровье.
var health: int = max_health
## Флажок смерти.
var is_dead: bool = false
## Активно ли окно неуязвимости.
var is_invulnerable: bool = false
## Оставшееся время неуязвимости, сек.
var invulnerability_timer: float = 0.0


## Возвращает здоровье к максимуму (старт игрока, возрождение).
## @emits health_changed(new, old), invulnerability_changed(false)
func reset() -> void:
	var old_health: int = health
	health = max_health
	is_dead = false
	is_invulnerable = false
	invulnerability_timer = 0.0
	health_changed.emit(health, old_health)
	invulnerability_changed.emit(false)


## Уменьшает таймер неуязвимости. Вызывается игроком каждый физический такт.
## @param delta - время такта, сек
func update(delta: float) -> void:
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false
			invulnerability_changed.emit(false)


## Наносит игроку урон с учётом окна неуязвимости.
## @param amount - количество урона
## @emits damaged(amount, new_health), health_changed(new, old), died
func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable:
		return
	var old_health: int = health
	health = maxi(health - amount, 0)
	health_changed.emit(health, old_health)
	# Сначала оповещаем об уроне (try_hurt -> HurtState): игрок должен отыграть
	# «боль» даже при летальном уроне. Только после этого обрабатываем смерть,
	# чтобы порядок всегда был: HurtState -> DeadState.
	damaged.emit(amount, health)
	if health <= 0:
		die()
		return
	is_invulnerable = true
	invulnerability_timer = invulnerability_time
	invulnerability_changed.emit(true)


## Обрабатывает смерть игрока.
func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()