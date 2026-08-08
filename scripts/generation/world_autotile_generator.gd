## Генератор мира с использованием автотайлинга Grass и Dirt.
## Создает процедурнуюterrain с пещерами и переходами между биомами.
class_name WorldAutotileGenerator
extends RefCounted

## Сигналы для уведомления о прогрессе генерации
signal generation_started
signal generation_progress(progress: float)
signal generation_completed

## Константы генерации
const TILE_SIZE: int = 8
const SOURCE_GRASS: int = 1
const SOURCE_DIRT: int = 2

## Atlas coordinates для тайлов
## Grass/Dirt.png layout:
##   [0,0] Full  [1,0] Top    [2,0] Full
##   [0,1] Left  [1,1] Empty  [2,1] Right
##   [0,2] Full  [1,2] Bottom [2,2] Full
const ATLAS_FULL: Vector2i = Vector2i(0, 0)
const ATLAS_TOP: Vector2i = Vector2i(1, 0)
const ATLAS_LEFT: Vector2i = Vector2i(0, 1)
const ATLAS_EMPTY: Vector2i = Vector2i(1, 1)
const ATLAS_RIGHT: Vector2i = Vector2i(2, 1)
const ATLAS_BOTTOM: Vector2i = Vector2i(1, 2)

## Параметры мира (передаются извне, не хардкодятся)
var world_width: int = 200
var world_height: int = 100
var surface_level: int = 30
var cave_frequency: float = 0.05
var cave_threshold: float = 0.4

## Ссылки на TileMapLayer
var dirt_layer: TileMapLayer
var grass_layer: TileMapLayer

## Генератор шума для пещер
var noise: FastNoiseLite


func _init(p_dirt: TileMapLayer, p_grass: TileMapLayer) -> void:
	dirt_layer = p_dirt
	grass_layer = p_grass
	_setup_noise()


## Настройка шума для генерации пещер
func _setup_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = cave_frequency
	noise.fractal_octaves = 4


## Основной метод генерации мира
func generate(seed_value: int = 0) -> void:
	generation_started.emit()

	if seed_value != 0:
		noise.seed = seed_value

	## Очищаем существующие тайлы
	dirt_layer.clear()
	grass_layer.clear()

	## Генерируем terrain
	_generate_terrain()

	generation_completed.emit()
	print("[WorldGen] Мир сгенерирован: %dx%d" % [world_width, world_height])


## Генерация основного terrain
func _generate_terrain() -> void:
	var total_tiles: int = world_width * world_height
	var processed: int = 0

	for x: int in range(world_width):
		for y: int in range(world_height):
			## Определяем, является ли тайл частью terrain
			if _is_terrain(x, y):
				_place_tile(x, y)

			## Обновляем прогресс
			processed += 1
			if processed % 1000 == 0:
				var progress: float = float(processed) / float(total_tiles)
				generation_progress.emit(progress)


## Определяет, должен ли тайл быть частью terrain
func _is_terrain(x: int, y: int) -> bool:
	## Поверхность и ниже - terrain
	if y >= surface_level:
		## Генерация пещер с помощью шума
		var cave_value: float = noise.get_noise_2d(float(x), float(y))
		## Пещеры только ниже поверхности
		if y > surface_level + 5 and cave_value > cave_threshold:
			return false
		return true
	return false


## Размещает тайл на карте
func _place_tile(x: int, y: int) -> void:
	## Определяем тип тайла на основе позиции
	if y == surface_level:
		## Поверхность - grass
		_place_grass_tile(x, y)
	elif y > surface_level:
		## Под землей - dirt
		_place_dirt_tile(x, y)


## Размещает тайл травы с учетом соседей
func _place_grass_tile(x: int, y: int) -> void:
	## Определяем atlas coordinates на основе соседей
	var atlas_coords: Vector2i = _get_grass_atlas_coords(x, y)
	grass_layer.set_cell(Vector2i(x, y), SOURCE_GRASS, atlas_coords, 0)


## Размещает тайл земли
func _place_dirt_tile(x: int, y: int) -> void:
	## Для dirt используем центральный тайл (пустой)
	## Autotile сам определит правильный вариант
	dirt_layer.set_cell(Vector2i(x, y), SOURCE_DIRT, Vector2i(1, 1), 0)


## Определяет atlas coordinates для grass тайла на основе соседей
func _get_grass_atlas_coords(x: int, y: int) -> Vector2i:
	var has_top: bool = _is_terrain(x, y - 1)
	var has_bottom: bool = _is_terrain(x, y + 1)
	var has_left: bool = _is_terrain(x - 1, y)
	var has_right: bool = _is_terrain(x + 1, y)

	## Полный блок (все соседи - terrain)
	if has_top and has_bottom and has_left and has_right:
		return ATLAS_FULL

	## Граничные случаи
	if not has_top:
		return ATLAS_TOP
	if not has_bottom:
		return ATLAS_BOTTOM
	if not has_left:
		return ATLAS_LEFT
	if not has_right:
		return ATLAS_RIGHT

	## По умолчанию - полный блок
	return ATLAS_FULL


## Устанавливает параметры мира
func set_world_params(width: int, height: int, surface: int) -> void:
	world_width = width
	world_height = height
	surface_level = surface


## Устанавливает параметры пещер
func set_cave_params(frequency: float, threshold: float) -> void:
	cave_frequency = frequency
	cave_threshold = threshold
	if noise:
		noise.frequency = frequency
