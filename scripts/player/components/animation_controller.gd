class_name AnimationController extends Node
## Управляет анимациями игрока: выбор анимации по состоянию, зеркалирование
## спрайта по направлению взгляда и мигание при неуязвимости. Единственный
## модуль, который знает имена анимаций из SpriteFrames.

const ANIM_DEFAULT: StringName = &"default"
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_RUN: StringName = &"run"
const ANIM_JUMP: StringName = &"jump"
const ANIM_FALL: StringName = &"fall"
const ANIM_HURT: StringName = &"hurt"
## Анимация смерти (проигрывается один раз, кадр остаётся на последнем кадре).
const ANIM_DEAD: StringName = &"die"
## Единая анимация «Взаимодействовать»: добыча блоков, установка блоков/
## предметов и любая атака. Заменяет отдельные анимации удара под инструмент.
const ANIM_INTERACT: StringName = &"interact"

## true - исходник спрайта смотрит вправо (спека). Пока стоит старый плейсхолдер
## (смотрит влево), держим false, чтобы не зеркалить его. После прихода новых
## спрайтов переключить на true.
const SOURCE_FACES_RIGHT: bool = false

# --- НАСТРОЙКИ АНИМАЦИИ ---
@export_category("Animation")
## Модуль горизонтальной скорости, выше которой показывается анимация бега
## (run) вместо шага (walk), px/с. Держим выше базовой move_speed (150), чтобы
## ходьба walk была дефолтной; run включается лишь при ускорении внешними
## факторами (артефакты/дебаффы через speed_multiplier).
@export var run_animation_speed_threshold: float = 170.0

## Спрайт игрока (задаётся через setup()).
var anim_sprite: AnimatedSprite2D


## Привязывает спрайт игрока. Вызывается игроком в _ready().
func setup(sprite: AnimatedSprite2D) -> void:
	anim_sprite = sprite


## Обновляет зеркалирование и анимацию движения по текущему состоянию.
## Действия (атака/взаимодействие, урон, смерть) запускаются самими
## состояниями и здесь не перебиваются.
## @param state_name - имя узла текущего состояния (константы STATE_*)
## @param facing - направление взгляда: 1 или -1
## @param horizontal_speed - модуль горизонтальной скорости игрока, px/с
func update(state_name: StringName, facing: int, horizontal_speed: float) -> void:
	anim_sprite.flip_h = _should_flip(facing)
	match state_name:
		&"IdleState":
			play(ANIM_IDLE)
		&"RunState":
			if horizontal_speed >= run_animation_speed_threshold:
				play(ANIM_RUN)
			else:
				play(ANIM_WALK)
		&"JumpState":
			play(ANIM_JUMP)
		&"FallState":
			play(ANIM_FALL)


## Проигрывает единую анимацию «Взаимодействовать»: добыча блока,
## установка блока/предмета и любая атака используют одну эту анимацию.
func play_interact() -> void:
	play(ANIM_INTERACT)


## Проигрывает анимацию смерти. Вызывается DeadState при входе.
func play_dead() -> void:
	play(ANIM_DEAD)


## Включает/выключает мигание спрайта при неуязвимости.
## @param is_invulnerable - активно ли окно неуязвимости
func set_invulnerable_visual(is_invulnerable: bool) -> void:
	anim_sprite.modulate.a = 0.5 if is_invulnerable else 1.0


## Воспроизводит анимацию с фолбэком: запрошенная -> idle -> default.
## @param anim - имя анимации из контракта
func play(anim: StringName) -> void:
	var frames: SpriteFrames = anim_sprite.sprite_frames
	if not frames:
		return
	var target: StringName = anim
	if not frames.has_animation(target):
		target = ANIM_IDLE if frames.has_animation(ANIM_IDLE) else ANIM_DEFAULT
	if frames.has_animation(target) and anim_sprite.animation != target:
		anim_sprite.play(target)


## true, если спрайт нужно отзеркалить по горизонтали (зависит от конвенции исходника).
func _should_flip(facing: int) -> bool:
	if SOURCE_FACES_RIGHT:
		return facing < 0
	return facing > 0