extends Control

@onready var click_sound = $"../../ClickSound"
@onready var hover_sound = $"../../HoverSound"
# --- УЗЛЫ ИНТЕРФЕЙСА ---
@onready var name_input = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/NameInput
@onready var race_select = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/RaceSelectButton
@onready var random_btn = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/RandomButton

@onready var char_image = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/VisualColumn/HBoxContainer/CharacterImage
@onready var left_btn = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/VisualColumn/HBoxContainer/LeftButton
@onready var right_btn = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/VisualColumn/HBoxContainer/RightButton

# Наши новые контейнеры и счетчики
@onready var good_list = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/TraitsSplit/GoodColumn/GoodTraitsList
@onready var bad_list = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/TraitsSplit/BadColumn/BadTraitsList

@onready var good_count_label = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/HBoxContainer/GoodCountLabel
@onready var bad_count_label = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/HBoxContainer/BadCountLabel
@onready var sandbox_toggle = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/SandboxToggle

# Справочник
@onready var info_button = $CenterGlassMenu/MarginContainer/ScrollContainer/VBoxContainer/MainSplit/StatsColumn/TraitsSplit/InfoButton
@onready var info_panel = $InfoPanel
@onready var info_text = $InfoPanel/InfoText

@onready var next_btn = $NextButton
@onready var cancel_btn = $CancelButton

# --- ПЕРЕМЕННЫЕ ПЕРСОНАЖА ---
var is_male = true
var current_race_index = 0

# База данных рас с описанием механик для всплывающих подсказок
var races_data = [
	{
		"name": "race_human",
		"file_prefix": "human",
		"good_traits": {
			"trait_diplomat": "desc_diplomat",
			"trait_endurant": "desc_endurant",
			"trait_crafter": "desc_crafter",
			"trait_sleep": "desc_sleep",
			"trait_lucky": "desc_lucky",
			"trait_metabolism": "desc_metabolism",
			"trait_stride": "desc_stride"
		},
		"bad_traits": {
			"trait_fragile_magic": "desc_fragile_magic",
			"trait_coward": "desc_coward",
			"trait_glutton": "desc_glutton",
			"trait_slow_heal": "desc_slow_heal",
			"trait_clumsy": "desc_clumsy",
			"trait_noisy": "desc_noisy",
			"trait_heavy_pockets": "desc_heavy_pockets"
		}
	},
	{
		"name": "race_astral",
		"file_prefix": "astral",
		"good_traits": {
			"trait_astronav": "desc_astronav",
			"trait_cygnus": "desc_cygnus",
			"trait_levitation": "desc_levitation",
			"trait_night_vis": "desc_night_vis",
			"trait_stardust": "desc_stardust",
			"trait_cosmic_en": "desc_cosmic_en",
			"trait_composure": "desc_composure"
		},
		"bad_traits": {
			"trait_photophobia": "desc_photophobia",
			"trait_fragile_bone": "desc_fragile_bone",
			"trait_outsider": "desc_outsider",
			"trait_insomnia": "desc_insomnia",
			"trait_magic_hunger": "desc_magic_hunger",
			"trait_grav_weak": "desc_grav_weak",
			"trait_loner": "desc_loner"
		}
	},
	{
		"name": "race_mage",
		"file_prefix": "mage",
		"good_traits": {
			"trait_deep_res": "desc_deep_res",
			"trait_alchemist": "desc_alchemist",
			"trait_rune_read": "desc_rune_read",
			"trait_quick_cast": "desc_quick_cast",
			"trait_ethereal_vis": "desc_ethereal_vis",
			"trait_light_step": "desc_light_step",
			"trait_magic_shield": "desc_magic_shield"
		},
		"bad_traits": {
			"trait_frail_body": "desc_frail_body",
			"trait_heavy_metal": "desc_heavy_metal",
			"trait_migraine": "desc_migraine",
			"trait_magic_addict": "desc_magic_addict",
			"trait_bad_hearing": "desc_bad_hearing",
			"trait_fragile_weap": "desc_fragile_weap",
			"trait_bright_aura": "desc_bright_aura"
		}
	},
	{
		"name": "race_nature",
		"file_prefix": "nature",
		"good_traits": {
			"trait_nature_child": "desc_nature_child",
			"trait_forest_str": "desc_forest_str",
			"trait_herbalist": "desc_herbalist",
			"trait_symbiosis": "desc_symbiosis",
			"trait_forest_brth": "desc_forest_brth",
			"trait_poison_skin": "desc_poison_skin",
			"trait_leaf_whisper": "desc_leaf_whisper"
		},
		"bad_traits": {
			"trait_wood_blood": "desc_wood_blood",
			"trait_technophobe": "desc_technophobe",
			"trait_vegan": "desc_vegan",
			"trait_dungeon_fear": "desc_dungeon_fear",
			"trait_soft_tissue": "desc_soft_tissue",
			"trait_sun_depend": "desc_sun_depend",
			"trait_pacifist": "desc_pacifist"
		}
	},
	{
		"name": "race_mech",
		"file_prefix": "mech",
		"good_traits": {
			"trait_scrapper": "desc_scrapper",
			"trait_demolition": "desc_demolition",
			"trait_engineer": "desc_engineer",
			"trait_iron_grip": "desc_iron_grip",
			"trait_plating": "desc_plating",
			"trait_steam_dash": "desc_steam_dash",
			"trait_mech_eye": "desc_mech_eye"
		},
		"bad_traits": {
			"trait_heavyweight": "desc_heavyweight",
			"trait_loud_steps": "desc_loud_steps",
			"trait_coal_depend": "desc_coal_depend",
			"trait_clumsiness": "desc_clumsiness",
			"trait_short_circ": "desc_short_circ",
			"trait_poor_vision": "desc_poor_vision",
			"trait_bad_compass": "desc_bad_compass"
		}
	},
	{
		"name": "race_spark",
		"file_prefix": "spark",
		"good_traits": {
			"trait_lantern": "desc_lantern",
			"trait_light_speed": "desc_light_speed",
			"trait_feather": "desc_feather",
			"trait_elusive": "desc_elusive",
			"trait_purify": "desc_purify",
			"trait_ethereal": "desc_ethereal",
			"trait_warmth": "desc_warmth"
		},
		"bad_traits": {
			"trait_tiny_hp": "desc_tiny_hp",
			"trait_dark_bait": "desc_dark_bait",
			"trait_wind_vuln": "desc_wind_vuln",
			"trait_hydrophobia": "desc_hydrophobia",
			"trait_weak_melee": "desc_weak_melee",
			"trait_en_hunger": "desc_en_hunger",
			"trait_blind_flash": "desc_blind_flash"
		}
	}
]

func _ready():
	# 1. Заполняем выпадающий список рас
	race_select.clear()
	for race in races_data:
		race_select.add_item(race["name"])
	
	# 2. Подключаем кнопки
	race_select.item_selected.connect(_on_race_selected)
	left_btn.pressed.connect(_toggle_gender)
	right_btn.pressed.connect(_toggle_gender)
	random_btn.pressed.connect(_on_random_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed) # <--- ВОТ НАША НОВАЯ СТРОЧКА
	
	sandbox_toggle.toggled.connect(_on_sandbox_toggled)
	info_button.pressed.connect(_on_info_button_pressed)

	# 3. Стартовый вид
	_update_character_ui()
	var all_buttons = [next_btn, cancel_btn, left_btn, right_btn, random_btn, info_button]
	for btn in all_buttons:
		btn.mouse_entered.connect(_play_hover_sound)
		btn.pressed.connect(_play_click_sound)

func _on_cancel_pressed():
	# Поднимаемся на 2 уровня вверх: от Control -> к CanvasLayer -> к StartMenu
	var main_menu = get_parent().get_parent() 
	
	# Если мы сейчас в Главном меню, проигрываем возврат
	if main_menu.has_method("show_buttons_back"):
		main_menu.show_buttons_back()
	else:
		# На будущее: если мы будем в меню создания мира, 
		# здесь будет логика возврата на предыдущий экран
		print("Возвращаемся назад...")

# --- ЛОГИКА ГЕНЕРАЦИИ КНОПОК-ХАРАКТЕРИСТИК ---
func _fill_traits_lists():
	# Удаляем старые кнопки
	for child in good_list.get_children(): child.queue_free()
	for child in bad_list.get_children(): child.queue_free()
	
	var current_race = races_data[current_race_index]
	
	# --- ДЕЛАЕМ КРАСИВЫЙ СВЕТЛЫЙ СТИЛЬ ДЛЯ НАЖАТИЯ ---
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.85, 0.85, 0.85) # Почти белый/светло-серый
	pressed_style.corner_radius_top_left = 4         # Скругляем края, чтобы было красиво
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_left = 4
	pressed_style.corner_radius_bottom_right = 4

	# Создаем хорошие кнопки
	for trait_name in current_race["good_traits"]:
		var btn = Button.new()
		btn.text = trait_name
		btn.toggle_mode = true
		
		# Встраиваем светлый стиль при нажатии
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_stylebox_override("hover_pressed", pressed_style)
		btn.add_theme_color_override("font_pressed_color", Color.BLACK) # Черный текст
		btn.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
		
		btn.toggled.connect(_on_trait_toggled)
		good_list.add_child(btn)
		
	# Создаем плохие кнопки
	for trait_name in current_race["bad_traits"]:
		var btn = Button.new()
		btn.text = trait_name
		btn.toggle_mode = true
		
		# Встраиваем светлый стиль при нажатии
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_stylebox_override("hover_pressed", pressed_style)
		btn.add_theme_color_override("font_pressed_color", Color.BLACK)
		btn.add_theme_color_override("font_hover_pressed_color", Color.BLACK)
		
		btn.toggled.connect(_on_trait_toggled)
		bad_list.add_child(btn)
		
	_update_counters()
	if info_panel.visible: _update_info_text()

func _on_trait_toggled(toggled_on: bool):
	_update_counters()

# --- ЛОГИКА СЧЕТЧИКОВ И БАЛАНСА ---
func _update_counters():
	var good_count = 0
	var bad_count = 0
	
	# Считаем нажатые кнопки
	for btn in good_list.get_children():
		if btn.button_pressed: good_count += 1
		
	for btn in bad_list.get_children():
		if btn.button_pressed: bad_count += 1
		
	good_count_label.text = tr("ui_good_traits") + " " + str(good_count)
	bad_count_label.text = tr("ui_bad_traits") + " " + str(bad_count)
	
	var is_sandbox = sandbox_toggle.button_pressed
	
	if is_sandbox:
		good_count_label.modulate = Color.WHITE
		bad_count_label.modulate = Color.WHITE
	else:
		# Красим в красный, если меньше 2 или количество не совпадает
		if good_count < 2 or good_count != bad_count:
			good_count_label.modulate = Color.RED
		else:
			good_count_label.modulate = Color.WHITE
			
		if bad_count < 2 or bad_count != good_count:
			bad_count_label.modulate = Color.RED
		else:
			bad_count_label.modulate = Color.WHITE

func _on_sandbox_toggled(toggled_on: bool):
	_update_counters()

# --- ЛОГИКА СПРАВОЧНИКА ---
func _on_info_button_pressed():
	info_panel.visible = !info_panel.visible
	if info_panel.visible:
		_update_info_text()

func _update_info_text():
	var current_race = races_data[current_race_index]
	var final_text = tr("ui_good_traits_hdr")
	
	for trait_key in current_race["good_traits"]:
		final_text += "[b]" + tr(trait_key) + "[/b] — " + tr(current_race["good_traits"][trait_key]) + "\n"
		
	final_text += "\n" + tr("ui_bad_traits_hdr")
	
	for trait_key in current_race["bad_traits"]:
		final_text += "[b]" + tr(trait_key) + "[/b] — " + tr(current_race["bad_traits"][trait_key]) + "\n"
		
	info_text.text = final_text

# --- ПРОВЕРКА ПЕРЕД СТАРТОМ (МИНИМУМ 2 и РАВЕНСТВО) ---
func _on_next_pressed():
	var good_count = 0
	var bad_count = 0
	
	for btn in good_list.get_children():
		if btn.button_pressed: good_count += 1
	for btn in bad_list.get_children():
		if btn.button_pressed: bad_count += 1
		
	if name_input.text == "":
		print("Введи имя персонажа!")
		return
		
	if not sandbox_toggle.button_pressed:
		var has_error = false
		if good_count < 2 or good_count != bad_count:
			_pulse_label(good_count_label)
			has_error = true
		if bad_count < 2 or bad_count != good_count:
			_pulse_label(bad_count_label)
			has_error = true
			
		if has_error:
			return # Останавливаем переход
			
	print("Персонаж создан по всем правилам! Идем дальше...")
	# Добавляем еще один .get_parent() !
	var main_menu = get_parent().get_parent() 
	
	if main_menu.has_method("open_world_menu"):
		main_menu.open_world_menu()

# Анимация ошибки (пульсация)
func _pulse_label(label: Node):
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

# Остальные стандартные функции (смена пола, картинки)
func _on_race_selected(index: int):
	current_race_index = index
	_update_character_ui()

func _toggle_gender():
	is_male = !is_male
	_update_character_image()

func _update_character_ui():
	_update_character_image()
	_fill_traits_lists()

func _update_character_image():
	var prefix = races_data[current_race_index]["file_prefix"]
	var suffix = "_m.png" if is_male else "_f.png"
	var image_path = "res://assets/textures/player/" + prefix + suffix
	if ResourceLoader.exists(image_path):
		char_image.texture = load(image_path)

func _on_random_pressed():
	is_male = randf() > 0.5
	current_race_index = randi() % races_data.size()
	race_select.select(current_race_index)
	
	# Перерисовываем интерфейс (здесь дается команда удалить старые кнопки)
	_update_character_ui()
	
	# 🛑 МАГИЧЕСКАЯ СТРОЧКА: Ждем ровно 1 кадр, чтобы старые кнопки стерлись навсегда!
	await get_tree().process_frame
	
	# Заменили русские имена на ключи
	var random_names = ["name_rand_1", "name_rand_2", "name_rand_3", "name_rand_4", "name_rand_5"]
	name_input.text = tr(random_names.pick_random())

	# --- ИДЕАЛЬНЫЙ РАНДОМ ХАРАКТЕРИСТИК ---
	var num_traits = randi_range(2, 7)
	
	# Собираем ТОЛЬКО новые кнопки (призраков больше нет)
	var good_btns = good_list.get_children()
	var bad_btns = bad_list.get_children()
	
	# Тасуем колоду кнопок
	good_btns.shuffle()
	bad_btns.shuffle()
	
	# Прокликиваем случайные кнопки
	for i in range(num_traits):
		if i < good_btns.size():
			good_btns[i].button_pressed = true
		if i < bad_btns.size():
			bad_btns[i].button_pressed = true

func _play_hover_sound():
	if hover_sound: hover_sound.play()

func _play_click_sound():
	if click_sound: click_sound.play()
