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

## Индексы terrain в TerrainSet
const TERRAIN_GRASS: int = 0
const TERRAIN_DIRT: int = 1

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


## Размещает тайл травы с terrain index — Godot автоматически выберет правильный тайл
func _place_grass_tile(x: int, y: int) -> void:
	grass_layer.set_cell(Vector2i(x, y), SOURCE_GRASS, Vector2i(-1, -1), TERRAIN_GRASS)


## Размещает тайл земли с terrain index
func _place_dirt_tile(x: int, y: int) -> void:
	dirt_layer.set_cell(Vector2i(x, y), SOURCE_DIRT, Vector2i(-1, -1), TERRAIN_DIRT)


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
