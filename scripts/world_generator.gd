extends RefCounted
# Генератор процедурного мира в стиле Terraria

enum TileType {
	AIR = -1, DIRT = 0, STONE = 1, GRASS = 2, DIRT_WALL = 3,
	STONE_WALL = 4, WOOD = 5, IRON_ORE = 6, GOLD_ORE = 7, SAND = 8,
	CLAY = 9, MUD = 10, SNOW = 11, ASH = 14, COPPER_ORE = 15,
	SILVER_ORE = 16, PLATINUM_ORE = 17, DEMONITE_ORE = 18, HELLSTONE = 13, HELL_ORE = 21
}

var width: int
var height: int
var world_seed: int

var terrain_noise: FastNoiseLite
var cave_noise_1: FastNoiseLite
var cave_noise_2: FastNoiseLite
var cave_noise_3: FastNoiseLite
var biome_noise: FastNoiseLite
var ore_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var humidity_noise: FastNoiseLite

var world_data = []
var wall_data = []
var surface_level: int
var rock_level: int
var hell_level: int

func _init(p_width: int, p_height: int, p_seed: int):
	width = p_width
	height = p_height
	world_seed = p_seed
	_setup_noise()

func _setup_noise():
	terrain_noise = FastNoiseLite.new(); terrain_noise.seed = world_seed; terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN; terrain_noise.frequency = 0.002; terrain_noise.fractal_octaves = 5; terrain_noise.fractal_lacunarity = 2.0; terrain_noise.fractal_gain = 0.5
	cave_noise_1 = FastNoiseLite.new(); cave_noise_1.seed = world_seed + 100; cave_noise_1.noise_type = FastNoiseLite.TYPE_PERLIN; cave_noise_1.frequency = 0.015; cave_noise_1.fractal_octaves = 4
	cave_noise_2 = FastNoiseLite.new(); cave_noise_2.seed = world_seed + 200; cave_noise_2.noise_type = FastNoiseLite.TYPE_CELLULAR; cave_noise_2.frequency = 0.02
	cave_noise_3 = FastNoiseLite.new(); cave_noise_3.seed = world_seed + 300; cave_noise_3.noise_type = FastNoiseLite.TYPE_PERLIN; cave_noise_3.frequency = 0.03; cave_noise_3.fractal_octaves = 2
	biome_noise = FastNoiseLite.new(); biome_noise.seed = world_seed + 400; biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN; biome_noise.frequency = 0.0003; biome_noise.fractal_octaves = 3
	ore_noise = FastNoiseLite.new(); ore_noise.seed = world_seed + 500; ore_noise.noise_type = FastNoiseLite.TYPE_CELLULAR; ore_noise.frequency = 0.04
	detail_noise = FastNoiseLite.new(); detail_noise.seed = world_seed + 600; detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN; detail_noise.frequency = 0.1
	temperature_noise = FastNoiseLite.new(); temperature_noise.seed = world_seed + 700; temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN; temperature_noise.frequency = 0.0005; temperature_noise.fractal_octaves = 2
	humidity_noise = FastNoiseLite.new(); humidity_noise.seed = world_seed + 800; humidity_noise.noise_type = FastNoiseLite.TYPE_PERLIN; humidity_noise.frequency = 0.0006; humidity_noise.fractal_octaves = 2

func generate_world() -> Dictionary:
	print("=== Генерация мира (Умный пирог) ===")
	world_data.clear()
	wall_data.clear()
	for y in range(height):
		world_data.append([])
		wall_data.append([])
		for x in range(width):
			world_data[y].append(TileType.AIR)
			wall_data[y].append(TileType.AIR)
	
	surface_level = floori(height * 0.45)
	rock_level = floori(height * 0.6)
	hell_level = floori(height * 0.9)
	
	_fill_world_with_blocks()
	_cut_surface()
	_cut_large_caves()
	_cut_medium_caves()
	_cut_small_caves()
	_cut_connecting_tunnels()
	_smooth_terrain()
	_remove_floating_blocks()
	
	var smoother = load("res://scripts/surface_smoother.gd").new()
	smoother.setup(world_data)
	smoother.smooth_surface(3)
	
	_generate_walls()
	
	# --- НАША НОВАЯ МАГИЯ СЛОЕВ ---
	_apply_smart_crust()
	
	_generate_desert()
	_generate_snow()
	_generate_corruption()
	_generate_copper()
	_generate_iron()
	_generate_silver()
	_generate_gold()
	_generate_platinum()
	_generate_demonite()
	_generate_hell_ores()
	_generate_hell()
	_generate_surface_details()
	_generate_trees()
	
	print("Мир сгенерирован!")
	return {"blocks": world_data, "walls": wall_data, "surface": surface_level}

func _fill_world_with_blocks():
	for y in range(floori(height * 0.1), height):
		for x in range(width):
			if y < hell_level:
				world_data[y][x] = TileType.STONE # Изначально всё ядро - темное
			else:
				world_data[y][x] = TileType.ASH

func _cut_surface():
	for x in range(width):
		var ground = clamp(surface_level + int(terrain_noise.get_noise_1d(x) * 40), floori(height * 0.1), floori(height * 0.55))
		for y in range(0, ground):
			if world_data[y][x] != TileType.AIR: world_data[y][x] = TileType.AIR
		if ground > 0 and ground < height: world_data[ground][x] = TileType.GRASS

func _cut_large_caves():
	for y in range(surface_level + 15, hell_level - 20):
		for x in range(10, width - 10):
			if world_data[y][x] == TileType.AIR or world_data[y][x] == TileType.WOOD: continue
			var cave_val = cave_noise_1.get_noise_2d(x, y)
			if cave_val > 0.3 and cave_val < 0.7:
				world_data[y][x] = TileType.AIR
				if abs(cave_val - 0.5) < 0.1:
					for dx in range(-2, 3):
						if x + dx >= 0 and x + dx < width and randf() < 0.7 and world_data[y][x + dx] != TileType.AIR:
							world_data[y][x + dx] = TileType.AIR

func _cut_medium_caves():
	for y in range(surface_level + 10, hell_level - 10):
		for x in range(5, width - 5):
			if world_data[y][x] == TileType.AIR or world_data[y][x] == TileType.WOOD: continue
			if cave_noise_2.get_noise_2d(x, y) > 0.5 and cave_noise_2.get_noise_2d(x, y) < 0.75:
				world_data[y][x] = TileType.AIR
				if randf() < 0.02:
					for dy in range(-3, 4):
						if y + dy >= 0 and y + dy < height and world_data[y + dy][x] != TileType.AIR:
							world_data[y + dy][x] = TileType.AIR

func _cut_small_caves():
	for y in range(surface_level + 5, hell_level - 5):
		for x in range(3, width - 3):
			if world_data[y][x] == TileType.AIR or world_data[y][x] == TileType.WOOD: continue
			if cave_noise_3.get_noise_2d(x, y) > 0.6 and cave_noise_3.get_noise_2d(x, y) < 0.8:
				world_data[y][x] = TileType.AIR

func _cut_connecting_tunnels():
	for y in range(surface_level + 20, hell_level - 20, 15):
		for x in range(20, width - 20):
			if world_data[y][x] == TileType.AIR:
				var has_air_right = false
				for dx in range(1, 6):
					if x + dx < width and world_data[y][x + dx] == TileType.AIR:
						has_air_right = true; break
				if has_air_right:
					for dx in range(1, 4):
						if x + dx < width and world_data[y][x + dx] != TileType.AIR and randf() < 0.6:
							world_data[y][x + dx] = TileType.AIR

func _smooth_terrain():
	for pass_idx in range(2):
		var changes = []
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				if world_data[y][x] == TileType.AIR or world_data[y][x] == TileType.WOOD: continue
				var air_neighbors = 0
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx != 0 or dy != 0:
							if world_data[y + dy][x + dx] == TileType.AIR: air_neighbors += 1
				if (air_neighbors >= 5 and world_data[y + 1][x] == TileType.AIR) or air_neighbors >= 7:
					changes.append({"x": x, "y": y})
		for change in changes: world_data[change["y"]][change["x"]] = TileType.AIR

func _remove_floating_blocks():
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if world_data[y][x] == TileType.AIR or world_data[y][x] == TileType.WOOD: continue
			var has_support = false
			for check_y in range(y + 1, min(y + 8, height)):
				if world_data[check_y][x] != TileType.AIR or (x > 0 and world_data[check_y][x - 1] != TileType.AIR) or (x < width - 1 and world_data[check_y][x + 1] != TileType.AIR):
					has_support = true; break
			if not has_support: world_data[y][x] = TileType.AIR

func _generate_walls():
	for y in range(surface_level + 5, height - 5):
		for x in range(5, width - 5):
			if world_data[y][x] != TileType.AIR: continue
			var solid_count = 0; var dirt_count = 0; var stone_count = 0
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var nx = x + dx; var ny = y + dy
					if nx >= 0 and nx < width and ny >= 0 and ny < height and world_data[ny][nx] != TileType.AIR:
						solid_count += 1
						if world_data[ny][nx] == TileType.DIRT or world_data[ny][nx] == TileType.GRASS: dirt_count += 1
						elif world_data[ny][nx] == TileType.STONE: stone_count += 1
			if solid_count >= 2:
				wall_data[y][x] = TileType.DIRT_WALL if dirt_count > stone_count else TileType.STONE_WALL

func _generate_desert():
	for x in range(width):
		if temperature_noise.get_noise_1d(x) > 0.3 and humidity_noise.get_noise_1d(x) < -0.2:
			var ground = _get_ground_level(x)
			if ground > 0:
				for dy in range(10):
					if ground + dy < height and world_data[ground + dy][x] in [TileType.DIRT, TileType.GRASS, TileType.STONE]:
						world_data[ground + dy][x] = TileType.SAND

func _generate_snow():
	for x in range(width):
		if temperature_noise.get_noise_1d(x) < -0.3:
			var ground = _get_ground_level(x)
			if ground > 0:
				for dy in range(8):
					if ground + dy < height and world_data[ground + dy][x] in [TileType.DIRT, TileType.GRASS, TileType.STONE]:
						world_data[ground + dy][x] = TileType.SNOW

func _generate_corruption():
	for i in range(1 + (randi() % 2)):
		var cx = floori(width * 0.2) + randi() % floori(width * 0.6)
		var ground = _get_ground_level(cx)
		if ground > 0:
			for x in range(cx - 30, cx + 30):
				if x >= 0 and x < width:
					for dy in range(-5, 30):
						if ground + dy >= 0 and ground + dy < height and world_data[ground + dy][x] != TileType.AIR and randf() < 0.7:
							world_data[ground + dy][x] = TileType.DEMONITE_ORE

func _generate_copper():
	for y in range(surface_level + 5, hell_level - 10):
		for x in range(width):
			if world_data[y][x] in [TileType.STONE, TileType.DIRT] and ore_noise.get_noise_2d(x * 1.1, y * 1.1) > 0.85:
				_create_ore_vein(x, y, TileType.COPPER_ORE, 4)

func _generate_iron():
	for y in range(surface_level + 10, hell_level - 5):
		for x in range(width):
			if world_data[y][x] == TileType.STONE and ore_noise.get_noise_2d(x * 1.3, y * 1.3) > 0.88:
				_create_ore_vein(x, y, TileType.IRON_ORE, 5)

func _generate_silver():
	for y in range(rock_level, hell_level):
		for x in range(width):
			if world_data[y][x] == TileType.STONE and ore_noise.get_noise_2d(x * 1.5, y * 1.5) > 0.92:
				_create_ore_vein(x, y, TileType.SILVER_ORE, 3)

func _generate_gold():
	for y in range(rock_level + 20, hell_level):
		for x in range(width):
			if world_data[y][x] == TileType.STONE and ore_noise.get_noise_2d(x * 1.7, y * 1.7) > 0.95:
				_create_ore_vein(x, y, TileType.GOLD_ORE, 2)

func _generate_platinum():
	for y in range(rock_level + 50, hell_level):
		for x in range(width):
			if world_data[y][x] == TileType.STONE and ore_noise.get_noise_2d(x * 2.0, y * 2.0) > 0.97:
				_create_ore_vein(x, y, TileType.PLATINUM_ORE, 2)

func _generate_demonite():
	for y in range(surface_level + 5, rock_level):
		for x in range(width):
			if world_data[y][x] in [TileType.STONE, TileType.DIRT] and ore_noise.get_noise_2d(x * 1.8, y * 1.8) > 0.96:
				_create_ore_vein(x, y, TileType.DEMONITE_ORE, 2)

func _generate_hell_ores():
	for y in range(hell_level, height):
		for x in range(width):
			if world_data[y][x] in [TileType.ASH, TileType.HELLSTONE] and ore_noise.get_noise_2d(x * 2.5, y * 2.5) > 0.85:
				_create_ore_vein(x, y, TileType.HELL_ORE, 3)

func _create_ore_vein(start_x: int, start_y: int, ore_type: int, size: int):
	var vein_tiles = [Vector2i(start_x, start_y)]
	var checked = [Vector2i(start_x, start_y)]
	for i in range(size * 4):
		if vein_tiles.is_empty(): break
		var pos = vein_tiles[randi() % vein_tiles.size()]
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0: continue
				var nx = pos.x + dx; var ny = pos.y + dy; var npos = Vector2i(nx, ny)
				if nx >= 0 and nx < width and ny >= 0 and ny < height and not npos in checked:
					checked.append(npos)
					if world_data[ny][nx] in [TileType.STONE, TileType.DIRT, TileType.ASH] and randf() < 0.5:
						world_data[ny][nx] = ore_type; vein_tiles.append(npos)

func _generate_hell():
	for y in range(hell_level, height):
		for x in range(width):
			if world_data[y][x] == TileType.AIR and randf() < 0.3: world_data[y][x] = TileType.ASH
			elif y > hell_level + 20 and world_data[y][x] in [TileType.STONE, TileType.ASH] and randf() < 0.4: world_data[y][x] = TileType.HELLSTONE
	for i in range(floori(width / 200)):
		var tx = floori(width * 0.1) + randi() % floori(width * 0.8)
		for dy in range(0, 15):
			var ty = hell_level + 10 + dy
			if ty < height:
				for dx in range(-2, 3):
					if tx + dx >= 0 and tx + dx < width: world_data[ty][tx + dx] = TileType.HELLSTONE

func _generate_surface_details():
	for x in range(width):
		var ground = _get_ground_level(x)
		if ground >= 0 and abs(detail_noise.get_noise_1d(x)) > 0.4:
			for dy in range(int(abs(detail_noise.get_noise_1d(x)) * 3)):
				if ground - 1 - dy >= 0 and world_data[ground - 1 - dy][x] == TileType.AIR:
					world_data[ground - 1 - dy][x] = TileType.DIRT

func _generate_trees():
	for x in range(10, width - 10, 4):
		var ground = _get_ground_level(x)
		if ground >= 0 and world_data[ground][x] == TileType.GRASS and randf() < 0.33:
			var can_place = true
			for dx in range(-2, 3):
				for dy in range(-8, 1):
					if x + dx >= 0 and x + dx < width and ground + dy >= 0 and world_data[ground + dy][x + dx] != TileType.AIR:
						can_place = false; break
			if can_place:
				var tree_height = 4 + randi() % 4
				for dy in range(1, tree_height + 1):
					if ground - dy >= 0: world_data[ground - dy][x] = TileType.WOOD
				for cx in range(-2, 3):
					for cy in range(-2, 3):
						if x + cx >= 0 and x + cx < width and ground - tree_height + cy >= 0:
							if world_data[ground - tree_height + cy][x + cx] == TileType.AIR and (abs(cx) < 2 or abs(cy) < 2):
								world_data[ground - tree_height + cy][x + cx] = TileType.WOOD

func _get_ground_level(x: int) -> int:
	for y in range(height):
		if world_data[y][x] != TileType.AIR: return y
	return -1

func _apply_smart_crust():
	print("  Этап 5.5: Умная кора (Слоеный пирог)...")
	for y in range(height):
		for x in range(width):
			if world_data[y][x] in [TileType.DIRT, TileType.STONE, TileType.GRASS]:
				var dist = 999
				var top = false
				for cy in range(-2, 3):
					for cx in range(-2, 3):
						var ny = y + cy
						var nx = x + cx
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							if world_data[ny][nx] == TileType.AIR:
								var d = max(abs(cx), abs(cy))
								if d < dist: dist = d
								if cx == 0 and cy == -1 and d == 1: top = true
				if top:
					world_data[y][x] = TileType.GRASS
				elif dist <= 2: # <--- Цифра 2 означает толщину светлого слоя. Если хочешь толще - ставь 3.
					world_data[y][x] = TileType.DIRT
				else:
					world_data[y][x] = TileType.STONE
