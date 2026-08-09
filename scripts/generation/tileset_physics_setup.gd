## Утилита для программного добавления collision polygons ко всем тайлам TileSet.
## Добавляет физику в _ready(), затем удаляется.
## Обходит атлас перебором координат, т.к. get_used_cells() ненадёжен в 4.7.
extends Node

## Ссылка на TileMapLayer, TileSet которого нужно настроить
@export var tile_map_layer: TileMapLayer

## Максимальный размер атласа для перебора (сетка тайлов)
const ATLAS_MAX_SIZE: int = 32


func _ready() -> void:
	if tile_map_layer and tile_map_layer.tile_set:
		_setup_physics(tile_map_layer.tile_set)
		print("[TilesetPhysicsSetup] OK: %s" % tile_map_layer.name)
	queue_free()


## Добавляет collision polygon ко всем тайлам в TileSet
func _setup_physics(ts: TileSet) -> void:
	if ts.get_physics_layers_count() == 0:
		ts.add_physics_layer()

	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 2)

	var polygon: PackedVector2Array = PackedVector2Array([
		Vector2(0, 0), Vector2(8, 0), Vector2(8, 8), Vector2(0, 8)
	])

	for source_idx: int in ts.get_source_count():
		var source_id: int = ts.get_source_id(source_idx)
		var source: TileSetSource = ts.get_source(source_id)
		if not (source is TileSetAtlasSource):
			continue

		var atlas: TileSetAtlasSource = source as TileSetAtlasSource
		var count: int = 0

		## Перебираем координаты сетки атласа
		for x: int in range(ATLAS_MAX_SIZE):
			for y: int in range(ATLAS_MAX_SIZE):
				var tile_id: Vector2i = Vector2i(x, y)
				## Проверяем существование тайла через альтернативу 0
				var tile_data: TileData = _get_tile_data_safe(atlas, tile_id)
				if tile_data == null:
					continue
				if tile_data.get_collision_polygons_count(0) == 0:
					tile_data.add_collision_polygon(0)
					tile_data.set_collision_polygon_points(
						0,
						tile_data.get_collision_polygons_count(0) - 1,
						polygon
					)
					count += 1
		print("[TilesetPhysicsSetup] source %d: %d tiles got collision" % [source_id, count])


## Безопасное получение TileData — возвращает null если тайл не существует
func _get_tile_data_safe(atlas: TileSetAtlasSource, tile_id: Vector2i) -> TileData:
	## Проверяем есть ли тайл в атласе по его атрибуту atlas_coords
	## TileSetAtlasSource хранит тайлы как Dictionary内部
	## Пробуем получить данные — если тайла нет, вернётся null или произойдёт ошибка
	if not atlas.has_tile(tile_id):
		return null
	return atlas.get_tile_data(tile_id, 0)
