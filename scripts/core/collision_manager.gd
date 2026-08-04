extends Node
var world_data = []
var mirror_world_data = []
var mirror_offset_x = 0
var main_body: StaticBody2D = null
var mirror_body: StaticBody2D = null
const TILE_SIZE = 8

func setup(p_world: Array, p_mirror: Array, p_offset: int):
	world_data = p_world
	mirror_world_data = p_mirror
	mirror_offset_x = p_offset

func build_all(parent: Node):
	build_world(parent)
	build_mirror(parent)

func build_world(parent: Node):
	if main_body: main_body.queue_free()
	main_body = StaticBody2D.new()
	main_body.name = "MainWorldCollision"
	main_body.collision_layer = 1
	main_body.collision_mask = 1
	_build_collision(main_body, world_data, 0)
	parent.add_child(main_body)

func build_mirror(parent: Node):
	if mirror_body: mirror_body.queue_free()
	mirror_body = StaticBody2D.new()
	mirror_body.name = "MirrorWorldCollision"
	mirror_body.collision_layer = 1
	mirror_body.collision_mask = 1
	_build_collision(mirror_body, mirror_world_data, mirror_offset_x)
	parent.add_child(mirror_body)

func _build_collision(body: StaticBody2D, data: Array, offset_x: int):
	for x in range(0, data[0].size(), 2):
		for y in range(0, data.size(), 2):
			for gx in range(x, min(x + 2, data[0].size())):
				for gy in range(y, min(y + 2, data.size())):
					if data[gy][gx] == -1 or data[gy][gx] == 5: continue
					if _needs_collision(data, gx, gy):
						var cs = CollisionShape2D.new()
						var rect = RectangleShape2D.new()
						rect.size = Vector2(TILE_SIZE, TILE_SIZE)
						cs.shape = rect
						cs.position = Vector2((offset_x + gx) * TILE_SIZE + TILE_SIZE / 2.0, gy * TILE_SIZE + TILE_SIZE / 2.0)
						body.add_child(cs)

func _needs_collision(data: Array, x: int, y: int) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx = x + dx; var ny = y + dy
			if nx >= 0 and nx < data[0].size() and ny >= 0 and ny < data.size():
				if data[ny][nx] == -1 or data[ny][nx] == 5:
					return true
	return false

func update_around(x: int, y: int, is_mirror: bool):
	# Обновляет коллизию только в радиусе 3 блоков
	var body = mirror_body if is_mirror else main_body
	var data = mirror_world_data if is_mirror else world_data
	var offset = mirror_offset_x if is_mirror else 0
	if not body: return
	
	# Удаляем старые коллизии в этой области
	for child in body.get_children():
		var cpos = child.position
		var cx = floori((cpos.x - offset * TILE_SIZE) / TILE_SIZE)
		var cy = floori(cpos.y / TILE_SIZE)
		if abs(cx - x) <= 3 and abs(cy - y) <= 3:
			child.queue_free()
	
	# Создаём новые коллизии в этой области
	for gx in range(max(0, x-3), min(data[0].size(), x+4)):
		for gy in range(max(0, y-3), min(data.size(), y+4)):
			if data[gy][gx] == -1 or data[gy][gx] == 5: continue
			if _needs_collision(data, gx, gy):
				var cs = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				rect.size = Vector2(TILE_SIZE, TILE_SIZE)
				cs.shape = rect
				cs.position = Vector2((offset + gx) * TILE_SIZE + TILE_SIZE / 2.0, gy * TILE_SIZE + TILE_SIZE / 2.0)
				body.add_child(cs)

func set_main_active(active: bool):
	if main_body:
		var l = 1 if active else 0
		main_body.collision_layer = l
		main_body.collision_mask = l

func set_mirror_active(active: bool):
	if mirror_body:
		var l = 1 if active else 0
		mirror_body.collision_layer = l
		mirror_body.collision_mask = l

func add_borders(parent: Node, world_width: int, world_height: int):
	var borders = StaticBody2D.new()
	borders.name = "WorldBorders"
	borders.collision_layer = 1
	borders.collision_mask = 1
	var ww = world_width * TILE_SIZE
	var wh = world_height * TILE_SIZE
	var mop = mirror_offset_x * TILE_SIZE
	var bt = 4
	_add_shape(borders, Vector2(bt, wh), Vector2(-bt/2.0, wh/2.0))
	_add_shape(borders, Vector2(bt, wh), Vector2(mop + ww + bt/2.0, wh/2.0))
	_add_shape(borders, Vector2(bt, wh), Vector2(mop - bt/2.0, wh/2.0))
	_add_shape(borders, Vector2(mop + ww + bt*2, bt), Vector2((mop + ww)/2.0, wh + bt/2.0))
	parent.add_child(borders)

func _add_shape(body: StaticBody2D, size: Vector2, pos: Vector2):
	var cs = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	cs.position = pos
	body.add_child(cs)
