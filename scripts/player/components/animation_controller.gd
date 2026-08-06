class_name AnimationController extends Node
## Управляет анимациями игрока: выбор анимации по текущему состоянию,
## зеркалирование спрайта по направлению взгляда и мигание при
## неуязвимости.
##
## Принцип: все анимации в SpriteFrames — одни на оба направления
## (левый исходник). Направление задаётся через flip_h у AnimatedSprite2D.
## Контроллер сам ставит flip_h = true при взгляде вправо.


# --- ИМЕНА АНИМАЦИЙ (совпадают с именами в SpriteFrames) ---
const ANIM_IDLE: StringName = &"idle"
const ANIM_RUN: StringName = &"run"
const ANIM_JUMP: StringName = &"jump"
const ANIM_FALL: StringName = &"fall"
const ANIM_DIE: StringName = &"die"
const ANIM_HURT: StringName = &"hurt"
## Единая анимация «Взаимодействовать»: добыча блоков, установка блоков/
## предметов и любая атака — всё одну анимацию.
const ANIM_INTERACT: StringName = &"interact"


# --- НАСТРОЙКИ ---
@export_category("Animation")
## Модуль горизонтальной скорости, выше которой показывается анимация бега
## (run) вместо покоя (idle), px/с. Базовая move_speed = 150, поэтому
## при стандартных настройках всегда idle. Run включается при ускорении
## внешними факторами (артефакты, дебаффы через speed_multiplier).
@export var run_speed_threshold: float = 170.0

## Спрайт игрока (задаётся через setup()).
var _sprite: AnimatedSprite2D


## Привязывает спрайт игрока. Вызывается игроком в _ready().
## @param sprite - AnimatedSprite2D из сцены игрока
func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite


## Главный метод обновления. Вызывается каждым физическим тактом из Player.
## Определяет анимацию по имени текущего состояния и ставит flip_h
## по направлению взгляда. Не перебивает анимации действий (атака,
## урон, смерть) — они запускаются самими состояниями.
##
## @param state_name - имя узла состояния (IdleState, RunState и т.д.)
## @param facing - направление взгляда: 1 = вправо, -1 = влево
## @param horizontal_speed - модуль горизонтальной скорости, px/с
func update(state_name: StringName, facing: int, horizontal_speed: float) -> void:
	match state_name:
		&"IdleState":
			_play_with_flip(ANIM_IDLE, facing)
		&"RunState":
			if horizontal_speed >= run_speed_threshold:
				_play_with_flip(ANIM_RUN, facing)
			else:
				_play_with_flip(ANIM_IDLE, facing)
		&"JumpState":
			_play_with_flip(ANIM_JUMP, facing)
		&"FallState":
			_play_with_flip(ANIM_FALL, facing)


## Проигрывает анимацию взаимодействия (атака, добыча, установка блока).
func play_interact() -> void:
	_play_with_flip(ANIM_INTERACT, _get_facing())


## Проигрывает анимацию получения урона. Вызывается HurtState и DeadState.
func play_hurt() -> void:
	_play_with_flip(ANIM_HURT, _get_facing())


## Проигрывает анимацию смерти. Вызывается DeadState при входе.
func play_dead() -> void:
	_play_with_flip(ANIM_DIE, _get_facing())


## Универсальный метод проигрывания анимации по имени.
## Фолбэк: запрошенная -> idle -> default.
## @param anim - имя анимации из SpriteFrames
func play(anim: StringName) -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if not frames:
		return
	var target: StringName = anim
	if not frames.has_animation(target):
		target = ANIM_IDLE if frames.has_animation(ANIM_IDLE) else &"default"
	if frames.has_animation(target) and _sprite.animation != target:
		_sprite.play(target)


## Включает/выключает мигание спрайта при неуязвимости.
## @param is_invulnerable - активно ли окно неуязвимости
func set_invulnerable_visual(is_invulnerable: bool) -> void:
	_sprite.modulate.a = 0.5 if is_invulnerable else 1.0


# --- ВНУТРЕННИЕ МЕТОДЫ ---

## Проигрывает анимацию и ставит flip_h по направлению взгляда.
## Исходник спрайта смотрит влево → при facing > 0 (вправо) flip_h = true.
##
## @param anim - имя анимации
## @param facing - направление: 1 = вправо, -1 = влево
func _play_with_flip(anim: StringName, facing: int) -> void:
	_sprite.flip_h = facing > 0
	if _sprite.animation != anim:
		_sprite.play(anim)


## Возвращает текущее направление взгляда из MovementController.
## Нужен для play_interact(), play_hurt() и play_dead(), которые
## вызываются из состояний без прямого доступа к facing.
func _get_facing() -> int:
	if owner and "movement_controller" in owner:
		return owner.movement_controller.facing
	return 1
