extends Button

var save_file_path = ""

# --- ПУТИ К ВЫПАДАЮЩЕМУ МЕНЮ ---
@onready var dropdown_menu = $DropdownMenu
@onready var traits_panel = $DropdownMenu/TraitsPanel
@onready var bookmark_btn = $DropdownMenu/BookmarkButton
@onready var traits_text = $DropdownMenu/TraitsPanel/Label

# Вот теперь ставим нашу новую переменную СЮДА, ниже bookmark_btn!
@onready var bookmark_start_y = bookmark_btn.position.y

# Переменные для анимации
var root_closed_height = 0
var is_open = false
var panel_closed_height = 0
var panel_opened_height = 120 # Укажи тут высоту, до которой панель должна разворачиваться
var animation_speed = 0.3

# Пути к нашему тексту
@onready var world_name_label = $MarginContainer/MainRow/TextColumn/HBoxContainer/WorldName
@onready var character_name_label = $MarginContainer/MainRow/TextColumn/HBoxContainer/CharacterName
@onready var stats_label_1 = $MarginContainer/MainRow/TextColumn/StatsRow/Label
@onready var stats_label_2 = $MarginContainer/MainRow/TextColumn/StatsRow/Label2
@onready var date_label = $MarginContainer/MainRow/DateLabel

func _ready():
	# 1. Настройка панели
	traits_panel.clip_contents = true 
	traits_panel.size.y = panel_closed_height
	traits_panel.hide()
	root_closed_height = self.custom_minimum_size.y 
	
	# 2. Звуки (Наведение)
	self.mouse_entered.connect(func(): $HoverSound.play())
	bookmark_btn.mouse_entered.connect(func(): $HoverSound.play())
	
	# 3. Клик (Загрузка мира + звук)
	self.pressed.connect(func(): 
		$ClickSound.play()
		_load_world()
	)
	
	# 4. Ярлычок (Открытие панели + звук)
	bookmark_btn.pressed.connect(_on_bookmark_pressed)
	bookmark_btn.pressed.connect(func(): $ClickSound.play())

func _load_world():
	print("Попытка загрузки: ", save_file_path)
	
	# ПЕРЕД загрузкой сцены передаем путь в Global, чтобы игра знала, что открывать
	if Global.has_method("set_current_save"):
		Global.set_current_save(save_file_path)
	
	## FIXME(Влад): избавиться от хардкода
	var error = get_tree().change_scene_to_file("res://scenes/game_world/main_game.tscn")
	
	if error != OK:
		print("ОШИБКА: Сцена не найдена! Проверь путь: res://scenes/game_world/main_game.tscn")
	else:
		print("Смена сцены инициирована...")

# --- АНИМАЦИЯ ЯРЛЫЧКА ---
func _on_bookmark_pressed():
	is_open = !is_open # Меняем статус
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_open:
		self.z_index = 1 # МАГИЯ 1: Сразу выносим мир на передний план!
		traits_panel.show()
		
		# Раздвигаем невидимый корень (нижние миры сдвинутся вниз)
		tween.tween_property(self, "custom_minimum_size:y", root_closed_height + panel_opened_height, animation_speed)
		
		# Открываем панель и опускаем ярлычок
		tween.parallel().tween_property(traits_panel, "size:y", panel_opened_height, animation_speed)
		tween.parallel().tween_property(bookmark_btn, "position:y", bookmark_start_y + panel_opened_height, animation_speed)
	else:
		# Сворачиваем всё обратно
		tween.tween_property(self, "custom_minimum_size:y", root_closed_height, animation_speed)
		tween.parallel().tween_property(traits_panel, "size:y", panel_closed_height, animation_speed)
		tween.parallel().tween_property(bookmark_btn, "position:y", bookmark_start_y, animation_speed)
		
		# МАГИЯ 2: Выключаем z_index ТОЛЬКО когда анимация закончится
		tween.tween_callback(_on_close_finished)

func _on_create_world_pressed():
	# Поднимаемся к главному меню и просим открыть персонажа
	var main_menu = get_parent() 
	if main_menu.has_method("open_character_creation_from_worlds"):
		main_menu.open_character_creation_from_worlds()

func setup(data: Dictionary):
	if data.has("file_path"): save_file_path = data["file_path"]
	world_name_label.text = data["world_name"]
	character_name_label.text = tr("ui_character_prefix") + " " + data["character_name"]
	stats_label_1.text = tr(data["difficulty"])
	stats_label_2.text = tr(data["size"])
	date_label.text = data["date"]
	
	# --- НОВАЯ УМНАЯ СКЛЕЙКА ЧЕРТ ---
	var good_translated = []
	var bad_translated = []
	
	# Переводим каждую хорошую черту из массива
	if typeof(data["good_traits"]) == TYPE_ARRAY:
		for trait_key in data["good_traits"]:
			good_translated.append(tr(trait_key))
			
	# Переводим каждую плохую черту из массива
	if typeof(data["bad_traits"]) == TYPE_ARRAY:
		for trait_key in data["bad_traits"]:
			bad_translated.append(tr(trait_key))
	
	# Склеиваем их через запятую
	var good_str = "[b]" + tr("ui_good_traits") + " [/b]" + ", ".join(good_translated)
	var bad_str = "[b]" + tr("ui_bad_traits") + " [/b]" + ", ".join(bad_translated)
	
	traits_text.text = good_str + "\n" + bad_str

func _on_close_finished():
	traits_panel.hide()
	self.z_index = 0


# --- ФУНКЦИЯ УДАЛЕНИЯ ---
func _on_delete_button_pressed():
	# Проверяем, есть ли у нас путь к файлу
	if save_file_path != "":
		# Команда remove_absolute удаляет файл напрямую по указанному пути
		DirAccess.remove_absolute(save_file_path)
		print("Файл сохранения навсегда удален: ", save_file_path)
	
	# Уничтожаем саму кнопку с экрана
	queue_free()

# --- ФУНКЦИЯ ЗАКРЕПА (ПИН) ---
func _on_pin_button_pressed():
	# Поднимаем кнопку в самый верх списка (индекс 0)
	var parent = get_parent()
	parent.move_child(self, 0)
	print("Мир закреплен!")
