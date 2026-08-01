extends CanvasLayer

@onready var language_btn = $Control/CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock4/MarginContainer/VBoxContainer/HBoxContainer/OptionButton
@onready var nickname_input = $Control/RightGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer/NicknameInput
@onready var ip_input = $Control/RightGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer2/IpInput
@onready var password_input = $Control/RightGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer3/PasswordInput
@onready var host_button = $Control/RightGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer5/HostButton
@onready var join_button = $Control/RightGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer5/JoinButton
@onready var fullscreen_toggle = $Control/CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock2/MarginContainer/VBoxContainer/HBoxContainer/FullscreenToggle
@onready var save_exit_button = $Control/SaveAndExitButton

@onready var master_slider = $Control/CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer/MasterSlider
@onready var sfx_slider = $Control/CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/AudioBlock/MarginContainer/VBoxContainer/HBoxContainer2/SfxSlider

@onready var hover_sound = $SettingsHoverSound
@onready var click_sound = $SettingsClickSound

var master_bus = AudioServer.get_bus_index("Master")
var sfx_bus = AudioServer.get_bus_index("SFX")

func _ready():
	# Загружаем сохраненный язык
	var saved_lang = SettingsManager.language_index # Убедись, что добавила эту переменную в SettingsManager!
	language_btn.select(saved_lang)
	_on_language_option_button_item_selected(saved_lang) # Применяем его
	language_btn.item_selected.connect(_on_language_option_button_item_selected)
	# Подключаем ползунки громкости
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	# Запускаем МАГИЮ: автоматическое добавление звуков на весь интерфейс!
	setup_ui_sounds(self)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	# 1. Подключаем нажатие на кнопку выхода
	save_exit_button.pressed.connect(_on_save_exit_pressed)
	
	# 2. Подключаем переключатель полного экрана
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	
	# 3. Синхронизируем галочку (чтобы она была нажата, если игра УЖЕ в полном экране)
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		fullscreen_toggle.button_pressed = true
	else:
		fullscreen_toggle.button_pressed = false
	# НОВОЕ: Подтягиваем сохраненные значения из SettingsManager
	# Чтобы при открытии меню ползунки и галочка уже стояли правильно
	master_slider.value = SettingsManager.master_volume
	sfx_slider.value = SettingsManager.sfx_volume
	# Если у тебя есть галочка полного экрана (замени fullscreen_toggle на своё имя узла)
	fullscreen_toggle.button_pressed = SettingsManager.fullscreen
	# Подтягиваем сохраненный язык в выпадающую кнопку при старте
	language_btn.select(SettingsManager.language_index)

# --- ФУНКЦИИ ГРОМКОСТИ ---
func _on_master_changed(value: float):
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0))

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value / 100.0))

# --- АВТОМАТИЗАЦИЯ ЗВУКОВ ИНТЕРФЕЙСА ---
# Этот скрипт сам обходит все элементы в окне настроек
func setup_ui_sounds(node: Node):
	for child in node.get_children():
		# Если это любая кнопка (включая галочки)
		if child is BaseButton: 
			child.mouse_entered.connect(_play_hover)
			child.pressed.connect(_play_click)
		
		# Если это ползунок
		elif child is Slider:
			child.mouse_entered.connect(_play_hover)
			# При отпускании мышки с ползунка издаем щелчок
			child.drag_ended.connect(_play_slider_click)
			
		# Запускаем функцию внутри самой себя, чтобы проверить детей этого узла
		setup_ui_sounds(child)

func _play_hover():
	hover_sound.play()

func _play_click():
	click_sound.play()

func _play_slider_click(value_changed: bool):
	if value_changed:
		click_sound.play()

func _on_host_pressed():
	var nickname = nickname_input.text
	var password = password_input.text
	print("Создаем сервер с ником: ", nickname)
	# Здесь позже пропишем: ENetMultiplayerPeer.create_server(...)

func _on_join_pressed():
	var ip = ip_input.text
	var nickname = nickname_input.text
	print("Подключаемся к: ", ip, " под ником: ", nickname)
	# Здесь позже пропишем: ENetMultiplayerPeer.create_client(...)

# Функция переключения экрана
func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		# Включаем полный экран
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		# Возвращаем оконный режим
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Твоя функция кнопки "Сохранить и выйти"
func _on_save_exit_pressed():
	# 1. 100% проигрываем звук клика
	click_sound.play()
	
	# 2. Собираем текущие значения с ползунков и галочки
	var current_master = master_slider.value
	var current_sfx = sfx_slider.value
	
	# (Если галочки экрана нет в скрипте, просто передай SettingsManager.fullscreen или false)
	var is_fullscreen = fullscreen_toggle.button_pressed

	# 3. Отправляем в SettingsManager приказ сохранить это в файл!
	SettingsManager.save_settings(current_master, current_sfx, is_fullscreen)
	
	print("Сохраняем игру и закрываем настройки...") 
	self.hide() # Прячем настройки
	
	# Возвращаем кнопки главного меню
	if get_parent().has_method("show_buttons_back"):
		get_parent().show_buttons_back()

func _on_language_option_button_item_selected(index):
	if index == 0:
		TranslationServer.set_locale("ru")
	elif index == 1:
		TranslationServer.set_locale("en")
	
	# Сохраняем индекс языка (0 или 1) в менеджер настроек!
	SettingsManager.language_index = index

# Функция для красивого отображения кнопок
func format_key_text(event: InputEvent) -> String:
	# Обрабатываем мышку
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			return tr("key_lmb")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			return tr("key_rmb")
			
	# Обрабатываем клавиатуру (убираем слово Physical)
	var text = event.as_text()
	text = text.replace(" (Physical)", "").replace(" - Physical", "")
	return text
