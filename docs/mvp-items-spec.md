# Спецификация №1: Система Предметов (Item System)

## 1. Назначение

Система предметов — ядро игровой экономики. Описывает все объекты, которые могут существовать в инвентаре, мире или крафте. Обеспечивает гибкое расширение за счёт композиции и чёткого разделения данных (Resource) и логики.

---

## 2. Базовые принципы

- **Данные — в Resource.** Каждый предмет — отдельный файл `.tres` с уникальным строковым идентификатором (ID).  
- **Композиция через компоненты** (в будущем — система модификаторов и рун).  
- **Строгая типизация** всех полей и методов.  
- **Подготовка к мультиплееру:** предметы неизменяемы; состояние (количество, прочность, руны) хранится отдельно в стеках инвентаря.  
- **Минимум хардкода:** все пути к ассетам, значения параметров — только через экспортированные поля или загрузку из ресурсов.

---

## 3. Иерархия классов

### 3.1. Базовый класс — `ItemBase` (extends Resource)

```gdscript
class_name ItemBase
extends Resource

@export var id: String = ""              # уникальный строковый ключ, например "item.wood"
@export var display_name: String = ""    # локализуемое имя
@export var icon: Texture2D              # иконка для UI
@export var type: ItemType               # категория (см. enum)
@export var max_stack: int = 999         # максимум в одном стеке
@export var usable: bool = false         # можно ли использовать (ПКМ по иконке)
@export var required_biome: BiomeType = BiomeType.NONE   # ограничение по макробиому (опционально)
@export var rune_slots: int = 0          # количество слотов для рун (0..5)
@export var can_break_grass: bool = false # может ли рубить траву/кусты (как меч в Terraria)
```

**Enum `ItemType`:**

```gdscript
enum ItemType {
    MATERIAL,     # ресурсы (дерево, руда, камень)
    BLOCK,        # строительные блоки
    TOOL,         # инструменты (кирка, топор, молот)
    WEAPON,       # оружие (меч, копьё)
    ACCESSORY,    # аксессуары (будущее)
    CONSUMABLE,   # расходники (зелья, еда)
    FURNITURE,    # мебель (верстак, сундук)
    RUNE,         # сами руны (вставляются в предметы)
}
```

### 3.2. Подкласс `BlockItem` (для блоков)

```gdscript
class_name BlockItem
extends ItemBase

@export var tile_light: TileSetAtlasSource   # спрайт в макробиоме Свет
@export var tile_dark: TileSetAtlasSource    # спрайт в макробиоме Тьма
@export var breakable: bool = true
@export var required_power: int = 0          # минимальная сила инструмента для добычи (0 — любым)
@export var drop_on_break: String = ""       # ID предмета, который выпадает при разрушении (по умолчанию сам блок)
```

### 3.3. Подкласс `ToolItem` (для инструментов — кирка, топор, молот)

```gdscript
class_name ToolItem
extends ItemBase

@export var tool_type: ToolType
@export var power: int = 1                # сила добычи блоков (влияет на скорость и возможность добычи)
@export var damage: int = 2               # урон при ударе по врагу (стандартный для всех инструментов)
@export var use_time: float = 0.5         # время между ударами (сек)
@export var speed_multiplier: float = 1.0 # множитель скорости анимации (для инструментов)

enum ToolType {
    PICKAXE,
    AXE,
    HAMMER,
    HOE,       # будущее
    FISHING,   # будущее
}
```

### 3.4. Подкласс `WeaponItem` (для оружия — меч, копьё и т.д.)

```gdscript
class_name WeaponItem
extends ItemBase

@export var damage: int = 5
@export var use_time: float = 0.3
@export var knockback: float = 1.0
@export var range: float = 1.5           # радиус атаки (в тайлах)
@export var projectile_id: String = ""   # ID снаряда, если оружие дальнего боя (будущее)
@export var ammo_type: String = ""       # тип используемых боеприпасов (будущее)
@export var special_effect: String = ""  # например, "fire", "poison" — для системы эффектов
```

**Решение:** инструменты тоже наносят урон (поле `damage`), но оружие специализируется на бою и имеет больше параметров (knockback, range, эффекты). Меч в Terraria рубит траву — для этого у базового `ItemBase` есть флаг `can_break_grass`. В будущем можно добавить интерфейс `IChoppable` или компонент.

### 3.5. Подкласс `MaterialItem` (для материалов)

```gdscript
class_name MaterialItem
extends ItemBase
# не добавляет новых полей, только наследует базовые
```

### 3.6. Подкласс `FurnitureItem` (для верстака, сундука)

```gdscript
class_name FurnitureItem
extends ItemBase

@export var placed_scene: PackedScene   # сцена, которая создаётся при установке в мире
@export var is_storage: bool = false    # является ли хранилищем (для сундука)
@export var storage_capacity: int = 0   # количество слотов, если is_storage = true
```

### 3.7. Подкласс `RuneItem` (для рун — модификаторов)

```gdscript
class_name RuneItem
extends ItemBase

@export var rune_type: RuneType
@export var bonus_value: float = 0.0
@export var duration: float = 0.0       # 0 = постоянный эффект
@export var stackable: bool = true      # руны могут стакаться до определённого лимита (но обычно нет)

enum RuneType {
    DAMAGE_BONUS,        # +x% урона
    SPEED_BONUS,         # +x% скорости атаки/добычи
    CRIT_CHANCE,         # +x% крит. шанс
    ELEMENTAL_FIRE,      # добавляет урон огнём
    ELEMENTAL_ICE,       # замедляет врагов
    LIFE_STEAL,          # вампиризм
    KNOCKBACK_BONUS,     # +x% отбрасывания
    DURABILITY_BONUS,    # +x% к прочности (будущее)
}
```

---

## 4. Управление предметами — `ItemRegistry` (Autoload)

- Загружает все `.tres` из папки `resources/items/` при старте.
- Предоставляет статический словарь `items: Dictionary[String, ItemBase]`.
- Метод `get_item(id: String) -> ItemBase` с кешированием.
- В будущем можно добавить горячую перезагрузку ресурсов для отладки.

**Вопрос об ID:** используем строки. Это удобно для читаемости, отладки и локализации. Производительность словаря по строковым ключам в GDScript достаточна для MVP. При необходимости в будущем можно ввести внутреннее числовое отображение без изменения API.

**О preload:** в ресурсах используем `preload` для иконок и атласов — это стандартная практика Godot, не считается хардкодом, так как путь задаётся в инспекторе. Для динамической загрузки можно использовать `load()`, но для ресурсов, которые всегда нужны, `preload` предпочтительнее.

---

## 5. Фабрика стеков — `ItemStackFactory`

Создаёт объекты `ItemStack` (см. спецификацию инвентаря) на основе ID и количества. При создании проверяет наличие предмета в реестре и копирует базовые параметры (max_stack и т.д.).

---

## 6. Поддержка макробиомов для блоков

- Каждый `BlockItem` хранит два разных набора тайлов (или один атлас с разными регионами).
- При рендеринге мира система выбирает нужный тайл в зависимости от текущего макробиома (хранится в `WorldManager`).
- Если у блока есть особое поведение во Тьме (например, замедление), это реализуется через компонент `BiomeBehavior`, который добавляется к блоку в мире, а не в самом `ItemBase`.

---

## 7. Крафт (рецепты) — отдельный модуль

Рецепты хранятся как `RecipeResource` с полями:  

- `result_id: String`  
- `ingredients: Array[Dictionary]` (например, `[{"id":"item.wood", "count":10}]`)  
- `required_station: String` (ID станка, например `"crafting_table"`)  
- `required_biome: BiomeType = BiomeType.NONE` (для будущего)

Рецепты загружаются отдельным `RecipeRegistry`. В MVP рецепты могут быть захардкожены в коде, но для масштабирования лучше вынести в ресурсы.

---

## 8. Примеры ресурсов

**`item.wood.tres`**

```gdscript
extends MaterialItem
id = "item.wood"
display_name = "Древесина"
icon = preload("res://assets/textures/items/wood.png")
type = ItemType.MATERIAL
max_stack = 999
```

**`item.stone_pickaxe.tres`**

```gdscript
extends ToolItem
id = "item.stone_pickaxe"
display_name = "Каменная кирка"
icon = preload("res://assets/textures/items/stone_pickaxe.png")
type = ItemType.TOOL
max_stack = 1
tool_type = ToolType.PICKAXE
power = 2
damage = 3
use_time = 0.6
speed_multiplier = 1.0
rune_slots = 0
```

**`item.copper_sword.tres`**

```gdscript
extends WeaponItem
id = "item.copper_sword"
display_name = "Медный меч"
icon = preload("res://assets/textures/items/copper_sword.png")
type = ItemType.WEAPON
max_stack = 1
damage = 5
use_time = 0.4
knockback = 1.2
range = 1.5
rune_slots = 1
can_break_grass = true
```
