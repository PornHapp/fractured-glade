extends Node
## Реестр инструментов (Autoload). Загружает ToolItem ресурсы из
## resources/items/tools/ и предоставляет доступ по ID.
##
## Используется AttackState для получения use_time текущего инструмента.
## Паттерн: Service Locator (см. CLAUDE.md §3.4).


# --- Внутреннее состояние ---

## Словарь ToolItem по ID: StringName -> ToolItem
var _tools: Dictionary = {}


# --- Инициализация ---

func _ready() -> void:
	_load_tools()


# --- Публичный API ---

## Возвращает ToolItem по имени. Если инструмент не найден,
## возвращает null (вызывающий код использует fallback).
## @param tool_name - ID инструмента (StringName)
## @return ToolItem или null
func get_tool(tool_name: StringName) -> ToolItem:
	return _tools.get(tool_name, null)


# --- Загрузка ---

## Рекурсивно загружает все .tres файлы из resources/items/tools/.
func _load_tools() -> void:
	var dir: DirAccess = DirAccess.open("res://resources/items/tools/")
	if not dir:
		push_warning("ToolItemRegistry: директория resources/items/tools/ не найдена")
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource: Resource = load("res://resources/items/tools/" + file_name)
			if resource is ToolItem:
				_tools[resource.id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()
