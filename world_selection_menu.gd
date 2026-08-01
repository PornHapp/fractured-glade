extends Control

@onready var back_button = $BackButton
@onready var create_button = $CreateWorldButton
# ПУТЬ К СПИСКУ
@onready var worlds_list = $CenterGlassMenu/MarginContainer/ScrollContainer/WorldsList

# ЗАГРУЖАЕМ ШАБЛОН КНОПКИ
var world_button_scene = preload("res://world_slot_button.tscn")

func _ready():
	load_saved_worlds() # Это твой сканер, он уже тут есть
	
	# Подключаем нажатия
	back_button.pressed.connect(_on_back_pressed)
	create_button.pressed.connect(_on_create_pressed)

func load_saved_worlds():
	# 1. Очищаем список от старого мусора (на всякий случай)
	for child in worlds_list.get_children():
		child.queue_free()
		
	# 2. Открываем системную папку с сохранениями
	var dir_path = "user://worlds"
	var dir = DirAccess.open(dir_path)
	
	if dir:
		# Начинаем перебирать файлы внутри папки
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Если это не папка, а именно файл сохранения:
			if not dir.current_is_dir() and file_name.ends_with(".save"):
				
				# Открываем файл и читаем наш словарь из Global
				var file = FileAccess.open(dir_path + "/" + file_name, FileAccess.READ)
				var saved_data = file.get_var()
				file.close()
				
				# Проверяем, что внутри точно лежат наши данные
				if typeof(saved_data) == TYPE_DICTIONARY:
					
					# Создаем кнопку-аккордеон
					var new_button = world_button_scene.instantiate()
					worlds_list.add_child(new_button)
					
					# --- ВРЕМЕННЫЕ ЗАГЛУШКИ ---
					# Защита, если ты еще не раскомментировала поле "world_name" в меню создания
					if not saved_data.has("world_name"):
						saved_data["world_name"] = "Мир " + saved_data.get("seed", "")
					
					# Совмещаем даты
					if not saved_data.has("date"):
						saved_data["date"] = saved_data.get("creation_date", "Неизвестно")
						
					# Подставляем заглушки для персонажа (потом мы заменим это на реальные файлы персонажей!)
					saved_data["character_name"] = "Странник"
					saved_data["good_traits"] = ["trait_diplomat", "trait_artisan"] # Теперь это список!
					saved_data["bad_traits"] = ["trait_clumsy", "trait_noisy"]
					
					# Сохраняем точный путь к файлу, чтобы кнопка знала, что удалять!
					saved_data["file_path"] = dir_path + "/" + file_name
					
					# Передаем данные в кнопку!
					if new_button.has_method("setup"):
						new_button.setup(saved_data)
						
			# Переходим к следующему файлу в папке
			file_name = dir.get_next()
	else:
		print("Папка с мирами пока пуста или не существует!")

func _on_back_pressed():
	# Прячем список миров
	self.hide() 
	
	# Дергаем главную сцену, чтобы она запустила твою анимацию возврата!
	var start_menu = get_tree().current_scene
	if start_menu.has_method("show_buttons_back"):
		start_menu.show_buttons_back()

func _on_create_pressed():
	# 1. Прячем текущее окно (Список миров)
	self.hide()
	
	# 2. Обращаемся к корню нашей сцены (StartMenu)
	var start_menu = get_tree().current_scene
	
	# 3. Идем по твоему дереву узлов: от корня -> в папку Character -> к CharacterMenu
	var char_menu = start_menu.get_node("Character/CharacterMenu")
	
	# 4. Показываем меню персонажа
	if char_menu:
		char_menu.modulate = Color(1, 1, 1, 1) # Делаем 100% непрозрачным
		char_menu.show()
		char_menu.get_child(0).show() # Твоя строчка из старого кода для показа интерфейса
