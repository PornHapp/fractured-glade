extends Control

@onready var name_input = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/HeaderBox/InputsBox/HBoxContainer/LineEdit

@onready var click_sound = $"../../ClickSound"
@onready var hover_sound = $"../../HoverSound"

# --- ВЕРХНИЙ РЯД ---
@onready var seed_input = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/HeaderBox/InputsBox/TopRow/SeedInput
@onready var random_seed_btn = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/HeaderBox/InputsBox/TopRow/RandomSeedButton
@onready var map_icon = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/HeaderBox/MapIcon

# --- КНОПКИ СЛОЖНОСТИ ---
@onready var normal_diff = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/SettingsContainer/DiffContainer/NormalDiff
@onready var hard_diff = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/SettingsContainer/DiffContainer/HardDiff
@onready var expert_diff = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/SettingsContainer/DiffContainer/ExpertDiff

# --- ПАНЕЛЬ ОПИСАНИЯ ---
@onready var desc_panel = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/DescriptionPanel
@onready var desc_text = $CenterGlassMenu/MarginContainer/ScrollContainer/MainColumn/DescriptionPanel/DescriptionText

# --- НИЖНИЕ КНОПКИ ---
@onready var back_btn = $BackButton
@onready var create_world_btn = $CreateWorldButton

# --- ПЕРЕМЕННЫЕ ДЛЯ СОХРАНЕНИЯ ВЫБОРА ---
var selected_difficulty = "diff_normal" # По умолчанию
var selected_size = "size_medium"       # По умолчанию

func _ready():
	_generate_random_seed()
	desc_panel.hide()
	
	random_seed_btn.pressed.connect(_generate_random_seed)
	
	# Подключаем нажатия (сразу показываем описание, меняем картинку и ЗАПОМИНАЕМ выбор)
	normal_diff.pressed.connect(func(): 
		_show_description("desc_diff_normal")
		_change_map_icon("res://меню/Ikon1.png")
		selected_difficulty = "diff_normal"
	)
	
	hard_diff.pressed.connect(func(): 
		_show_description("desc_diff_hard")
		_change_map_icon("res://меню/Ikon2.png")
		selected_difficulty = "diff_hard"
	)
	
	expert_diff.pressed.connect(func(): 
		_show_description("desc_diff_expert")
		_change_map_icon("res://меню/Ikon3.png")
		selected_difficulty = "diff_hardcore"
	)
	
	back_btn.pressed.connect(_on_back_pressed)
	create_world_btn.pressed.connect(_on_create_world_pressed)
	
	var world_buttons = [random_seed_btn, normal_diff, hard_diff, expert_diff, back_btn, create_world_btn]
	for btn in world_buttons:
		btn.mouse_entered.connect(_play_hover_sound)
		btn.pressed.connect(_play_click_sound)

func _generate_random_seed():
	var random_seed = randi_range(100000000, 999999999)
	seed_input.text = str(random_seed)

# Теперь функция просто берет ключ локализации и переводит его!
func _show_description(localization_key: String):
	desc_panel.show()
	desc_text.text = tr(localization_key)

func _on_back_pressed():
	var main_menu = get_parent().get_parent() 
	if main_menu.has_method("back_to_character_menu"):
		main_menu.back_to_character_menu()

func _on_create_world_pressed():
	# --- НОВАЯ ЗАЩИТА: Проверяем, ввел ли игрок имя ---
	# Функция strip_edges() удаляет случайные пробелы (если игрок ввел просто "   ")
	if name_input.text.strip_edges() == "":
		print("Игрок не ввел имя! Ждем...")
		# Можно даже поменять текст-подсказку в поле, чтобы привлечь внимание
		name_input.placeholder_text = "Введите название мира!"
		return # Команда return мгновенно останавливает функцию. Дальше код не пойдет!
	# --- МАГИЯ СОХРАНЕНИЯ ---
	# Упаковываем все данные в Глобал перед тем, как уйти на экран загрузки
	Global.temp_world_data = {
		"world_name": name_input.text,
		"seed": seed_input.text,
		"difficulty": selected_difficulty,
		"size": selected_size,
		"icon_path": map_icon.texture.resource_path,
		"creation_date": Time.get_date_string_from_system() # Сохраняем дату в формате ДД.ММ.ГГГГ
	}
	
	print("Данные переданы в Global! Запуск генерации...")
	get_tree().change_scene_to_file("res://loading_screen.tscn")

func _change_map_icon(path: String):
	var new_texture = load(path)
	if new_texture:
		map_icon.texture = new_texture

func _play_hover_sound():
	if hover_sound: hover_sound.play()

func _play_click_sound():
	if click_sound: click_sound.play()
