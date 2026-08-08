## Тестовый скрипт для проверки автотайлинга Grass и Dirt.
## Размещает тайлы на TileMapLayer для визуальной проверки переходов.
extends Node2D

## Ссылки на TileMapLayer узлы
@onready var dirt_layer: TileMapLayer = $DirtLayer
@onready var grass_layer: TileMapLayer = $GrassLayer

## Размер тайла в пикселях
const TILE_SIZE: int = 8

## Источники тайлсета (из TileSet)
const SOURCE_GRASS: int = 1
const SOURCE_DIRT: int = 2

## Позиции тайлов в атласе (col:row)
## Grass/Dirt.png - 3x3:
##   [0,0] [1,0] [2,0]
##   [0,1] [1,1] [2,1]
##   [0,2] [1,2] [2,2]

## Типы тайлов для autotile (atlas coordinates)
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


func _ready() -> void:
	_setup_dirt_terrain()
	_setup_grass_terrain()
	print("[AutotileTest] Террейн создан. Проверьте визуально.")


## Создает базовый слой земли (dirt)
func _setup_dirt_terrain() -> void:
	## Заполняем область 12x8 тайлами земли
	for x: int in range(-2, 14):
		for y: int in range(0, 8):
			dirt_layer.set_cell(
				Vector2i(x, y),
				SOURCE_DIRT,
				Vector2i(1, 1),  ## Центральный тайл dirt (пустой)
				0
			)


## Создает слой травы поверх земли
func _setup_grass_terrain() -> void:
	## Верхний ряд - полные блоки травы
	for x: int in range(0, 12):
		grass_layer.set_cell(
			Vector2i(x, -1),
			SOURCE_GRASS,
			Vector2i(0, 0),  ## Полный блок
			0
		)

	## Левый край
	grass_layer.set_cell(
		Vector2i(-1, 0),
		SOURCE_GRASS,
		Vector2i(0, 1),  ## Левый край
		0
	)

	## Правый край
	grass_layer.set_cell(
		Vector2i(12, 0),
		SOURCE_GRASS,
		Vector2i(2, 1),  ## Правый край
		0
	)

	## Нижний край
	for x: int in range(0, 12):
		grass_layer.set_cell(
			Vector2i(x, 8),
			SOURCE_GRASS,
			Vector2i(1, 2),  ## Нижний край
			0
		)

	## Углы
	grass_layer.set_cell(
		Vector2i(-1, -1),
		SOURCE_GRASS,
		Vector2i(0, 0),  ## Верхний левый угол
		0
	)
	grass_layer.set_cell(
		Vector2i(12, -1),
		SOURCE_GRASS,
		Vector2i(2, 0),  ## Верхний правый угол
		0
	)
	grass_layer.set_cell(
		Vector2i(-1, 8),
		SOURCE_GRASS,
		Vector2i(0, 2),  ## Нижний левый угол
		0
	)
	grass_layer.set_cell(
		Vector2i(12, 8),
		SOURCE_GRASS,
		Vector2i(2, 2),  ## Нижний правый угол
		0
	)


## Вспомогательная функция для заполнения.rectangle области
func _fill_rect(layer: TileMapLayer, start: Vector2i, end: Vector2i,
		source: int, atlas_coords: Vector2i) -> void:
	for x: int in range(start.x, end.x + 1):
		for y: int in range(start.y, end.y + 1):
			layer.set_cell(Vector2i(x, y), source, atlas_coords, 0)
