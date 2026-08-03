extends Control

# --- УЗЛЫ ИНТЕРФЕЙСА ЗАГРУЗКИ ---
@onready var status_text = $StatusText
@onready var loading_frame = $VBoxContainer/LoadingFrame # Твоя анимированная рамка
@onready var progress_bar_left = $ProgressBarLeft        # Первая полоска (вне VBox)
@onready var progress_bar_right = $ProgressBarRight      # Вторая полоска (вне VBox)

# --- УЗЛЫ ФОНА (ДЕНЬ/НОЧЬ) ---
@onready var sun = $Sun
@onready var moon = $Moon
@onready var day_night_mask = $DayNightMask
@onready var moon_light = $Moon/PointLight2D 

# --- ПЕРЕМЕННЫЕ ДЛЯ НЕБА ---
var time = 12.0 # НАЧИНАЕМ С 12.0 (ЭТО НОЧЬ, БЛИЖЕ К РАССВЕТУ)
var day_duration = 20.0 
var orbit_radius = 250.0 
var center_y = 500.0 

# --- ФРАЗЫ ДЛЯ ЗАГРУЗКИ ---
var loading_phrases = [
	"load_seed",
	"load_resources",
	"load_dirt",
	"load_fluids",
	"load_trees",
	"load_light",
	"load_chests",
	"load_done"
]

var is_cancelled = false 

func _ready():
	# Сбрасываем значения обеих полосок перед стартом
	progress_bar_left.min_value = 0
	progress_bar_left.max_value = 100
	progress_bar_left.value = 0
	
	progress_bar_right.min_value = 0
	progress_bar_right.max_value = 100
	progress_bar_right.value = 0
	
	# Включаем анимацию рамки (убедись, что анимация называется "default", 
	# или впиши свое название в кавычки)
	loading_frame.play("default")
	
	# Запускаем загрузку
	_start_fake_loading()

# --- АНИМАЦИЯ ДНЯ И НОЧИ (Работает каждый кадр) ---
func _process(delta):
	# Время идет вперед, приближая утро
	time += delta
	
	# Формулы орбиты
	var cycle_progress = fmod(time, day_duration) / day_duration
	var angle_sun = cycle_progress * PI * 2
	var angle_moon = angle_sun + PI
	
	# Двигаем Солнце и Луну
	sun.position.y = center_y - cos(angle_sun) * orbit_radius
	moon.position.y = center_y - cos(angle_moon) * orbit_radius
	
	var sun_height = cos(angle_sun) 
	
	# Цвета времени суток
	var day_color = Color(1.0, 1.0, 1.0, 1.0) 
	var evening_color = Color("9c6454")        
	var night_color = Color(0.1, 0.1, 0.3, 1.0) 
	
	# Меняем цвет неба в зависимости от высоты солнца
	if sun_height > 0.0:
		day_night_mask.color = evening_color.lerp(day_color, sun_height)
	else:
		day_night_mask.color = evening_color.lerp(night_color, -sun_height)
	
	# Луна светится только когда солнце внизу
	moon_light.energy = max(0.0, -sun_height) * 1.5


# --- ЛОГИКА ФЕЙКОВОЙ ЗАГРУЗКИ ---
func _start_fake_loading():
	var total_phrases = loading_phrases.size()
	var step_time = 0.8 # Скорость смены фраз
	var progress_step = 100.0 / (total_phrases - 1)
	
	for i in range(total_phrases):
		if is_cancelled:
			return 
			
		status_text.text = tr(loading_phrases[i])
		
		# Плавно двигаем ОБЕ полоски одновременно
		var target_value = i * progress_step
		var tween = create_tween()
		
		tween.set_parallel(true) # <-- Эта магия заставляет полоски ползти вместе!
		
		tween.tween_property(progress_bar_left, "value", target_value, step_time)
		tween.tween_property(progress_bar_right, "value", target_value, step_time)
		
		await get_tree().create_timer(step_time).timeout
		
	if not is_cancelled:
		_finish_loading()

# --- ЕСЛИ НАЖАЛИ "ОТМЕНА" ---
func _on_cancel_pressed():
	is_cancelled = true
	status_text.text = tr("load_cancel")
	
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://start_menu.tscn")

# --- ЕСЛИ ЗАГРУЗКА ДОШЛА ДО 100% ---
func _finish_loading():
	print("Мир успешно сгенерирован!")
	
	# БЕРЕМ ДАННЫЕ ИЗ ГЛОБАЛА И СОХРАНЯЕМ В ФАЙЛ
	if not Global.temp_world_data.is_empty():
		Global.save_new_world(Global.temp_world_data)
		Global.temp_world_data.clear() # Очищаем временные данные
	
	await get_tree().create_timer(1.0).timeout
	Global.return_from_loading = true 
	get_tree().change_scene_to_file("res://start_menu.tscn")
