extends Node

var config = ConfigFile.new()
var save_path = "user://settings.cfg"

var language_index: int = 0 # По умолчанию 0 (Русский)
var master_volume = 100.0
var sfx_volume = 100.0
var fullscreen = false

# --- Список всех наших действий из Input Map ---
var actions_to_save = [
	"move_left", "move_right", "jump", "attack", "use_item",
	"interact", "skill_1", "skill_2", "skill_3", "walk_slow",
	"inventory", "stats", "global_map", "minimap_toggle", "pause_menu"
]

func _ready():
	load_settings()

func save_settings(master: float, sfx: float, is_fullscreen: bool):
	config.set_value("audio", "master", master)
	config.set_value("audio", "sfx", sfx)
	config.set_value("video", "fullscreen", is_fullscreen)
	
	# ДОБАВЛЕНО: Сохраняем выбранный индекс языка в файл
	config.set_value("locale", "language_index", language_index)
	
	# --- Сохраняем кнопки управления ---
	for action in actions_to_save:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			config.set_value("controls", action, events[0])

	config.save(save_path)
	print("Настройки, управление и язык успешно сохранены в: ", save_path)

func load_settings():
	var err = config.load(save_path)
	if err != OK:
		print("Файл настроек не найден. Используем стандартные.")
		apply_settings()
		return

	master_volume = config.get_value("audio", "master", 100.0)
	sfx_volume = config.get_value("audio", "sfx", 100.0)
	fullscreen = config.get_value("video", "fullscreen", false)
	
	# ДОБАВЛЕНО: Загружаем индекс языка из файла (если его там нет, берем 0)
	language_index = config.get_value("locale", "language_index", 0)
	
	# --- Загружаем кнопки управления ---
	for action in actions_to_save:
		if config.has_section_key("controls", action):
			var saved_event = config.get_value("controls", action)
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, saved_event)

	apply_settings()

func apply_settings():
	# 1. Применяем звук
	var master_bus = AudioServer.get_bus_index("Master")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume / 100.0))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume / 100.0))
	
	# 2. Применяем полноэкранный режим
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	# ДОБАВЛЕНО: Применяем язык локализации в движке при старте игры
	if language_index == 0:
		TranslationServer.set_locale("ru")
	elif language_index == 1:
		TranslationServer.set_locale("en")
