extends Node2D

var time = 0.0
var vines = []
var wind_strength = 0.0
var wind_target = 0.0
var gust_timer = 0.0

func _ready():
	randomize()
	create_jungle()

func create_jungle():
	var screen_size = get_viewport_rect().size
	
	# === 1. ОБЫЧНЫЕ ЛИАНЫ (свисают с потолка) ===
	var vine_count = 35
	
	for i in range(vine_count):
		var x_pos = randf_range(0, screen_size.x)
		var center_dist = abs(x_pos - screen_size.x / 2) / (screen_size.x / 2)
		
		var density = 1.0 - center_dist * 0.6
		if randf() > density:
			continue
		
		var max_length
		if center_dist < 0.3:
			max_length = randf_range(0.1, 0.25)
		else:
			if randf() < 0.4:
				max_length = randf_range(0.1, 0.3)
			else:
				max_length = randf_range(0.5, 0.9)
		
		var x_offset = randf_range(-10, 10)
		var thickness = randf_range(2.0, 5.0)
		
		var vine = Line2D.new()
		vine.width = thickness
		vine.default_color = Color(0.1, 0.6, 0.15, 0.7)
		vine.joint_mode = Line2D.LINE_JOINT_ROUND
		vine.begin_cap_mode = Line2D.LINE_CAP_ROUND
		vine.end_cap_mode = Line2D.LINE_CAP_ROUND
		vine.z_index = 0
		add_child(vine)
		
		var points = []
		var points_count = randi_range(30, 45)
		
		var fixed_x = x_pos + x_offset
		
		for j in range(points_count):
			var t = float(j) / points_count
			var base_x = fixed_x + sin(t * 1.5) * randf_range(-15, 15)
			var base_y = t * screen_size.y * max_length
			points.append(Vector2(base_x, base_y))
		
		vine.points = points
		
		# === ЛИСТЬЯ НА ОБЫЧНОЙ ЛИАНЕ ===
		var leaf_data = []
		var leaf_count = randi_range(5, 12)
		
		for k in range(leaf_count):
			var t = randf_range(0.15, 0.85)
			var idx = int(t * points.size())
			if idx < points.size():
				var pos = points[idx]
				var leaf = create_leaf(pos, true)
				leaf_data.append({
					"node": leaf,
					"t": t,
					"phase": randf() * PI * 2,
					"size": leaf.scale.x,
				})
		
		vines.append({
			"node": vine,
			"points": points,
			"fixed_x": fixed_x,
			"max_length": max_length,
			"phase": randf() * PI * 2,
			"leaves": leaf_data,
			"wind_phase": randf() * PI * 2,
			"type": "normal"
		})
	
	# === 2. ДУГООБРАЗНЫЕ ЛИАНЫ (ОБА КОНЦА ЗА ВЕРХОМ ЭКРАНА) ===
	var arch_count = 25
	
	for i in range(arch_count):
		var x_pos = randf_range(0, screen_size.x)
		var center_dist = abs(x_pos - screen_size.x / 2) / (screen_size.x / 2)
		
		# Только по краям
		if center_dist < 0.3:
			continue
		
		var span = randf_range(250, 450)  # Ширина дуги (больше)
		var height = randf_range(120, 280)  # Высота дуги
		var thickness = randf_range(2.0, 4.0)
		
		var vine = Line2D.new()
		vine.width = thickness
		vine.default_color = Color(0.1, 0.6, 0.15, 0.6)
		vine.joint_mode = Line2D.LINE_JOINT_ROUND
		vine.begin_cap_mode = Line2D.LINE_CAP_ROUND
		vine.end_cap_mode = Line2D.LINE_CAP_ROUND
		vine.z_index = 0
		add_child(vine)
		
		var points = []
		var points_count = randi_range(35, 50)
		
		# === ДУГА С КОНЦАМИ ЗА ЭКРАНОМ ===
		# Смещаем дугу вверх, чтобы концы были за экраном
		var y_offset_top = -randf_range(20, 80)  # Концы выше экрана
		
		for j in range(points_count):
			var t = float(j) / points_count
			
			# Парабола: y = 4 * height * t * (1 - t)
			var y_offset = 4 * height * t * (1 - t)
			
			# Смещение по X от центра дуги
			var x_offset = -span/2 + t * span
			
			# Базовая позиция (концы уходят за экран)
			var base_x = x_pos + x_offset + sin(t * 2.0) * randf_range(-10, 10)
			var base_y = y_offset_top + y_offset + randf_range(-5, 5)
			
			points.append(Vector2(base_x, base_y))
		
		vine.points = points
		
		# === ЛИСТЬЯ НА ДУГООБРАЗНОЙ ЛИАНЕ ===
		var leaf_data = []
		var leaf_count = randi_range(10, 20)
		
		for k in range(leaf_count):
			var t = randf_range(0.05, 0.95)
			var idx = int(t * points.size())
			if idx < points.size():
				var pos = points[idx]
				var leaf = create_leaf(pos, true)
				leaf_data.append({
					"node": leaf,
					"t": t,
					"phase": randf() * PI * 2,
					"size": leaf.scale.x,
				})
		
		vines.append({
			"node": vine,
			"points": points,
			"fixed_x": x_pos,
			"max_length": 1.0,
			"phase": randf() * PI * 2,
			"leaves": leaf_data,
			"wind_phase": randf() * PI * 2,
			"type": "arch",
			"span": span,
			"height": height,
			"y_offset_top": y_offset_top
		})
	
	# === 3. ДОПОЛНИТЕЛЬНАЯ ЛИСТВА ПО КРАЯМ ===
	for i in range(40):
		var side = randf() < 0.5
		var x = randf_range(0, screen_size.x * 0.08) if side else randf_range(screen_size.x * 0.92, screen_size.x)
		var y = randf_range(0, screen_size.y * 0.4)
		var leaf = create_leaf(Vector2(x, y), false, true)
		
		vines.append({
			"is_leaf": true,
			"node": leaf,
			"base_x": x,
			"base_y": y,
			"phase": randf() * PI * 2,
			"sway_speed": randf_range(0.2, 0.5),
			"sway_amount": randf_range(2, 6)
		})


func create_leaf(pos, on_vine = false, standalone = false):
	var leaf = Sprite2D.new()
	
	# Размер листа
	var image_size = 20
	var image = Image.create(image_size, image_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var hue = randf_range(0.2, 0.4)
	var sat = randf_range(0.5, 0.9)
	var val = randf_range(0.4, 0.9)
	var center = image_size / 2
	
	# === РИСУЕМ РОМБ ===
	for px in range(image_size):
		for py in range(image_size):
			var dx = abs(px - center) / center
			var dy = abs(py - center) / center
			
			# Форма ромба: |dx| + |dy| < 1
			if dx + dy < 0.9:
				var alpha_leaf = (1.0 - (dx + dy) / 0.9) * randf_range(0.7, 1.0)
				var color = Color.from_hsv(
					hue + randf_range(-0.03, 0.03),
					sat + randf_range(-0.1, 0.1),
					val + randf_range(-0.1, 0.1),
					alpha_leaf
				)
				image.set_pixel(px, py, color)
	
	leaf.texture = ImageTexture.create_from_image(image)
	leaf.position = pos
	leaf.centered = true
	leaf.z_index = 5
	leaf.z_as_relative = false
	
	if standalone:
		# Отдельные листья (не на лианах) - делаем прозрачными
		leaf.scale = Vector2(randf_range(0.3, 0.5), randf_range(0.3, 0.5))
		leaf.modulate = Color(1, 1, 1, 0.2)  # Почти прозрачные
		leaf.rotation = randf_range(-0.5, 0.5)
		add_child(leaf)
		return leaf
	
	if on_vine:
		# === ЛИСТЬЯ НА ЛИАНЕ (как ёлочка) ===
		# Случайно выбираем сторону: -1 (лево) или 1 (право)
		var side = 1 if randf() < 0.5 else -1
		
		# Смещение от центра лианы (на край)
		var offset = randf_range(8, 14) * side
		
		# Размер листа
		var size = randf_range(0.6, 1.0)
		leaf.scale = Vector2(size, size)
		
		# Поворот в сторону от лианы
		var angle = side * randf_range(0.3, 0.8)  # Угол от лианы
		leaf.rotation = angle
		
		# Смещаем лист на край лианы
		leaf.position = pos + Vector2(offset, 0)
		
		# Запоминаем данные для анимации
		leaf.set_meta("side", side)
		leaf.set_meta("offset", offset)
		leaf.set_meta("base_pos", pos)
		
		add_child(leaf)
		return leaf
	
	# Обычные листья (для безопасности)
	leaf.scale = Vector2(randf_range(0.4, 0.7), randf_range(0.4, 0.7))
	leaf.rotation = randf_range(-0.5, 0.5)
	add_child(leaf)
	return leaf

func _process(delta):
	time += delta
	var screen_size = get_viewport_rect().size
	
	# === ВЕТЕР ===
	gust_timer += delta
	if gust_timer > randf_range(2.5, 5.0):
		gust_timer = 0.0
		wind_target = randf_range(-0.5, 0.5)
	
	wind_strength = lerp(wind_strength, wind_target, delta * 2.0)
	
	for item in vines:
		if item.has("is_leaf") and item["is_leaf"]:
			# Отдельные листья - оставляем прозрачными
			var leaf = item["node"]
			var base_x = item["base_x"]
			var base_y = item["base_y"]
			var phase = item["phase"]
			var sway_speed = item["sway_speed"]
			var sway_amount = item["sway_amount"]
			
			var wind_effect = wind_strength * 10
			var sway_x = sin(time * sway_speed + phase) * sway_amount + wind_effect
			var sway_y = cos(time * sway_speed * 0.7 + phase * 1.3) * sway_amount * 0.5
			leaf.position = Vector2(base_x + sway_x, base_y + sway_y)
			leaf.rotation = sin(time * 0.3 + phase) * 0.2
			# Оставляем прозрачными
			leaf.modulate = Color(1, 1, 1, 0.15)
			
		else:
			var vine = item["node"]
			var points = item["points"]
			var new_points = []
			
			var fixed_x = item["fixed_x"]
			var max_length = item["max_length"]
			var phase = item["phase"]
			var leaves = item.get("leaves", [])
			var wind_phase = item["wind_phase"]
			var type = item["type"]
			
			if type == "arch":
				# === ДУГООБРАЗНЫЕ ЛИАНЫ ===
				var span = item["span"]
				var height = item["height"]
				var y_offset_top = item["y_offset_top"]
				var wind_force = wind_strength * 35
				
				for j in range(points.size()):
					var t = float(j) / points.size()
					
					var y_offset = 4 * height * t * (1 - t)
					var x_offset = -span/2 + t * span
					
					var base_x = fixed_x + x_offset
					var base_y = y_offset_top + y_offset
					
					var wind_multiplier = sin(t * PI) * 0.8
					var wind_offset = wind_force * wind_multiplier
					
					var sway = sin(time * 0.6 + t * 4.0 + phase) * 8 * sin(t * PI)
					var sway2 = sin(time * 0.4 + t * 6.0 + wind_phase) * 5 * sin(t * PI)
					
					new_points.append(Vector2(
						base_x + wind_offset + sway + sway2,
						base_y
					))
				
				vine.points = new_points
				
			else:
				# === ОБЫЧНЫЕ ЛИАНЫ ===
				var wind_force = wind_strength * 60
				
				for j in range(points.size()):
					var t = float(j) / points.size()
					
					var base_x = fixed_x
					var base_y = t * screen_size.y * max_length
					
					var wind_multiplier = t * t * 1.2
					var wind_offset = wind_force * wind_multiplier
					
					var sway1 = sin(time * 0.8 + t * 3.0 + phase) * 15 * t
					var sway2 = sin(time * 0.5 + t * 5.0 + phase * 1.5 + wind_phase) * 8 * t
					
					new_points.append(Vector2(
						base_x + wind_offset + sway1 + sway2,
						base_y
					))
				
				vine.points = new_points
			
			# === ОБНОВЛЯЕМ ЛИСТЬЯ НА ЛИАНАХ ===
			for leaf_info in leaves:
				var leaf = leaf_info["node"]
				var t = leaf_info["t"]
				
				# Вычисляем индекс по пропорции
				var idx = int(t * new_points.size())
				
				if idx >= new_points.size():
					idx = new_points.size() - 1
				if idx < 0:
					idx = 0
				
				var pos = new_points[idx]
				
				# Получаем сторону и смещение
				var side = leaf.get_meta("side", 1)
				var offset = leaf.get_meta("offset", 10)
				
				# Позиция на краю лианы (с учетом стороны)
				var leaf_pos = pos + Vector2(offset, 0)
				
				# Если лист на правой стороне, смещение положительное
				# Если на левой - отрицательное
				if side < 0:
					leaf_pos = pos + Vector2(-abs(offset), 0)
				
				# Обновляем позицию листа
				leaf.position = leaf_pos
				
				# Вращение от ветра (немного)
				var wind_rotation = wind_strength * 0.05
				var base_rotation = leaf.get_meta("base_rotation", 0.5)
				leaf.rotation = base_rotation * side + wind_rotation
				
				# Мерцание
				var glow = sin(time * 0.8 + leaf_info["phase"]) * 0.15 + 0.85
				leaf.modulate = Color(1, 1, 1, glow)
				
				# Пульсация размера
				var pulse = sin(time * 0.3 + leaf_info["phase"]) * 0.05 + 1.0
				var base_size = leaf_info["size"]
				leaf.scale = Vector2(base_size * pulse, base_size * pulse)
