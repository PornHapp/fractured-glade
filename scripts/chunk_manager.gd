extends Node
const CHUNK_SIZE = 32
const RENDER_DISTANCE = 3

var world_data = []
var mirror_world_data = []
var mirror_offset_x = 0

var loaded_chunks = {}
var mirror_loaded_chunks = {}
var last_player_chunk = Vector2i(-999, -999)

var terrain_renderer: Node = null

func setup(p_world_data: Array, p_mirror_world_data: Array, p_mirror_offset: int, p_terrain_renderer: Node):
	world_data = p_world_data
	mirror_world_data = p_mirror_world_data
	mirror_offset_x = p_mirror_offset
	terrain_renderer = p_terrain_renderer

func get_chunk_key(chunk_x: int, chunk_y: int) -> String:
	return str(chunk_x) + "_" + str(chunk_y)

func get_chunk_for_position(world_x: int, world_y: int) -> Vector2i:
	return Vector2i(floori(world_x / float(CHUNK_SIZE)), floori(world_y / float(CHUNK_SIZE)))

func get_chunk_bounds(chunk_x: int, chunk_y: int) -> Dictionary:
	return {
		"x_start": chunk_x * CHUNK_SIZE,
		"x_end": min((chunk_x + 1) * CHUNK_SIZE, world_data[0].size()),
		"y_start": chunk_y * CHUNK_SIZE,
		"y_end": min((chunk_y + 1) * CHUNK_SIZE, world_data.size())
	}

func update(player_position: Vector2, is_mirror: bool):
	var world_x = floori(player_position.x / 8.0)
	var world_y = floori(player_position.y / 8.0)
	if is_mirror: world_x -= mirror_offset_x
	
	var player_chunk = get_chunk_for_position(world_x, world_y)
	if player_chunk == last_player_chunk:
		return
	last_player_chunk = player_chunk
	
	var needed_chunks = {}
	for dx in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for dy in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var cx = player_chunk.x + dx
			var cy = player_chunk.y + dy
			if cx >= 0 and cy >= 0 and cx * CHUNK_SIZE < world_data[0].size() and cy * CHUNK_SIZE < world_data.size():
				needed_chunks[get_chunk_key(cx, cy)] = {"x": cx, "y": cy}
	
	for key in needed_chunks:
		var chunk = needed_chunks[key]
		load_chunk(chunk["x"], chunk["y"], is_mirror)
	
	var target_dict = mirror_loaded_chunks if is_mirror else loaded_chunks
	var to_unload = []
	for key in target_dict:
		if not needed_chunks.has(key):
			var parts = key.split("_")
			to_unload.append({"x": int(parts[0]), "y": int(parts[1])})
	for chunk in to_unload:
		unload_chunk(chunk["x"], chunk["y"], is_mirror)

func load_chunk(chunk_x: int, chunk_y: int, is_mirror: bool):
	var key = get_chunk_key(chunk_x, chunk_y)
	var target_dict = mirror_loaded_chunks if is_mirror else loaded_chunks
	if target_dict.has(key): return
	
	var bounds = get_chunk_bounds(chunk_x, chunk_y)
	var data = mirror_world_data if is_mirror else world_data
	if terrain_renderer:
		terrain_renderer.render_chunk(bounds, data, is_mirror)
	target_dict[key] = true

func unload_chunk(chunk_x: int, chunk_y: int, is_mirror: bool):
	var key = get_chunk_key(chunk_x, chunk_y)
	var target_dict = mirror_loaded_chunks if is_mirror else loaded_chunks
	if not target_dict.has(key): return
	
	var bounds = get_chunk_bounds(chunk_x, chunk_y)
	if terrain_renderer:
		terrain_renderer.clear_chunk(bounds, is_mirror)
	target_dict.erase(key)

func reload_all_visible(player_position: Vector2, is_mirror: bool):
	last_player_chunk = Vector2i(-999, -999)
	update(player_position, is_mirror)

func get_loaded_count(is_mirror: bool) -> int:
	var d = mirror_loaded_chunks if is_mirror else loaded_chunks
	return d.size()
