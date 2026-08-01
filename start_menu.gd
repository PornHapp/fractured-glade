extends Control

@onready var world_selection_menu = $WorldSelectionMenu

var has_saved_worlds = false

# --- УЗЛЫ ИНТЕРФЕЙСА ---
@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var settings_menu = $SettingsMenu
@onready var start_sparks = $VBoxContainer/StartButton/HoverSparks

# Заглушки для будущих окон (пока они могут быть не созданы, но код к ним готов)
@onready var character_menu = $Character/CharacterMenu
@onready var world_menu = $Character/WorldMenu

# --- ЗВУКОВЫЕ УЗЛЫ ---
@onready var dissolve_sound_1 = $DissolveSound
@onready var dissolve_sound_2 = $DissolveSound2
@onready var dissolve_sound_3 = $DissolveSound3

@onready var noise_sound_1 = $NoiseSound
@onready var noise_sound_2 = $NoiseSound2

# Опционально: если добавишь звук наведения и клика
@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

func _ready():
	if Global.return_from_loading:
		# --- МЫ ВЕРНУЛИСЬ ИЗ ЗАГРУЗКИ ---
		$VBoxContainer.hide() 
		
		# Плавно показываем меню миров
		world_selection_menu.modulate = Color(1, 1, 1, 0)
		world_selection_menu.show()
		var fade_tween = create_tween()
		fade_tween.tween_property(world_selection_menu, "modulate", Color(1, 1, 1, 1), 1.5)
		
		Global.return_from_loading = false 
		
	else:
		# --- ОБЫЧНЫЙ ЗАПУСК ИГРЫ ---
		pass
		
	# === ЭТОТ БЛОК ДОЛЖЕН БЫТЬ БЕЗ ОТСТУПА ===
	character_menu.hide()
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Подключаем мышку для искр
	start_button.mouse_entered.connect(_on_start_button_mouse_entered)
	start_button.mouse_exited.connect(_on_start_button_mouse_exited)
	start_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)

func _on_button_hover():
	hover_sound.play()

# --- АНИМАЦИЯ И ЗВУКИ РАСТВОРЕНИЯ ---
func animate_buttons(target_value: float):
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(start_button.material, "shader_parameter/dissolve_value", target_value, 1.5)
	tween.tween_property(settings_button.material, "shader_parameter/dissolve_value", target_value, 1.5)
	tween.tween_property(exit_button.material, "shader_parameter/dissolve_value", target_value, 1.5)
	
	return tween

# Каскадное проигрывание звуков разлома
func play_dissolve_sequence():
	dissolve_sound_1.play()
	await get_tree().create_timer(0.3).timeout # Ждем 0.3 секунды
	dissolve_sound_2.play()
	await get_tree().create_timer(0.4).timeout
	dissolve_sound_3.play()

# Каскадное проигрывание шума
func play_noise_sequence():
	noise_sound_1.play()
	await get_tree().create_timer(0.5).timeout
	noise_sound_2.play()

# --- ЛОГИКА КНОПОК ---

func _on_start_pressed():
	click_sound.play()
	
	# 1. Резко обрываем глобальную музыку
	if has_node("/root/MusicManager"):
		MusicManager.get_child(0).stop()
	
	# 2. Запускаем звуки разлома и шума параллельно с анимацией
	play_dissolve_sequence()
	play_noise_sequence()
	
	# 3. Растворяем кнопки
	var tween = animate_buttons(1.0)
	
	# 4. Также анимируем глитч фона (если он есть в сцене)
	if has_node("LightBackground"):
		var bg_tween = create_tween()
		bg_tween.tween_property($LightBackground.material, "shader_parameter/transition_progress", 1.0, 1.5)
	
	# --- 5. МАГИЯ СКАНИРОВАНИЯ (работает, пока крутятся анимации) ---
	var has_saved_worlds = false
	var dir_path = "user://worlds"
	
	if DirAccess.dir_exists_absolute(dir_path):
		var files = DirAccess.get_files_at(dir_path)
		for file in files:
			if file.ends_with(".save"):
				has_saved_worlds = true
				break # Нашли хотя бы один мир — ура!
	
	# Ждем завершения растворения кнопок
	await tween.finished 
	
	# --- 6. ЛОГИКА СТАРТА ---
	if has_saved_worlds:
		# Если миры есть, показываем окно ВЫБОРА МИРОВ
		world_selection_menu.modulate = Color(1, 1, 1, 0)
		world_selection_menu.show()
		var fade_tween = create_tween()
		fade_tween.tween_property(world_selection_menu, "modulate", Color(1, 1, 1, 1), 1.5)
	else:
		# Если миров нет (новичок), показываем окно СОЗДАНИЯ ПЕРСОНАЖА
		var char_control = character_menu.get_child(0)
		char_control.modulate = Color(1, 1, 1, 0)
		character_menu.show()
		char_control.show()
		var fade_tween = create_tween()
		fade_tween.tween_property(char_control, "modulate", Color(1, 1, 1, 1), 1.5)

func open_character_creation_from_worlds():
	world_selection_menu.hide() # Прячем список миров
	character_menu.show()       # Показываем создание персонажа

func _on_settings_pressed():
	click_sound.play()
	play_dissolve_sequence() # Запускаем треск кнопок
	
	var tween = animate_buttons(1.0)
	await tween.finished
	
	settings_menu.show()

func _on_exit_pressed():
	click_sound.play()
	play_dissolve_sequence()
	
	var tween = animate_buttons(1.0)
	await tween.finished
	get_tree().quit()

# Возврат кнопок из других меню (Настройки, Выбор персонажа, Выбор мира)
func show_buttons_back():
	# 1. Прячем настройки (они закрываются резко, как и открывались)
	settings_menu.hide()
	
	# 2. Если открыто окно персонажа — плавно растворяем его
	if character_menu.visible:
		var char_control = character_menu.get_child(0)
		var fade_tween = create_tween()
		# Плавно уводим в прозрачность за 1 секунду
		fade_tween.tween_property(char_control, "modulate", Color(1, 1, 1, 0), 1.0)
		await fade_tween.finished # Ждем, пока окно полностью исчезнет
		character_menu.hide() # И только потом выключаем сам узел
	
	# --- ВОЗВРАЩАЕМ ГЛАВНОЕ МЕНЮ ---
	
	# 3. Возвращаем музыку (если она была выключена)
	if has_node("/root/MusicManager"):
		var music_player = MusicManager.get_child(0)
		if not music_player.playing:
			music_player.play()
			
	# 4. Возвращаем оригинальный фон (откатываем глитч/эффект)
	if has_node("LightBackground"):
		var bg_tween = create_tween()
		bg_tween.tween_property($LightBackground.material, "shader_parameter/transition_progress", 0.0, 1.5)
		
	# 5. Собираем осколки кнопок обратно!
	animate_buttons(0.0)

# --- ИСКРЫ ПРИ НАВЕДЕНИИ ---
func _on_start_button_mouse_entered():
	start_sparks.emitting = true
	# Опционально: hover_sound.play()

func _on_start_button_mouse_exited():
	start_sparks.emitting = false

# Функция плавного перехода к созданию мира
func open_world_menu():
	# Прячем окно персонажа
	if character_menu.visible:
		character_menu.hide()
	
	# Показываем окно мира
	world_menu.show()

# Функция возврата от создания мира обратно к персонажу
func back_to_character_menu():
	# Прячем окно мира
	if world_menu.visible:
		world_menu.hide()
	
	# Снова показываем окно персонажа
	character_menu.show()


func _on_small_size_pressed():
	$ClickSound.play()


func _on_medium_size_pressed():
	$ClickSound.play()


func _on_large_size_pressed():
	$ClickSound.play()
