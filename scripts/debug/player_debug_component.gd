class_name PlayerDebugComponent extends CanvasLayer
## Дебаг-компонента игрока (inline, dev-инструмент).
##
## Самодостаточный компонент: строит UI программно, подключается к сигналам
## игрока и обрабатывает дебаг-клавиши (8/9/0). Живёт как дочерний узел
## на игровой сцене - не требует отдельной .tscn.
##
## Использование:
##   1. Добавить как дочерний CanvasLayer на сцену
##   2. Вывать set_player(player) после создания игрока
##   3. Настроить @export-переменные в инспекторе

## --- Настройка отображения ---
@export_category("Отображение")
## Показывать HP-бар и числовое HP.
@export var show_hp: bool = true
## Показывать текущее состояние (имя из StateMachine).
@export var show_state: bool = true
## Показывать скорость.
@export var show_speed: bool = true
## Показывать позицию.
@export var show_position: bool = true

## --- Дебаг-ключи ---
@export_category("Дебаг-ключи")
## Включить обработку клавиш 8/9/0.
@export var enable_debug_keys: bool = true
## Клавиша урона.
@export var damage_key: int = KEY_8
## Клавиша летального урона.
@export var kill_key: int = KEY_9
## Клавиша лечения/воскрешения.
@export var heal_key: int = KEY_0
## Урон по клавише урона.
@export var debug_damage: int = 20
## Летальный урон.
@export var debug_lethal_damage: int = 9999

## --- Визуал ---
@export_category("Визуал")
## Отступ панели от края viewport.
@export var panel_offset: Vector2 = Vector2(12, 12)
## Путь к шрифту.
@export var font_path: String = "res://assets/fonts/izax_sha_0.otf"
## Размер шрифта заголовка.
@export var font_size_title: int = 30
## Размер шрифта HP.
@export var font_size_hp: int = 24
## Размер шрифта состояния.
@export var font_size_state: int = 24
## Размер шрифта скорости.
@export var font_size_speed: int = 24
## Размер шрифта позиции.
@export var font_size_pos: int = 22
## Размер шрифта справки.
@export var font_size_help: int = 20

## --- Цвета ---
@export_category("Цвета")
@export var color_title: Color = Color(0.95, 0.95, 0.95)
@export var color_hp: Color = Color(0.5, 0.9, 0.5)
@export var color_state: Color = Color(0.95, 0.8, 0.4)
@export var color_speed: Color = Color(0.5, 0.8, 0.95)
@export var color_pos: Color = Color(0.6, 0.7, 0.9)
@export var color_help: Color = Color(0.75, 0.75, 0.75)
@export var color_invulnerable: Color = Color(0.9, 0.5, 0.5)

## --- Внутренние ссылки ---
var _player: Player = null
var _panel: PanelContainer = null
var _hp_label: Label = null
var _hp_bar: ProgressBar = null
var _state_label: Label = null
var _speed_label: Label = null
var _invulnerable_label: Label = null
var _pos_label: Label = null


func _ready() -> void:
	_build_ui()
	visible = false


## Принимает ссылку на игрока, подключается к сигналам.
## Вызывается родительской сценой после создания игрока.
func set_player(player: Player) -> void:
	if not player:
		push_warning("[PlayerDebugComponent] Игрок не передан - панель скрыта.")
		return
	_disconnect_current()
	_player = player
	_player.health_changed.connect(_on_health_changed)
	_player.state_machine.state_changed.connect(_on_state_changed)
	_player.health_component.invulnerability_changed.connect(_on_invulnerability_changed)
	_on_health_changed(_player.health, _player.health)
	_on_invulnerability_changed(_player.health_component.is_invulnerable)
	if _state_label:
		_state_label.text = "Состояние: " + str(_player.state_machine.current_state.name)
	visible = true


## --- UI ---

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DebugPanel"
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 0.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.position = panel_offset

	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.85)
	bg.border_width_top = 2
	bg.border_width_bottom = 2
	bg.border_width_left = 2
	bg.border_width_right = 2
	bg.border_color = Color(0.3, 0.3, 0.4, 0.6)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	bg.content_margin_left = 14.0
	bg.content_margin_top = 10.0
	bg.content_margin_right = 14.0
	bg.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var font: Font = load(font_path) if ResourceLoader.exists(font_path) else null

	## Заголовок
	_apply_label_style(_add_label(vbox, "ДЕБАГ ИГРОКА"), font, font_size_title, color_title)

	## HP
	if show_hp:
		_hp_label = _add_label(vbox, "HP: 100 / 100")
		_apply_label_style(_hp_label, font, font_size_hp, color_hp)
		_hp_bar = ProgressBar.new()
		_hp_bar.custom_minimum_size = Vector2(320, 26)
		_hp_bar.show_percentage = false
		_hp_bar.max_value = 100.0
		_hp_bar.value = 100.0
		vbox.add_child(_hp_bar)

	## Состояние
	if show_state:
		_state_label = _add_label(vbox, "Состояние: Idle")
		_apply_label_style(_state_label, font, font_size_state, color_state)

	## Неуязвимость
	_invulnerable_label = _add_label(vbox, "Неуязвимость: выкл")
	_apply_label_style(_invulnerable_label, font, font_size_state, color_pos)

	## Скорость
	if show_speed:
		_speed_label = _add_label(vbox, "Скорость: 0 px/с")
		_apply_label_style(_speed_label, font, font_size_speed, color_speed)

	## Позиция
	if show_position:
		_pos_label = _add_label(vbox, "Позиция: (0, 0)")
		_apply_label_style(_pos_label, font, font_size_pos, color_pos)

	## Справка
	var help_text: String = ""
	if enable_debug_keys:
		help_text = "[8] урон · [9] смерть · [0] лечение/воскрешение"
	var help_label: Label = _add_label(vbox, help_text)
	_apply_label_style(help_label, font, font_size_help, color_help)


func _add_label(parent: Control, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	parent.add_child(label)
	return label


func _apply_label_style(label: Label, font: Font, size: int, color: Color) -> void:
	if not label:
		return
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


## --- Сигналы игрока ---

func _on_health_changed(new_value: int, _old_value: int = 0) -> void:
	if _hp_label and _player:
		_hp_label.text = "HP: %d / %d" % [new_value, _player.health_component.max_health]
	if _hp_bar and _player:
		_hp_bar.max_value = _player.health_component.max_health
		_hp_bar.value = new_value


func _on_state_changed(state_name: StringName) -> void:
	if _state_label:
		_state_label.text = "Состояние: " + str(state_name)


func _on_invulnerability_changed(is_invulnerable: bool) -> void:
	if _invulnerable_label:
		_invulnerable_label.text = "Неуязвимость: " + ("вкл" if is_invulnerable else "выкл")
		_invulnerable_label.add_theme_color_override(
			"font_color",
			color_invulnerable if is_invulnerable else color_pos
		)


## --- Обновление каждый кадр ---

func _process(_delta: float) -> void:
	if not _player:
		return
	if _speed_label:
		var speed: float = absf(_player.movement_controller.velocity.x)
		_speed_label.text = "Скорость: %.0f px/с" % speed
	if _pos_label:
		_pos_label.text = "Позиция: (%d, %d)" % [_player.position.x, _player.position.y]


## --- Дебаг-ключи ---

func _unhandled_input(event: InputEvent) -> void:
	if not enable_debug_keys or not _player:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		damage_key:
			_player.take_damage(debug_damage)
		kill_key:
			_player.take_damage(debug_lethal_damage)
		heal_key:
			_player.revive()


## --- Очистка ---

func _disconnect_current() -> void:
	if not _player:
		return
	if _player.health_changed.is_connected(_on_health_changed):
		_player.health_changed.disconnect(_on_health_changed)
	if _player.state_machine.state_changed.is_connected(_on_state_changed):
		_player.state_machine.state_changed.disconnect(_on_state_changed)
	if _player.health_component.invulnerability_changed.is_connected(_on_invulnerability_changed):
		_player.health_component.invulnerability_changed.disconnect(_on_invulnerability_changed)
