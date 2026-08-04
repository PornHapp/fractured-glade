extends Control

@onready var sun = $Sun
@onready var moon = $Moon
@onready var day_night_mask = $DayNightMask
@onready var logo = $UI_Layer/Logo 
@onready var moon_light = $Moon/PointLight2D 
@onready var press_text = $UI_Layer/PressText 
@onready var text_background = $UI_Layer/TextBackground # Ссылка на твою тень!
@onready var fade_rect = $UI_Layer/FadeRect 

var time = 0.0 
var day_duration = 20.0 
var orbit_radius = 250.0 
var center_y = 500.0 
var is_transitioning = false 

func _ready():
	# Прячем всё на старте (включая тень)
	press_text.modulate.a = 0.0
	text_background.modulate.a = 0.0 
	fade_rect.color.a = 0.0

func _process(delta):
	time += delta
	
	# --- ПУЛЬСАЦИЯ ЛОГОТИПА ---
	var pulse = 1.0 + sin(time * 3.0) * 0.03
	logo.scale = Vector2(pulse, pulse)
	
	# --- ТЕКСТ И ТЕНЬ ПЛАВНО ПОЯВЛЯЮТСЯ ЧЕРЕЗ 5 СЕКУНД ---
	if time >= 5.0: 
		# fade_in плавно растет от 0.0 до 1.0 за 2 секунды (с 5-й по 7-ю секунду)
		var fade_in = clamp((time - 5.0) / 2.0, 0.0, 1.0)
		
		# Наше красивое мигание для текста
		var blink = 0.65 + sin(time * 4.0) * 0.35
		
		# Умножаем мигание на плавное появление
		press_text.modulate.a = blink * fade_in
		
		# Если хочешь, чтобы тень тоже мигала вместе с текстом:
		text_background.modulate.a = blink * fade_in
		# (Если хочешь, чтобы тень просто ровно появилась и не мигала, 
		# замени верхнюю строчку на: text_background.modulate.a = fade_in)
	
	
	# --- ДВИЖЕНИЕ СОЛНЦА И ЛУНЫ ---
	var cycle_progress = fmod(time, day_duration) / day_duration
	var angle_sun = cycle_progress * PI * 2
	var angle_moon = angle_sun + PI
	
	sun.position.y = center_y - cos(angle_sun) * orbit_radius
	moon.position.y = center_y - cos(angle_moon) * orbit_radius
	
	var sun_height = cos(angle_sun) 
	
	var day_color = Color(1.0, 1.0, 1.0, 1.0) 
	var evening_color = Color("9c6454")       
	var night_color = Color(0.1, 0.1, 0.3, 1.0) 
	
	if sun_height > 0.0:
		day_night_mask.color = evening_color.lerp(day_color, sun_height)
	else:
		day_night_mask.color = evening_color.lerp(night_color, -sun_height)
	
	moon_light.energy = max(0.0, -sun_height) * 1.5


# --- ПЛАВНЫЙ ПЕРЕХОД ПО КЛИКУ ---
func _input(event):
	# Блокируем клики первые 5 секунд (теперь ждем до 5.0) ИЛИ если переход уже идет
	if time < 5.0 or is_transitioning:
		return
		
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		is_transitioning = true
		
		var tween = get_tree().create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 1.5)
		await tween.finished
		
		get_tree().change_scene_to_file("res://scenes/ui/menu/start_menu.tscn") # Не забудь свой путь!
