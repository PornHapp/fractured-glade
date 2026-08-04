extends Button

@export var action_name: String # Здесь мы будем писать имя действия (например, "jump")

var is_waiting_for_input = false

func _ready():
	# Обновляем текст кнопки при запуске игры, чтобы он показывал текущую клавишу
	update_text()

func _pressed():
	# Когда игрок жмет кнопку, мы активируем режим "ожидания"
	is_waiting_for_input = true
	text = "..."

func _input(event):
	if is_waiting_for_input:
		# Если это нажатие клавиши или кнопки мыши
		if event is InputEventKey or event is InputEventMouseButton:
			# 1. Удаляем старую привязку из Input Map
			InputMap.action_erase_events(action_name)
			# 2. Добавляем новую
			InputMap.action_add_event(action_name, event)
			
			# 3. Выходим из режима ожидания
			is_waiting_for_input = false
			update_text()
			# Прерываем событие, чтобы оно не ушло дальше
			get_viewport().set_input_as_handled()

func update_text():
	# Получаем текущую клавишу
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		# МУСОР УБРАН: Теперь мы пропускаем клавишу через наш красивый фильтр!
		text = format_key_text(events[0])
	else:
		text = "---"

# --- НАШ ФИЛЬТР ДЛЯ КРАСИВОГО ТЕКСТА ---
func format_key_text(event: InputEvent) -> String:
	# Обрабатываем мышку
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			return tr("key_lmb")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			return tr("key_rmb")
			
	# Обрабатываем клавиатуру
	var key_str = event.as_text()
	
	# Убираем все технические слова, которые Godot любит приписывать
	key_str = key_str.replace(" (Physical)", "").replace(" - Physical", "")
	
	return key_str
