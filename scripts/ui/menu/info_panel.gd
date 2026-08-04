extends Node2D

var fps_counter: Label
var version_label: Label
var build_label: Label
var status_label: Label
var sound_label: Label
var fps_update_timer: float = 0.0
var current_fps: int = 0
var is_sound_on: bool = true

func _ready():
	var screen_size = get_viewport_rect().size
	
	# === ЛЕВЫЙ НИЖНИЙ УГОЛ ===
	
	# Версия игры
	version_label = Label.new()
	version_label.text = "v1.0.0"
	version_label.add_theme_font_size_override("font_size", 28)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3, 0.9))
	version_label.add_theme_color_override("font_outline_modulate", Color(0, 0, 0, 0.5))
	version_label.add_theme_constant_override("outline_size", 3)
	version_label.position = Vector2(25, screen_size.y - 55)
	version_label.z_index = 10
	add_child(version_label)
	
	# Дата сборки (увеличена)
	build_label = Label.new()
	var date = Time.get_date_dict_from_system()
	build_label.text = "Build: " + str(date.get("day")) + "." + str(date.get("month")) + "." + str(date.get("year"))
	build_label.add_theme_font_size_override("font_size", 28)  # Было 14
	build_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.3, 0.7))  # Ярче
	build_label.add_theme_color_override("font_outline_modulate", Color(0, 0, 0, 0.5))
	build_label.add_theme_constant_override("outline_size", 3)
	build_label.position = Vector2(25, screen_size.y - 30)  # Сдвинул выше
	build_label.z_index = 10
	add_child(build_label)
	
	# === ПРАВЫЙ НИЖНИЙ УГОЛ ===
	
	# FPS
	fps_counter = Label.new()
	fps_counter.text = "FPS: 0"
	fps_counter.add_theme_font_size_override("font_size", 28)
	fps_counter.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3, 0.9))
	fps_counter.add_theme_color_override("font_outline_modulate", Color(0, 0, 0, 0.5))
	fps_counter.add_theme_constant_override("outline_size", 3)
	fps_counter.position = Vector2(screen_size.x - 180, screen_size.y - 55)
	fps_counter.z_index = 10
	add_child(fps_counter)
	
	# Статус (увеличен)
	status_label = Label.new()
	status_label.text = "● OPTIMAL"
	status_label.add_theme_font_size_override("font_size", 28)  # Было 14
	status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3, 0.8))  # Ярче
	status_label.add_theme_color_override("font_outline_modulate", Color(0, 0, 0, 0.5))
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.position = Vector2(screen_size.x - 195, screen_size.y - 30)  # Сдвинул выше
	status_label.z_index = 10
	add_child(status_label)
	
	# Звук (увеличен)
	sound_label = Label.new()
	#sound_label.text = "🔊"
	sound_label.add_theme_font_size_override("font_size", 32)  # Было 22
	sound_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.5, 0.8))  # Ярче
	sound_label.add_theme_color_override("font_outline_modulate", Color(0, 0, 0, 0.5))
	sound_label.add_theme_constant_override("outline_size", 3)
	sound_label.position = Vector2(screen_size.x - 90, screen_size.y - 48)
	sound_label.z_index = 10
	add_child(sound_label)
	
	# === ДЕКОРАТИВНЫЕ ТОЧКИ (увеличены) ===
	var dot1 = create_dot(Color(0.3, 0.9, 0.2, 0.6))
	dot1.position = Vector2(12, screen_size.y - 45)
	add_child(dot1)
	
	var dot2 = create_dot(Color(0.3, 0.9, 0.2, 0.6))
	dot2.position = Vector2(screen_size.x - 210, screen_size.y - 45)
	add_child(dot2)
	
	# Разделительная линия (толще)
	var line = ColorRect.new()
	line.color = Color(0.0, 0.0, 0.0, 0.0)
	line.size = Vector2(screen_size.x - 40, 2)  # Было 1
	line.position = Vector2(20, screen_size.y - 22)  # Сдвинул из-за увеличенных элементов
	line.z_index = 9
	add_child(line)

func create_dot(color: Color) -> Sprite2D:
	var sprite = Sprite2D.new()
	var image = Image.create(14, 14, false, Image.FORMAT_RGBA8)  # Было 10
	image.fill(Color(0, 0, 0, 0))
	
	for x in range(14):
		for y in range(14):
			var dx = x - 7.0
			var dy = y - 7.0
			var dist = sqrt(dx*dx + dy*dy)
			if dist < 7.0:
				var alpha = (1.0 - dist / 7.0) * 0.9
				var col = Color(color.r, color.g, color.b, alpha)
				image.set_pixel(x, y, col)
	
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = true
	sprite.z_index = 10
	return sprite

func _process(delta):
	var screen_size = get_viewport_rect().size
	
	# === FPS ===
	fps_update_timer += delta
	if fps_update_timer >= 0.5:
		fps_update_timer = 0.0
		current_fps = Engine.get_frames_per_second()
		fps_counter.text = "FPS: " + str(current_fps)
		
		if current_fps >= 60:
			fps_counter.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
			status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 0.9))
			status_label.text = "● OPTIMAL"
		elif current_fps >= 30:
			fps_counter.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2, 1.0))
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 0.9))
			status_label.text = "● NORMAL"
		else:
			fps_counter.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
			status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 0.9))
			status_label.text = "● SLOW"
	
	# === МЕРЦАНИЕ ===
	var glow = sin(Time.get_ticks_msec() * 0.002) * 0.1 + 0.9
	version_label.modulate = Color(1, 1, 1, glow * 0.9)
	build_label.modulate = Color(1, 1, 1, glow * 0.9)
	
	# === ИНТЕРАКТИВНЫЙ ЗВУК (клик) ===
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		var sound_rect = Rect2(screen_size.x - 110, screen_size.y - 75, 60, 60)  # Увеличил область клика
		if sound_rect.has_point(mouse_pos):
			is_sound_on = !is_sound_on
			sound_label.text = "🔊" if is_sound_on else "🔇"
			await get_tree().create_timer(0.2).timeout
