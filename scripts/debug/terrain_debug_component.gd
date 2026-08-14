class_name TerrainDebugComponent extends CanvasLayer
## Дебаг-компонента terrain (inline, dev-инструмент).
##
## Самодостаточный компонент: строит UI программно, отображает FPS,
## количество ячеек по terrain-слоям, позицию игрока. Живет как
## дочерний узел на сцене - не требует отдельной .tscn.
##
## Использование:
##   1. Добавить как дочерний CanvasLayer на сцену
##   2. Вызывать set_terrain_data(terrain_layers) из родителя
##   3. Вызывать refresh_stats() при изменении блоков

## --- Настройка отображения ---
@export_category("Отображение")
## Показывать FPS.
@export var show_fps: bool = true
## Показывать количество ячеек по слоям.
@export var show_cell_counts: bool = true
## Показывать позицию игрока.
@export var show_player_pos: bool = false
## Текст справки внизу панели.
@export var help_text: String = "[1] трава · [2] земля · ЛКМ поставить · ПКМ убрать"

## --- Визуал ---
@export_category("Визуал")
## Путь к шрифту.
@export var font_path: String = "res://assets/fonts/izax_sha_0.otf"
## Размер шрифта заголовка.
@export var font_size_title: int = 30
## Размер шрифта данных.
@export var font_size_info: int = 24
## Размер шрифта статистики.
@export var font_size_stats: int = 22
## Размер шрифта справки.
@export var font_size_help: int = 20
## Интервал обновления FPS (секунды).
@export var fps_update_interval: float = 0.5

## --- Цвета ---
@export_category("Цвета")
@export var color_title: Color = Color(0.95, 0.95, 0.95)
@export var color_info: Color = Color(0.5, 0.9, 0.5)
@export var color_stats: Color = Color(0.5, 0.8, 0.95)
@export var color_help: Color = Color(0.75, 0.75, 0.75)

## --- Внутренние ссылки ---
var _panel: PanelContainer = null
var _fps_label: Label = null
var _cells_label: Label = null
var _player_pos_label: Label = null
var _terrain_layers: Dictionary = {}
var _player: CharacterBody2D = null
var _fps_timer: float = 0.0

## Названия terrain-слоев по индексу (для отображения).
var _terrain_names: Dictionary = {
	0: "Трава",
	1: "Земля",
	2: "Камень",
	3: "Песок",
}


func _ready() -> void:
	_build_ui()
	_player = _find_player()
	visible = false


## Передает данные о terrain-слоях из родительского скрипта.
## @param terrain_layers - Dictionary {terrain_index: TileMapLayer}
func set_terrain_data(terrain_layers: Dictionary) -> void:
	_terrain_layers = terrain_layers
	visible = true
	refresh_stats()


## Принудительно обновляет статистику ячеек.
## Вызывается родителем при изменении блоков.
func refresh_stats() -> void:
	if _terrain_layers.is_empty() or not _cells_label:
		return
	var parts: PackedStringArray = []
	for terrain_idx: int in _terrain_layers:
		var tilemap_layer: TileMapLayer = _terrain_layers[terrain_idx] as TileMapLayer
		if not tilemap_layer:
			continue
		var count: int = tilemap_layer.get_used_cells().size()
		var layer_name: String = _terrain_names.get(terrain_idx, "Terrain %d" % terrain_idx)
		parts.append("%s: %d" % [layer_name, count])
	_cells_label.text = " | ".join(parts)


## --- UI ---

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DebugPanel"
	_panel.anchor_left = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.position = Vector2(-370, 12)

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
	_apply_label_style(_add_label(vbox, "ДЕБАГ TERRAIN"), font, font_size_title, color_title)

	## FPS
	if show_fps:
		_fps_label = _add_label(vbox, "FPS: 0")
		_apply_label_style(_fps_label, font, font_size_info, color_info)

	## Статистика ячеек
	if show_cell_counts:
		_cells_label = _add_label(vbox, "")
		_apply_label_style(_cells_label, font, font_size_stats, color_stats)

	## Позиция игрока
	if show_player_pos:
		_player_pos_label = _add_label(vbox, "Игрок: (0, 0)")
		_apply_label_style(_player_pos_label, font, font_size_stats, color_stats)

	## Справка
	_apply_label_style(_add_label(vbox, help_text), font, font_size_help, color_help)


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


## --- Поиск игрока ---

func _find_player() -> CharacterBody2D:
	var parent: Node = get_parent()
	if not parent:
		return null
	for child: Node in parent.get_children():
		if child is CharacterBody2D:
			return child as CharacterBody2D
	return null


## --- Обновление каждый кадр ---

func _process(delta: float) -> void:
	## FPS
	if _fps_label and show_fps:
		_fps_timer += delta
		if _fps_timer >= fps_update_interval:
			_fps_timer = 0.0
			_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	## Позиция игрока
	if _player_pos_label and show_player_pos and _player:
		_player_pos_label.text = "Игрок: (%d, %d)" % [_player.position.x, _player.position.y]
