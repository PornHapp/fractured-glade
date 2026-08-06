extends Node2D

## TODO(Влад): необходим рефакторинг скрипта

const TILE_SIZE = 8

# Оставил твои названия узлов, чтобы не пришлось их менять в Godot!
@onready var grass_tile_map = $MainTileMapLayer
@onready var mirror_grass_tile_map = $MirrorTileMapLayer
@onready var info_label = $UI/InfoLabel

var player = null
var world_gen = null
var world_data = []
var mirror_world_data = []
var in_mirror_world = false

# Новые менеджеры
var chunk_manager: Node = null
var terrain_renderer: Node = null
var collision_manager: Node = null

var selected_block = 0
var mirror_offset_x = 0

func _ready():
	print("=== Загрузка игрового мира ===")
	# Используем твой Global
	var world_width_tiles: int = floori(Global.world_width / float(TILE_SIZE))
	var world_height_tiles: int = floori(Global.world_height / float(TILE_SIZE))
	mirror_offset_x = world_width_tiles + 10
	
	# Подключаем новые системы
	terrain_renderer = load("res://scripts/core/terrain_renderer.gd").new()
	terrain_renderer.name = "TerrainRenderer"
	terrain_renderer.setup(grass_tile_map, mirror_grass_tile_map, mirror_offset_x)
	add_child(terrain_renderer)
	
	chunk_manager = load("res://scripts/core/chunk_manager.gd").new()
	chunk_manager.name = "ChunkManager"
	chunk_manager.setup([], [], mirror_offset_x, terrain_renderer)
	add_child(chunk_manager)
	
	collision_manager = load("res://scripts/core/collision_manager.gd").new()
	collision_manager.name = "CollisionManager"
	collision_manager.setup([], [], mirror_offset_x)
	add_child(collision_manager)
	
	# Генерируем мир новым генератором
	## FIXME(Влад): избавиться от хардкода
	var WorldGeneratorClass = load("res://scripts/generation/world_generator.gd")
	world_gen = WorldGeneratorClass.new(world_width_tiles, world_height_tiles, Global.world_seed)
	var result = world_gen.generate_world()
	world_data = result["blocks"]
	
	_create_mirror_world()
	
	chunk_manager.setup(world_data, mirror_world_data, mirror_offset_x, terrain_renderer)
	collision_manager.setup(world_data, mirror_world_data, mirror_offset_x)
	
	_copy_tilesets_to_mirror()
	_create_player()
	# Дебаг-панель игрока (клавиши 8/9/0 меняют HP для проверки состояний)
	if player:
		$PlayerDebug.setup(player)
		$PlayerDebugUI.setup(player)
	
	# Загружаем только то, что вокруг игрока (Чанки)
	chunk_manager.update(player.position, in_mirror_world)
	collision_manager.build_all(self)
	collision_manager.add_borders(self, world_data[0].size(), world_data.size())
	_update_ui()
	print("=== Мир готов! ===")

func _create_mirror_world():
	mirror_world_data = []
	for y in range(world_data.size()):
		mirror_world_data.append([])
		for x in range(world_data[y].size()):
			mirror_world_data[y].append(world_data[y][world_data[y].size() - 1 - x])

func _copy_tilesets_to_mirror():
	if grass_tile_map.tile_set:
		mirror_grass_tile_map.tile_set = grass_tile_map.tile_set.duplicate()

func place_block(x: int, y: int, block_type: int):
	if x < 0 or x >= world_data[0].size() or y < 0 or y >= world_data.size(): return
	if world_data[y][x] != -1: return
	if player:
		var pr = Rect2(player.position.x - 8, player.position.y - 24, 16, 24)
		if pr.intersects(Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)): return
	
	world_data[y][x] = block_type
	terrain_renderer.update_surroundings(x, y, false, world_data)
	collision_manager.update_around(x, y, false)
	
	var mx = world_data[y].size() - 1 - x
	mirror_world_data[y][mx] = block_type
	terrain_renderer.update_surroundings(mx, y, true, mirror_world_data)
	collision_manager.update_around(mx, y, true)
	# Проигрываем анимацию «Взаимодействовать» (установка блока)
	if player:
		player.play_interact()

func remove_block(x: int, y: int):
	if x < 0 or x >= world_data[0].size() or y < 0 or y >= world_data.size(): return
	if world_data[y][x] == -1: return
	
	world_data[y][x] = -1
	terrain_renderer.update_surroundings(x, y, false, world_data)
	collision_manager.update_around(x, y, false)
	
	var mx = world_data[y].size() - 1 - x
	mirror_world_data[y][mx] = -1
	terrain_renderer.update_surroundings(mx, y, true, mirror_world_data)
	collision_manager.update_around(mx, y, true)
	# Проигрываем анимацию «Взаимодействовать» (добыча блока)
	if player:
		player.play_interact()

func switch_world():
	in_mirror_world = !in_mirror_world
	if in_mirror_world:
		var mx = world_data[0].size() - 1 - floori(player.position.x / float(TILE_SIZE))
		player.position.x = mirror_offset_x * TILE_SIZE + mx * TILE_SIZE + TILE_SIZE / 2.0
		collision_manager.set_main_active(false)
		collision_manager.set_mirror_active(true)
	else:
		var mx = world_data[0].size() - 1 - floori((player.position.x - mirror_offset_x * TILE_SIZE) / float(TILE_SIZE))
		player.position.x = mx * TILE_SIZE + TILE_SIZE / 2.0
		collision_manager.set_main_active(true)
		collision_manager.set_mirror_active(false)
	chunk_manager.reload_all_visible(player.position, in_mirror_world)
	_update_ui()

func _create_player():
	## FIXME(Влад): избавиться от хардкода
	var ps = load("res://scenes/player/player.tscn")
	if not ps: print("ОШИБКА: player.tscn не найден!"); return
	player = ps.instantiate(); player.name = "Player"; player.z_index = 10; add_child(player)
	var sx = world_data[0].size() / 2; var sy = 0
	for y in range(world_data.size()):
		if world_data[y][sx] != -1 and world_data[y][sx] != 5: sy = y; break
	player.position = Vector2(sx * TILE_SIZE + TILE_SIZE / 2.0, (sy - 30) * TILE_SIZE)

func _update_ui():
	if info_label:
		var block_names = {0: "Земля", 2: "Трава", 8: "Песок"}
		var count = chunk_manager.get_loaded_count(in_mirror_world)
		var world_name = "Новый мир"
		if Global.get("world_name"):
			world_name = Global.world_name
			
		info_label.text = ("ЗЕРКАЛЬНЫЙ" if in_mirror_world else "ОСНОВНОЙ") + " МИР | " + world_name
		info_label.text += "\nБлок: " + block_names.get(selected_block, "???") + " | Чанков: " + str(count)
		info_label.text += "\n1-Земля 2-Трава 3-Песок | ЛКМ-поставить ПКМ-убрать"
		info_label.text += "\nA/D-движение Пробел-прыжок Enter-смена мира ESC-меню"

func _input(event):
	if event.is_action_pressed("ui_cancel"): 
		## FIXME(Влад): избавиться от хардкода
		get_tree().change_scene_to_file("res://scenes/ui/menu/main_menu.tscn")

func _process(_delta):
	if not player: return
	# Динамически загружаем и выгружаем чанки при движении
	chunk_manager.update(player.position, in_mirror_world)
	
	if Input.is_key_pressed(KEY_1): selected_block = 0
	if Input.is_key_pressed(KEY_2): selected_block = 2
	if Input.is_key_pressed(KEY_3): selected_block = 8
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var tp = _get_mouse_tile()
		if in_mirror_world:
			var mx = world_data[0].size() - 1 - (tp.x - mirror_offset_x)
			if mx >= 0 and mx < world_data[0].size(): place_block(mx, tp.y, selected_block)
		else:
			place_block(tp.x, tp.y, selected_block)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var tp = _get_mouse_tile()
		if in_mirror_world:
			var mx = world_data[0].size() - 1 - (tp.x - mirror_offset_x)
			if mx >= 0 and mx < world_data[0].size(): remove_block(mx, tp.y)
		else:
			remove_block(tp.x, tp.y)

func _get_mouse_tile() -> Vector2i:
	if player:
		## FIXME(Влад): договориться о нейминге `Camera`, а не `Camera2D`
		var cam = player.get_node("Camera2D")
		if cam:
			var mp = cam.get_global_mouse_position()
			return Vector2i(floori(mp.x / float(TILE_SIZE)), floori(mp.y / float(TILE_SIZE)))
	return Vector2i(-1, -1)
