class_name ToolItem extends Resource
## Ресурс инструмента: хранит параметры, специфичные для конкретного типа
## инструмента (кирка, топор, молот и т.д.).
##
## Используется AttackState для определения скорости атаки (use_time).
## Создаётся как .tres файл в resources/items/tools/.
##
## Полная спецификация: docs/mvp-items-spec.md (раздел 3.3)


# --- Основные параметры ---

## Уникальный строковый ключ, например "item.stone_pickaxe".
@export var id: StringName = &""
## Отображаемое имя (локализуемое).
@export var display_name: String = ""
## Время между ударами, сек. Определяет скорость повтора атаки
## при зажатой кнопке (как в Terraria).
@export var use_time: float = 0.5
