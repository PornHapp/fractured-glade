class_name PlayerDebugUI extends CanvasLayer
## Дебаг-панель Игрока (UI-оверлей, dev-инструмент).
##
## Крупная панель в левом верхнем углу с живыми данными игрока:
##   - заголовок;
##   - HP-бар (ProgressBar) + числовое HP текущее/максимум;
##   - состояние (имя активного StateMachine-состояния);
##   - скорость (модуль горизонтальной скорости, px/с);
##   - неуязвимость (активно ли окно after получения урона);
##   - позиция игрока (локальные координаты мира);
##   - справку по командам: 8 - урон, 9 - летальный урон (смерть),
##     0 - восстановление/воскрешение.
##
## HP, состояние и неуязвимость обновляются по сигналам Игрока; скорость и
## позиция - каждый кадр. Интерфейс строится в коде, чтобы не плодить хрупкие
## .tscn. Шрифт - @assets/fonts/izax_sha_0.otf.

## Путь к шрифту панели.
const FONT_PATH: String = "res://assets/fonts/izax_sha_0.otf"
## Текст-справки по клавишам (в отдельной строке внизу).
const HELP_TEXT: String = "[8] урон · [9] смерть · [0] лечение/воскрешение"

## Цвета строк панели.
const COLOR_TITLE: Color = Color(0.95, 0.95, 0.95)
const COLOR_HP: Color = Color(0.5, 0.9, 0.5)
const COLOR_STATE: Color = Color(0.95, 0.8, 0.4)
const COLOR_SPEED: Color = Color(0.5, 0.8, 0.95)
const COLOR_POS: Color = Color(0.6, 0.7, 0.9)
const COLOR_HELP: Color = Color(0.75, 0.75, 0.75)

## Ссылки на лейблы панели.
var _hp_bar: ProgressBar = null
var _hp_label: Label = null
var _state_label: Label = null
var _speed_label: Label = null
var _invulnerable_label: Label = null
var _pos_label: Label = null

## Целевой игрок (задаётся через setup()).
var _player: Player = null


func _ready() -> void:
	_build_ui()


## Принимает ссылку на игрока, подключается к его сигналам. Вызывается главной
## сценой после создания игрока. Скрывает панель при сбое.
## @param player - узел Игрока
func setup(player: Player) -> void:
	if not player:
		push_warning("[PlayerDebugUI] игрок не получен - панель скрыта.")
		visible = false
		return
	_player = player
	_player.health_changed.connect(_on_health_changed)
	_player.state_machine.state_changed.connect(_on_state_changed)
	_player.health_component.invulnerability_changed.connect(_on_invulnerability_changed)
	# Заполняем начальные значения.
	_on_health_changed(player.health, player.health)
	_on_invulnerability_changed(player.health_component.is_invulnerable)
	_state_label.text = "Состояние: " + _player.state_machine.current_state.name


## Строит оверлей: крупная панель в левом верхнем углу.
func _build_ui() -> void:
	var font: Font = load(FONT_PATH)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(12, 12)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Заголовок.
	var title := _make_label(font, 30, COLOR_TITLE)
	title.text = "ДЕБАГ ИГРОКА"
	vbox.add_child(title)

	# --- Секция HP ---
	_hp_label = _make_label(font, 24, COLOR_HP)
	vbox.add_child(_hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(320, 26)
	_hp_bar.show_percentage = false
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	vbox.add_child(_hp_bar)

	# --- Состояние и скорость ---
	_state_label = _make_label(font, 24, COLOR_STATE)
	vbox.add_child(_state_label)

	_speed_label = _make_label(font, 24, COLOR_SPEED)
	vbox.add_child(_speed_label)

	_invulnerable_label = _make_label(font, 24, COLOR_POS)
	vbox.add_child(_invulnerable_label)

	_pos_label = _make_label(font, 22, COLOR_POS)
	vbox.add_child(_pos_label)

	# --- Справка ---
	var help := _make_label(font, 20, COLOR_HELP)
	help.text = HELP_TEXT
	vbox.add_child(help)


## Создаёт лейбл с общими настройками (шрифт, размер, цвет).
## @param font - шрифт из ресурса
## @param size - размер шрифта, px
## @param color - цвет текста
func _make_label(font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.text = "-"
	return label


## Обновляет HP-лейбл и HP-бар по сигналу health_changed.
## @param new_value - текущее здоровье
func _on_health_changed(new_value: int, _old_value: int = 0) -> void:
	_hp_label.text = "HP: %d / %d" % [new_value, _player.health_component.max_health]
	_hp_bar.max_value = _player.health_component.max_health
	_hp_bar.value = new_value


## Обновляет лейбл состояния по сигналу state_changed.
## @param state_name - имя нового состояния (StringName)
func _on_state_changed(state_name: StringName) -> void:
	_state_label.text = "Состояние: " + str(state_name)


## Обновляет статус неуязвимости по сигналу invulnerability_changed.
## @param is_invulnerable - активно ли окно неуязвимости
func _on_invulnerability_changed(is_invulnerable: bool) -> void:
	_invulnerable_label.text = "Неуязвимость: " + ("вкл" if is_invulnerable else "выкл")
	_invulnerable_label.add_theme_color_override(
		"font_color",
		Color(0.9, 0.5, 0.5) if is_invulnerable else COLOR_POS
	)


## Обновляет скорость и позицию каждый кадр.
func _process(_delta: float) -> void:
	if not _player:
		return
	var speed: float = absf(_player.movement_controller.velocity.x)
	_speed_label.text = "Скорость: %.0f px/с" % speed
	_pos_label.text = "Позиция: (%d, %d)" % [_player.position.x, _player.position.y]