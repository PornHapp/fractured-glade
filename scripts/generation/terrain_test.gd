## Тестовый скрипт для проверки автотайлинга тайлсетов.
## Создает процедурный terrain и использует TerrainSet для автоматического выбора тайлов.
## Использует set_cells_terrain_connect() - правильный API для terrain autotile в Godot 4.
##
## - Установка/удаление блоков ЛКМ/ПКМ (как в main_game)
## - Разнообразная генерация мира (холмы, платформы, пещеры)
## - Дебаг-компоненты: PlayerDebugComponent + TerrainDebugComponent
extends Node2D

## Ссылки на TileMapLayer узлы - расширяемый словарь terrain -> layer
## Ключ: terrain index (int), Значение: TileMapLayer
var terrain_layers: Dictionary = {}

## Константы по умолчанию (переопределяются через set_terrain_config)
var default_surface_y: int = 15
var area_width: int = 120
var area_height: int = 40
var area_offset_x: int = -40
var area_offset_y: int = -10

## Блоки: 0 = трава, 1 = земля
var selected_block: int = 0

## Ссылка на игрока
var player: Player = null

## Флаг нажатия мыши для непрерывной установки блоков
var _is_mouse_pressed: bool = false
var _mouse_button_index: int = -1


func _ready() -> void:
	_discover_layers()
	print("[TerrainTest] Слоёв: %d, ключи: %s" % [terrain_layers.size(), str(terrain_layers.keys())])
	_setup_terrain()
	for terrain_idx: int in terrain_layers:
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		print("[TerrainTest] %s: used_cells=%d" % [layer.name, layer.get_used_cells().size()])
	_position_player()
	$PlayerDebugComponent.set_player(player)
	$TerrainDebugComponent.set_terrain_data(terrain_layers)
	$TerrainDebugComponent.refresh_stats()


## Автоматически находит TileMapLayer узлы и маппит их на terrain index
func _discover_layers() -> void:
	for child: Node in get_children():
		if child is TileMapLayer:
			var layer: TileMapLayer = child as TileMapLayer
			## Имя узла определяет terrain index:
			## "GrassLayer" -> terrain 0, "DirtLayer" -> terrain 1
			var terrain_idx: int = _terrain_index_from_name(child.name)
			terrain_layers[terrain_idx] = layer


## Конвертирует имя слоя в terrain index
## "GrassLayer" -> 0, "DirtLayer" -> 1, "StoneLayer" -> 2
func _terrain_index_from_name(node_name: String) -> int:
	var name_lower: String = node_name.to_lower()
	if "grass" in name_lower:
		return 0
	elif "dirt" in name_lower:
		return 1
	elif "stone" in name_lower:
		return 2
	elif "sand" in name_lower:
		return 3
	## Fallback: используем порядок в дереве
	return 0


## Создает разнообразный terrain: холмы, платформы, пещеры.
## Собирает ячейки по типам terrain и вызывает set_cells_terrain_connect().
func _setup_terrain() -> void:
	## Массивы ячеек по terrain index
	var terrain_cells: Dictionary = {}
	for terrain_idx: int in terrain_layers:
		terrain_cells[terrain_idx] = []

	## Процедурная генерация высоты поверхности (холмы)
	var surface_heights: Dictionary = {}  # x -> surface_y
	for x: int in range(area_offset_x, area_offset_x + area_width):
		## Суммируем несколько синусоид для разнообразия
		var base: float = default_surface_y
		var hill1: float = sin(x * 0.08) * 4.0
		var hill2: float = sin(x * 0.15 + 1.5) * 2.0
		var hill3: float = sin(x * 0.03) * 5.0
		var hill4: float = sin(x * 0.22 + 3.0) * 1.0
		surface_heights[x] = int(base + hill1 + hill2 + hill3 + hill4)

	## Заполняем область - собираем ячейки по terrain типам
	for x: int in range(area_offset_x, area_offset_x + area_width):
		var surf_y: int = surface_heights[x]
		for y: int in range(area_offset_y, area_offset_y + area_height):
			if y < surf_y:
				continue
			elif y == surf_y:
				## Поверхность - terrain 0 (grass)
				terrain_cells[0].append(Vector2i(x, y))
			elif y < surf_y + 5:
				## Неглубоко под землей - terrain 1 (dirt)
				terrain_cells[1].append(Vector2i(x, y))
			else:
				## Глубоко - тоже dirt, но с «пещерами»
				var cave_noise: float = sin(x * 0.25 + y * 0.18) * cos(x * 0.12 - y * 0.12)
				var cave_noise2: float = sin(x * 0.15 + y * 0.25) * cos(x * 0.2 - y * 0.1)
				if (cave_noise + cave_noise2) > 0.8:
					continue  ## Пустота (пещера)
				terrain_cells[1].append(Vector2i(x, y))

	## Добавляем floating платформы из grass
	_add_platforms(terrain_cells, surface_heights)

	## Вызываем set_cells_terrain_connect для каждого слоя
	for terrain_idx: int in terrain_cells:
		var cells: Array = terrain_cells[terrain_idx]
		if cells.size() == 0:
			continue
		if terrain_idx not in terrain_layers:
			print("[TerrainTest] WARN: terrain %d not in layers, skipping %d cells" % [terrain_idx, cells.size()])
			continue
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		## terrain_set=0, terrain_index=terrain_idx
		layer.set_cells_terrain_connect(cells, 0, terrain_idx)

	## Обновляем автотайлинг для всех слоёв
	for terrain_idx: int in terrain_layers:
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		layer.update_internals()

	## Настраиваем физику TileSet (collision polygons на ВСЕХ тайлах)
	_ensure_tileset_physics()

	## Диагностика физики
	for terrain_idx: int in terrain_layers:
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		var ts: TileSet = layer.tile_set
		if ts:
			print("[TerrainTest] %s: physics_layers=%d" % [layer.name, ts.get_physics_layers_count()])
			if ts.get_physics_layers_count() > 0:
				print("[TerrainTest] %s: collision_layer=%d, collision_mask=%d" % [
					layer.name,
					ts.get_physics_layer_collision_layer(0),
					ts.get_physics_layer_collision_mask(0)
				])


## Добавляет floating-платформы из grass над поверхностью.
## Y каждой платформы вычисляется от реальной высоты surface_heights[x],
## чтобы платформы не оказались внутри холмов.
func _add_platforms(terrain_cells: Dictionary, surface_heights: Dictionary) -> void:
	## Платформа слева - над минимальной высотой поверхности в этом диапазоне
	var left_min: int = _min_surface(surface_heights, area_offset_x + 8, area_offset_x + 18)
	var plat_y1: int = left_min - 6
	for x: int in range(area_offset_x + 8, area_offset_x + 18):
		terrain_cells[0].append(Vector2i(x, plat_y1))

	## Платформа справа
	var right_min: int = _min_surface(surface_heights, area_offset_x + 70, area_offset_x + 90)
	var plat_y2: int = right_min - 8
	for x: int in range(area_offset_x + 70, area_offset_x + 90):
		terrain_cells[0].append(Vector2i(x, plat_y2))

	## Маленькая платформа по центру
	var center_min: int = _min_surface(surface_heights, area_offset_x + 45, area_offset_x + 55)
	var plat_y3: int = center_min - 5
	for x: int in range(area_offset_x + 45, area_offset_x + 55):
		terrain_cells[0].append(Vector2i(x, plat_y3))

	## Ступеньки слева
	for i: int in range(5):
		var step_x: int = area_offset_x + 25 + i * 4
		var step_min: int = _min_surface(surface_heights, step_x, step_x + 4)
		var step_y: int = step_min - 4 - i * 2
		for dx: int in range(4):
			terrain_cells[0].append(Vector2i(step_x + dx, step_y))

	## «Лестница» справа
	for i: int in range(4):
		var stair_x: int = area_offset_x + 55 + i * 5
		var stair_min: int = _min_surface(surface_heights, stair_x, stair_x + 5)
		var stair_y: int = stair_min - 5 - i * 3
		for dx: int in range(5):
			terrain_cells[0].append(Vector2i(stair_x + dx, stair_y))

	## Дополнительные платформы для разнообразия
	var plat4_min: int = _min_surface(surface_heights, area_offset_x + 30, area_offset_x + 38)
	var plat_y4: int = plat4_min - 10
	for x: int in range(area_offset_x + 30, area_offset_x + 38):
		terrain_cells[0].append(Vector2i(x, plat_y4))

	var plat5_min: int = _min_surface(surface_heights, area_offset_x + 60, area_offset_x + 65)
	var plat_y5: int = plat5_min - 12
	for x: int in range(area_offset_x + 60, area_offset_x + 65):
		terrain_cells[0].append(Vector2i(x, plat_y5))


## Возвращает минимальную высоту поверхности в диапазоне [x_from, x_to).
func _min_surface(surface_heights: Dictionary, x_from: int, x_to: int) -> int:
	var result: int = default_surface_y
	for x: int in range(x_from, x_to):
		if surface_heights.has(x) and surface_heights[x] < result:
			result = surface_heights[x]
	return result


## Настраивает физику TileSet: добавляет collision polygons ко всем тайлам.
## Обходит атлас перебором координат (get_used_cells ненадёжен в 4.7).
## ВАЖНО: Удаляет старые коллайдеры и добавляет новые для всех тайлов!
func _ensure_tileset_physics() -> void:
	## Берём TileSet из первого слоя (все слои делят один TileSet)
	if terrain_layers.size() == 0:
		return
	var first_layer: TileMapLayer = terrain_layers.values()[0] as TileMapLayer
	var ts: TileSet = first_layer.tile_set
	if not ts:
		return

	## Гарантируем physics layer
	if ts.get_physics_layers_count() == 0:
		ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  ## terrain = layer 1
	ts.set_physics_layer_collision_mask(0, 2)   ## player on layer 2

	## Полигон центрирован на тайле (8x8): от (-4,-4) до (4,4)
	var polygon: PackedVector2Array = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)
	])
	var total_fixed: int = 0

	for source_idx: int in ts.get_source_count():
		var source_id: int = ts.get_source_id(source_idx)
		var source: TileSetSource = ts.get_source(source_id)
		if not (source is TileSetAtlasSource):
			continue
		var atlas: TileSetAtlasSource = source as TileSetAtlasSource
		var fixed: int = 0

		## Перебираем координаты сетки атласа (макс 16x16 - более чем достаточно)
		for x: int in range(16):
			for y: int in range(16):
				var tile_id: Vector2i = Vector2i(x, y)
				## Безопасно: сначала проверяем existence через has_tile
				if not atlas.has_tile(tile_id):
					continue
				var td: TileData = atlas.get_tile_data(tile_id, 0)

				## Удаляем ВСЕ старые коллайдеры (если есть)
				while td.get_collision_polygons_count(0) > 0:
					td.remove_collision_polygon(0, 0)

				## Добавляем новый коллайдер
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, polygon)
				fixed += 1

		total_fixed += fixed
		print("[TerrainTest] source %d: %d tiles fixed" % [source_id, fixed])

	print("[TerrainTest] Физика: всего %d tiles исправлено" % total_fixed)


## Позиционирует игрока на поверхности terrain
func _position_player() -> void:
	for child: Node in get_children():
		if child is CharacterBody2D:
			player = child as CharacterBody2D
			var center_x: int = area_offset_x + floori(area_width / 2.0)
			## Прямой расчёт позиции: поверхность на default_surface_y,
			## ставим игрока на 3 тайла выше (с запасом для тела персонажа)
			var player_y: float = (default_surface_y - 4) * 8.0
			player.position = Vector2(center_x * 8.0 + 4.0, player_y)
			print("[TerrainTest] Player positioned at: %s (surface_y=%d)" % [
				str(player.position), default_surface_y
			])


## Публичный API для настройки извне
func set_surface_y(value: int) -> void:
	default_surface_y = value


func set_area(width: int, height: int, offset_x: int = -2, offset_y: int = -2) -> void:
	area_width = width
	area_height = height
	area_offset_x = offset_x
	area_offset_y = offset_y


## Обработка ввода: установка/удаление блоков + выбор блока
func _unhandled_input(event: InputEvent) -> void:
	if not player:
		return

	## Мёртвый игрок не обрабатывает блоки и выбор
	if player.is_dead:
		return

	## Выбор блока клавишами 1/2
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				selected_block = 0
				print("[TerrainTest] Выбран блок: Трава")
			KEY_2:
				selected_block = 1
				print("[TerrainTest] Выбран блок: Земля")

	## ЛКМ - поставить блок
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_mouse_pressed = event.pressed
		_mouse_button_index = MOUSE_BUTTON_LEFT if event.pressed else -1
		if event.pressed:
			var tile_pos := _get_mouse_tile()
			if tile_pos.x >= 0:
				_place_block(tile_pos.x, tile_pos.y, selected_block)

	## ПКМ - убрать блок
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_is_mouse_pressed = event.pressed
		_mouse_button_index = MOUSE_BUTTON_RIGHT if event.pressed else -1
		if event.pressed:
			var tile_pos := _get_mouse_tile()
			if tile_pos.x >= 0:
				_remove_block(tile_pos.x, tile_pos.y)


func _process(_delta: float) -> void:
	## Непрерывная установка/удаление блоков при зажатии мыши
	if _is_mouse_pressed and player and not player.is_dead:
		var tile_pos := _get_mouse_tile()
		if tile_pos.x >= 0:
			if _mouse_button_index == MOUSE_BUTTON_LEFT:
				_place_block(tile_pos.x, tile_pos.y, selected_block)
			elif _mouse_button_index == MOUSE_BUTTON_RIGHT:
				_remove_block(tile_pos.x, tile_pos.y)


## Конвертирует позицию мыши в координаты тайла
func _get_mouse_tile() -> Vector2i:
	if not player:
		return Vector2i(-1, -1)
	var cam := player.get_node_or_null("Camera2D")
	if not cam:
		return Vector2i(-1, -1)
	var mouse_pos: Vector2 = cam.get_global_mouse_position()
	var tile_x: int = floori(mouse_pos.x / 8.0)
	var tile_y: int = floori(mouse_pos.y / 8.0)
	return Vector2i(tile_x, tile_y)


## Ставит блок указанного типа в world-координатах тайла
func _place_block(tile_x: int, tile_y: int, block_type: int) -> void:
	## Проверяем, не стоит ли игрок на этом тайле
	if player:
		var player_tile := Vector2i(floori(player.position.x / 8.0), floori(player.position.y / 8.0))
		if tile_x == player_tile.x and tile_y == player_tile.y:
			return
		## Проверяем тело игрока (примерный хитбокс)
		var pr := Rect2(player.position.x - 7, player.position.y - 17, 14, 17)
		if pr.intersects(Rect2(tile_x * 8, tile_y * 8, 8, 8)):
			return

	## Проверяем, есть ли уже блок в этой позиции (в ЛЮБОМ слое)
	for terrain_idx: int in terrain_layers:
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		if layer.get_cell_atlas_coords(Vector2i(tile_x, tile_y)) != Vector2i(-1, -1):
			return  ## Блок уже есть, не ставим

	## Поворачиваем игрока к цели и запускаем анимацию
	player.face_toward(Vector2(tile_x * 8.0 + 4.0, tile_y * 8.0 + 4.0))
	player.play_interact()

	## Определяем terrain_index по типу блока
	## block_type: 0 = grass (terrain 0), 1 = dirt (terrain 1)
	var terrain_idx: int = block_type

	## Устанавливаем блок через set_cells_terrain_connect
	if terrain_idx in terrain_layers:
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		layer.set_cells_terrain_connect([Vector2i(tile_x, tile_y)], 0, terrain_idx)
		layer.update_internals()

	## Обновляем автотайлинг соседних блоков (8 направлений)
	_update_autotile_neighbors(Vector2i(tile_x, tile_y))
	$TerrainDebugComponent.refresh_stats()


## Удаляет блок в world-координатах тайла
func _remove_block(tile_x: int, tile_y: int) -> void:
	## Поворачиваем игрока к цели и запускаем анимацию
	if player:
		player.face_toward(Vector2(tile_x * 8.0 + 4.0, tile_y * 8.0 + 4.0))
		player.play_interact()

	## Удаляем блок из ВСЕХ слоёв terrain
	for terrain_idx: int in terrain_layers:
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		layer.set_cell(Vector2i(tile_x, tile_y), -1)
		layer.update_internals()

	## Обновляем автотайлинг соседних блоков (8 направлений)
	_update_autotile_neighbors(Vector2i(tile_x, tile_y))
	$TerrainDebugComponent.refresh_stats()


## Обновляет автотайлинг для 8 соседей заданной позиции.
## Собирает соседей по terrain-слоям и пересчитывает пиринговые биты.
func _update_autotile_neighbors(cell: Vector2i) -> void:
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	]

	## Собираем соседей по terrain-индексу
	var neighbors_by_terrain: Dictionary = {}
	for terrain_idx: int in terrain_layers:
		neighbors_by_terrain[terrain_idx] = []

	for offset: Vector2i in offsets:
		var neighbor: Vector2i = cell + offset
		## Определяем, в каком terrain-слое находится сосед
		for terrain_idx: int in terrain_layers:
			var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
			if layer.get_cell_atlas_coords(neighbor) != Vector2i(-1, -1):
				(neighbors_by_terrain[terrain_idx] as Array).append(neighbor)
				break

	## Пересчитываем автотайлинг для каждого terrain-слоя
	for terrain_idx: int in neighbors_by_terrain:
		var cells: Array = neighbors_by_terrain[terrain_idx] as Array
		if cells.is_empty():
			continue
		var layer: TileMapLayer = terrain_layers[terrain_idx] as TileMapLayer
		layer.set_cells_terrain_connect(cells, 0, terrain_idx, true)
		layer.update_internals()
