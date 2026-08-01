extends Node
# Отрисовщик тайлов (С системой Умной Коры)

var grass_tile_map: TileMapLayer = null
var mirror_grass_tile_map: TileMapLayer = null
var mirror_offset_x = 0

func setup(p_grass: TileMapLayer, p_mirror: TileMapLayer, p_offset: int):
	grass_tile_map = p_grass
	mirror_grass_tile_map = p_mirror
	mirror_offset_x = p_offset

func render_chunk(bounds: Dictionary, data: Array, is_mirror: bool):
	var tile_map = mirror_grass_tile_map if is_mirror else grass_tile_map
	var offset_x = mirror_offset_x if is_mirror else 0
	if not tile_map or not tile_map.tile_set: return
	
	var x_start = max(0, bounds["x_start"] - 1)
	var x_end = min(data[0].size(), bounds["x_end"] + 1)
	var y_start = max(0, bounds["y_start"] - 1)
	var y_end = min(data.size(), bounds["y_end"] + 1)
	
	var grass_cells = []
	var dirt_cells = []
	var stone_cells = []
	
	for y in range(y_start, y_end):
		for x in range(x_start, x_end):
			if y >= data.size() or x >= data[y].size(): continue
			var t = data[y][x]
			if t == -1 or t == 5: continue
			var pos = Vector2i(x + offset_x, y)
			
			if t == 2: grass_cells.append(pos)
			elif t == 0: dirt_cells.append(pos)
			else: stone_cells.append(pos)
			
	if stone_cells.size() > 0: tile_map.set_cells_terrain_connect(stone_cells, 0, 2)
	if dirt_cells.size() > 0: tile_map.set_cells_terrain_connect(dirt_cells, 0, 1)
	if grass_cells.size() > 0: tile_map.set_cells_terrain_connect(grass_cells, 0, 0)

func clear_chunk(bounds: Dictionary, is_mirror: bool):
	var tile_map = mirror_grass_tile_map if is_mirror else grass_tile_map
	var offset_x = mirror_offset_x if is_mirror else 0
	for y in range(bounds["y_start"], bounds["y_end"]):
		for x in range(bounds["x_start"], bounds["x_end"]):
			tile_map.erase_cell(Vector2i(x + offset_x, y))

func update_block(x: int, y: int, is_mirror: bool, data: Array):
	pass # Не используется, всё делаем массово

func update_surroundings(x: int, y: int, is_mirror: bool, data: Array):
	var tile_map = mirror_grass_tile_map if is_mirror else grass_tile_map
	var offset_x = mirror_offset_x if is_mirror else 0
	
	if data[y][x] == -1 or data[y][x] == 5:
		tile_map.erase_cell(Vector2i(x + offset_x, y))
		
	# 1. Пересчитываем пирог (Умная кора)
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or ny >= data.size() or nx >= data[ny].size(): continue
			
			var t = data[ny][nx]
			if t in [0, 1, 2]: # DIRT, STONE, GRASS
				var dist = 999
				var top = false
				# Ищем воздух в радиусе 2 блоков
				for cy in range(-2, 3):
					for cx in range(-2, 3):
						var check_x = nx + cx
						var check_y = ny + cy
						if check_x >= 0 and check_x < data[ny].size() and check_y >= 0 and check_y < data.size():
							if data[check_y][check_x] == -1: # Воздух
								var d = max(abs(cx), abs(cy))
								if d < dist: dist = d
								if cx == 0 and cy == -1 and d == 1: top = true
								
				var new_type = 1 # STONE (Ядро - темная земля)
				if top: new_type = 2 # GRASS (Сверху)
				elif dist <= 2: new_type = 0 # DIRT (Кора - светлая земля)
				data[ny][nx] = new_type
				
	# 2. Отрисовываем изменения
	var grass_cells = []
	var dirt_cells = []
	var stone_cells = []
	
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or ny >= data.size() or nx >= data[ny].size(): continue
			var pos = Vector2i(nx + offset_x, ny)
			var t = data[ny][nx]
			
			if t == -1 or t == 5: tile_map.erase_cell(pos)
			elif t == 2: grass_cells.append(pos)
			elif t == 0: dirt_cells.append(pos)
			else: stone_cells.append(pos)
			
	if stone_cells.size() > 0: tile_map.set_cells_terrain_connect(stone_cells, 0, 2)
	if dirt_cells.size() > 0: tile_map.set_cells_terrain_connect(dirt_cells, 0, 1)
	if grass_cells.size() > 0: tile_map.set_cells_terrain_connect(grass_cells, 0, 0)
