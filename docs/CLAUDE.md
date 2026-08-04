# CLAUDE.md - Fractured Glade

## О проекте

**Fractured Glade** - 2D sandbox-survival игра, вдохновленная Terraria, с центральной механикой двух Макробиомов (Свет и Тьма), существующих одновременно в одном мире. Игрок перемещается между ними через Разломы, сохраняя координаты.

**Технологический стек:**

- Godot Engine 4.7 (последняя стабильная версия)
- GDScript (строгая типизация)
- Git + GitHub
- Процедурная генерация мира

**Ключевая документация:**

- [Концепт и границы MVP](./mvp-vision-and-scope.md)
- [Style Guide](./style-guide.md)

---

## Основная задача для ИИ-ассистента

При разработке этого проекта необходимо строго придерживаться:

1. **Best practice** - код и документация должны соответствовать best practice и подходящим паттернам проектирования в играх
1. **Масштабируемой архитектуры** - все системы должны быть модульными, с четким разделением ответственности
2. **Подготовки к мультиплееру** - минимизация глобального состояния, разделение данных и представления
3. **Соглашений из Style Guide** - именование, структура, коммиты, код-стайл
4. **Фокуса на MVP** - не выходить за рамки описанных фич, но закладывать основу для расширения
5. **Инженерных практик** - документация, типизация, тестируемость

---

## Архитектура проекта

### 1. Основные принципы

1. **Service Locator** - глобальные менеджеры через Autoload
2. **Разделение данных и логики** - данные в `Resource`, логика в скриптах
3. **Композиция вместо наследования** - предпочитать компоненты
4. **Событийно-ориентированная архитектура** - использование сигналов для слабой связанности
5. **Dependency Injection** - передача зависимостей через конструкторы или сеттеры

### 2. Иерархия Autoload (порядок загрузки)

```gdscript
# 1. Core - самое нижнее
AudioManager
InputManager
SaveManager

# 2. Game Systems
GameManager          # Главный цикл, состояния игры
WorldManager         # Управление макробиомами, загрузка чанков
PlayerManager        # Состояние игрока (здоровье, позиция, макробиом)
InventoryManager     # Инвентарь, предметы

# 3. Debug/Cheat (только в dev-сборке)
DebugSystem
CheatSystem
```

### 3. Коммуникация между системами

```gdscript
# ✅ ПРАВИЛЬНО: через сигналы
signal biome_changed(new_biome: BiomeType)

# ❌ НЕПРАВИЛЬНО: прямые вызовы глобальных менеджеров из любой точки
GameManager.switch_biome()  # Только через WorldManager
```

---

## Ключевые системы и их реализация

### 1. Система двух Макробиомов

**Принцип работы:**

- Мир генерируется один раз (основа - ландшафт, пещеры, руды)
- Создаются две **виртуальные копии** (Свет и Тьма) с разным наполнением
- Переключение происходит через `WorldManager.switch_biome()`

**Реализация:**

```gdscript
# biome_data.gd - Resource
class_name BiomeData extends Resource

@export var biome_name: String
@export var biome_type: BiomeType  # enum { LIGHT, DARK }
@export var tile_set: TileSet
@export var background_color: Color
@export var ambient_light: Color
@export var enemy_pool: Array[EnemyData]
@export var ore_types: Array[OreData]
@export var decoration_tiles: Array[Vector2i]

# world_manager.gd
class_name WorldManager extends Node

var current_biome: BiomeType = BiomeType.LIGHT
var biome_layers: Dictionary = {}  # { BiomeType: TileMapLayer }

func switch_biome(new_biome: BiomeType) -> void:
    if current_biome == new_biome:
        return
    
    # Сохраняем состояние текущего макробиома
    biome_layers[current_biome].hide()
    biome_layers[new_biome].show()
    current_biome = new_biome
    
    # Обновляем визуальные эффекты
    update_ambient_light()
    update_background()
    
    biome_changed.emit(new_biome)
```

**Важно:**

- Каждый макробиом использует свой `TileMapLayer`
- Тайлы могут быть одинаковыми или разными - это определяется в `BiomeData`
- При переключении не пересоздавать мир, только переключать видимость слоев

### 1.2. Разломы (Rifts)

**Требования:**

- Объект в мире, при взаимодействии с которым меняется макробиом
- Сохраняет мировые координаты игрока
- Визуально отличается в разных макробиомах

**Реализация:**

```gdscript
# rift.gd
class_name Rift extends Area2D

@export var rift_id: String
@export var target_biome: BiomeType

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is Player:
        WorldManager.switch_biome(target_biome)
        # Визуальный эффект перехода
        EffectsManager.play_rift_transition()
```

**Визуальное состояние:**

- В Свете: белое свечение, парящие частицы
- В Тьме: фиолетовое свечение, темные частицы

### 3. Генерация мира (MVP)

**Ограничения MVP:**

- Размер: **Маленький** (примерно 200x100 тайлов)
- Подбиомы: Лес + Простые пещеры
- Одна руда (медь/железо)

**Алгоритм генерации:**

```gdscript
# world_generator.gd
class_name WorldGenerator extends Node

@export var world_width: int = 200
@export var world_height: int = 100
@export var seed: int = 0

func generate_world() -> Dictionary:
    var seed_value = seed if seed != 0 else randi()
    var noise = FastNoiseLite.new()
    noise.seed = seed_value
    
    var height_map = generate_height_map(noise)
    var cave_map = generate_cave_map(noise)
    var tile_map = build_tile_map(height_map, cave_map)
    
    # Сохраняем сид для отладки
    DebugSystem.set_seed(seed_value)
    
    # Генерируем оба макробиома на основе одной карты
    var light_world = apply_biome(tile_map, BiomeType.LIGHT)
    var dark_world = apply_biome(tile_map, BiomeType.DARK)
    
    return {
        "light": light_world,
        "dark": dark_world,
        "seed": seed_value
    }

func generate_height_map(noise: FastNoiseLite) -> Array:
    # Простая генерация высот (поверхность)
    var height_map = []
    for x in world_width:
        var height = noise.get_noise_2d(x, 0.0)
        height_map.append(int(remap(height, -1, 1, 20, 60)))
    return height_map
```

### 4. Инвентарь

**Структура:**

```gdscript
# inventory.gd
class_name Inventory extends Resource

@export var slots: Array[InventorySlot]
@export var max_slots: int = 50
@export var hotbar_slots: int = 10

signal inventory_updated

func add_item(item_id: String, count: int = 1) -> bool:
    # Поиск существующего стака
    for slot in slots:
        if slot.item_id == item_id and slot.count < item_data.max_stack:
            var added = min(count, item_data.max_stack - slot.count)
            slot.count += added
            count -= added
            if count == 0:
                inventory_updated.emit()
                return true
    
    # Добавление в новый слот
    if count > 0 and slots.size() < max_slots:
        slots.append(InventorySlot.new(item_id, count))
        inventory_updated.emit()
        return true
    
    return false

class InventorySlot:
    var item_id: String
    var count: int
    
    func _init(id: String, c: int):
        item_id = id
        count = c
```

### 5. Крафт (MVP)

**Рецепты хранятся как Resources:**

```gdscript
# recipe_data.gd
class_name RecipeData extends Resource

@export var result_item_id: String
@export var result_count: int = 1
@export var ingredients: Array[Ingredient]
@export var required_station: String = ""  # "workbench", "anvil" и т.д.

class Ingredient:
    var item_id: String
    var count: int

# crafting_manager.gd
func craft_recipe(recipe: RecipeData) -> bool:
    # Проверка ингредиентов
    for ingredient in recipe.ingredients:
        if not InventoryManager.has_item(ingredient.item_id, ingredient.count):
            return false
    
    # Снятие ингредиентов
    for ingredient in recipe.ingredients:
        InventoryManager.remove_item(ingredient.item_id, ingredient.count)
    
    # Добавление результата
    InventoryManager.add_item(recipe.result_item_id, recipe.result_count)
    return true
```

### 6. Враги (MVP)

**Базовый класс всех врагов:**

```gdscript
# enemy_base.gd
class_name EnemyBase extends CharacterBody2D

@export var enemy_data: EnemyData
@export var health: int = 20
@export var speed: float = 50.0
@export var damage: int = 5

var current_biome: BiomeType
var is_dead: bool = false

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()

func die() -> void:
    is_dead = true
    # Дроп предметов
    drop_loot()
    queue_free()

# slime.gd - пример конкретного врага
class_name Slime extends EnemyBase

var jump_timer: float = 0.0

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    
    # AI движение (прыжки в сторону игрока)
    var player = GameManager.get_player()
    if player:
        var direction = sign(player.global_position.x - global_position.x)
        velocity.x = direction * speed
        # Прыжок каждые 2 секунды
        jump_timer += delta
        if jump_timer > 2.0 and is_on_floor():
            velocity.y = -200.0
            jump_timer = 0.0
    
    move_and_slide()
```

**Различия между макробиомами:**

- Светлый слизень: зеленый, низкий урон, дропает "студень"
- Темный слизень: фиолетовый/черный, высокий урон, дропает "темный студень"

---

## Работа с ресурсами (Resources)

**Все игровые данные - через Resource:**

```gdscript
# ✅ ПРАВИЛЬНО: данные в ресурсах
# wood.tres
@export var item_id: String = "wood"
@export var item_name: String = "Древесина"
@export var icon: Texture2D
@export var max_stack: int = 99
@export var item_type: ItemType = ItemType.MATERIAL

# ❌ НЕПРАВИЛЬНО: данные хардкодом в скриптах
func get_wood_data():
    return {"id": "wood", "name": "Древесина"}  # Так нельзя
```

**Преимущества:**

- Редактирование в инспекторе Godot
- Легкое добавление новых предметов без изменения кода
- Возможность загрузки из JSON/CSV в будущем

---

## Отладка и читы (Dev-инструменты)

**Debug System (отображение информации):**

```gdscript
# debug_system.gd (Autoload)
class_name DebugSystem extends Node

var is_visible: bool = false
var free_camera: bool = false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_toggle"):
        is_visible = !is_visible
        update_ui()
    
    if event.is_action_pressed("debug_free_camera"):
        free_camera = !free_camera
        if free_camera:
            enable_free_camera()
        else:
            disable_free_camera()

func update_ui() -> void:
    # Показываем:
    # - FPS
    # - Координаты игрока
    # - Текущий макробиом
    # - Активный биом
    # - Сид генерации
    pass
```

**Cheat System (консоль/горячие клавиши):**

```gdscript
# cheat_system.gd (Autoload, только DEV-сборка)
class_name CheatSystem extends Node

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F1: Godot.toggle_god_mode()
            KEY_F2: Godot.toggle_flight()
            KEY_F3: InventoryManager.give_item("wood", 999)
            KEY_F4: WorldManager.switch_biome()
            KEY_F5: toggle_no_clip()
```

---

## Правила написания кода

### Типизация

```gdscript
# ✅ ПРАВИЛЬНО: явная типизация
var health: int = 100
var position: Vector2 = Vector2.ZERO
var items: Array[ItemData] = []
func take_damage(amount: int) -> void:
    health -= amount

# ❌ НЕПРАВИЛЬНО: динамическая типизация
var health = 100
func take_damage(amount):
    health -= amount
```

### Сигналы

```gdscript
# ✅ ПРАВИЛЬНО: сигналы с описанием
signal health_changed(new_value: int, old_value: int)
signal biome_changed(new_biome: BiomeType)
signal item_picked_up(item_id: String, count: int)

# ❌ НЕПРАВИЛЬНО: сигналы без данных
signal health_changed
```

### Документация

```gdscript
## Переключает текущий макробиом.
## @param new_biome - целевой макробиом (LIGHT или DARK)
## @emits biome_changed(new_biome)
func switch_biome(new_biome: BiomeType) -> void:
    # Проверка на смену того же биома
    if current_biome == new_biome:
        return
    # ... реализация
```

---

## Структура проекта (напоминание)

```text
fractured-glade/
├── assets/                       # Все немодифицируемые ресурсы
│   ├── textures/                 # Графика
│   │   ├── tiles/                # Тайлы (земля, трава, камень, руды)
│   │   ├── items/                # Иконки предметов
│   │   ├── enemies/              # Спрайты врагов
│   │   ├── npc/                  # Спрайты NPC
│   │   ├── ui/                   # Элементы интерфейса (кнопки, фоны)
│   │   └── effects/              # Визуальные эффекты (частицы, молнии)
│   ├── audio/                    # Звуки и музыка
│   │   ├── music/                # Музыкальные треки (в формате .ogg)
│   │   └── sfx/                  # Звуковые эффекты (шаги, удары, добыча)
│   ├── fonts/                    # Шрифты
│   └── localization/             # Файлы локализации (.po или .csv)
│
├── scenes/                       # Все сцены (.tscn)
│   ├── main_menu/                # Главное меню и настройки
│   ├── game_world/               # Основная игровая сцена (мир + игрок)
│   ├── player/                   # Сцена игрока
│   ├── enemies/                  # Сцены врагов (по одному на тип)
│   ├── npc/                      # Сцены NPC
│   ├── ui/                       # Отдельные UI-сцены (инвентарь, крафт)
│   └── props/                    # Сцены окружающих объектов (дерево, разлом и т.п.)
│       ├── rifts/                # Сцены разломов
│       └── ...                   # Остальные сцены
│
├── scripts/                      # Все GDScript-скрипты (.gd)
│   ├── core/                     # Базовые классы и глобальные менеджеры
│   │   ├── game_manager.gd       # Главный управляющий цикл
│   │   ├── world_manager.gd      # Управление миром и макробиомами
│   │   ├── input_manager.gd      # Обработка ввода
│   │   ├── audio_manager.gd      # Управление звуком
│   │   └── save_manager.gd       # Сохранение/загрузка
│   ├── player/                   # Логика игрока
│   │   ├── player.gd
│   │   └── player_inventory.gd
│   ├── world/                    # Генерация, тайлы, биомы
│   │   ├── world_generator.gd
│   │   ├── biome_data.gd         # Ресурс-класс для биома
│   │   ├── tile_data.gd
│   │   └── rifts/                # Логика разломов
│   ├── items/                    # Предметы и инвентарь
│   │   ├── item_base.gd          # Базовый класс предмета
│   │   ├── item_data.gd          # Ресурс с данными предмета
│   │   └── inventory.gd
│   ├── craft/                    # Система крафта
│   │   ├── crafting_manager.gd
│   │   └── recipe_data.gd
│   ├── enemies/                  # Логика врагов
│   │   ├── enemy_base.gd
│   │   └── slime.gd
│   ├── npc/                      # Логика NPC
│   │   ├── npc_base.gd
│   │   └── dialogue_manager.gd
│   ├── ui/                       # Логика интерфейса
│   │   ├── hud.gd
│   │   ├── inventory_ui.gd
│   │   └── crafting_ui.gd
│   └── utils/                    # Утилиты и вспомогательные функции
│       ├── math_utils.gd
│       └── noise.gd              # Генерация шума (если не использовать плагин)
│
├── resources/                    # Ресурсы Godot (.tres, .res) - данные
│   ├── items/                    # Ресурсы предметов (wood.tres, stone.tres, ...)
│   ├── recipes/                  # Ресурсы рецептов (wood_pickaxe.tres, ...)
│   ├── biomes/                   # Данные биомов (light_forest.tres, dark_forest.tres)
│   ├── enemies/                  # Данные врагов (slime.tres)
│   └── npc/                      # Данные NPC (guide.tres)
│
├── tests/                        # Тесты (если будут)
│   ├── unit/                     # Юнит-тесты
│   └── integration/              # Интеграционные тесты
│
├── addons/                       # Сторонние плагины (Godot addons)
│
├── project.godot                 # Файл проекта
├── .gitignore
├── .editorconfig                 # Единые настройки редактора
└── README.md
```

---

## Git и коммиты

### 1.1. Структура сообщения коммита

`<type>(<scope>): <краткое описание>`

### 1.2. Правила оформления

1. Длина заголовка коммита не должна превышать 72 символов
2. Текст коммита на русском языке
3. Все буквы должны быть строчными
4. Вместо буквы `е` в тексте коммита используется буква `е`

### 1.3. Типы коммитов (type)

| Тип        | Назначение                                                              |
| ---------- | ----------------------------------------------------------------------- |
| `feat`     | Новая функциональность (новая фича, компонент)                          |
| `fix`      | Исправление бага                                                        |
| `art`      | Добавление или изменение визуальных/звуковых ресурсов (текстуры, звуки) |
| `balance`  | Изменение игрового баланса (характеристики предметов, врагов и т.п.)    |
| `docs`     | Изменения в документации                                                |
| `chore`    | Рутинные задачи: обновление `.gitignore`, форматирование скрипта и т.п. |
| `local`    | Локализация, перевод текстов                                            |
| `refactor` | Переработка кода без изменения внешнего поведения                       |
| `perf`     | Изменения, направленные на повышение производительности (оптимизация)   |
| `test`     | Добавление или обновление тестов (юнит-, интеграционных)                |

### 1.4. Области (scope)

Области соответствуют основным подсистемам игры. При необходимости можно добавлять новые, но перечисленные ниже - стандартные.

| Область   | Описание                                                                |
| --------- | ----------------------------------------------------------------------- |
| `player`  | Игрок: управление, инвентарь, здоровье, анимации                        |
| `enemies` | Противники, ИИ, анимации                                                |
| `npc`     | Неигровые персонажи, диалоги                                            |
| `assets`  | Добавление новых ресурсов (текстуры, звуки, шрифты)                     |
| `world`   | Мир: тайлы, мировые ивенты,                                             |
| `bioms`   | Макробиомы, биомы и их свойства                                         |
| `gen`     | Процедурная генерация                                                   |
| `rifts`   | Разломы, переход между макробиомами                                     |
| `ui`      | Интерфейс: главное меню, настройки, инвентарь, хотбар, HUD              |
| `items`   | Предметы, ресурсы, инструменты                                          |
| `craft`   | Крафт, рецепты, верстак                                                 |
| `audio`   | Звуки, музыка, микширование                                             |
| `save`    | Сохранение и загрузка (миры, состояние, инвентарь)                      |
| `debug`   | Отладочные инструменты, консоль, читы                                   |
| `core`    | Базовые системные компоненты (главный цикл, менеджеры, Service Locator) |
| `input`   | Управление, привязка клавиш, геймпады                                   |
| `network` | Мультиплеер (архитектура, синхронизация)                                |

### 1.5. Примеры корректных сообщений

- `feat(player): добавлен двойной прыжок`
- `feat(rifts): реализован переход между макробиомами`
- `feat(ui): добавлен хотбар с 10 слотами`
- `fix(gen): исправлена генерация деревьев на поверхности`
- `fix(enemies): слизень теперь наносит урон при касании`
- `balance(items): уменьшен урон медного меча с 12 до 8`
- `refactor(core): менеджеры переведены на autoload`
- `refactor(player): отформатирован скрипт player.gd`
- `art(assets): добавлены текстуры для темного леса`
- `art(assets): добавлен саундтрек для главного меню`
- `docs(style-guide): обновлен список скоупов`
- `chore(git): добавлен workflow для проверки gdscript линтером`
- `test(saving): добавлены юнит-тесты для сериализации мира`

---

## Тестирование

**Юнит-тесты (GUT плагин):**

```gdscript
# tests/unit/test_inventory.gd
extends GutTest

func test_add_item():
    var inventory = Inventory.new()
    inventory.add_item("wood", 10)
    assert_eq(inventory.slots[0].count, 10)
```

**Интеграционные тесты:**

- Сцена с автоматическим прохождением базового цикла
- Проверка генерации мира
- Проверка перехода между макробиомами

---

## Что делать в первую очередь

1. **Настроить Autoload** (GameManager, WorldManager, InputManager)
2. **Реализовать генерацию мира** (простая, с шумом)
3. **Создать систему макробиомов** (два слоя TileMap)
4. **Реализовать игрока** (движение, прыжок, добыча блоков)
5. **Добавить Разлом** (переключение между макробиомами)
6. **Инвентарь и крафт** (минимальный набор)
7. **Враги и боевая система**

---

## Частые ошибки и как их избежать

| Ошибка                                  | Решение                                                  |
| --------------------------------------- | -------------------------------------------------------- |
| Глобальные переменные вместо Autoload   | Использовать Service Locator через Autoload              |
| Жесткая связанность систем              | Использовать сигналы и события                           |
| Хардкод данных (ID предметов строками)  | Использовать Resource и константы enum                   |
| Смешивание логики и UI                  | Разделять: UI только отображает данные                   |
| Игнорирование типизации                 | Всегда указывать типы переменных и возвращаемых значений |
| Прямые вызовы Godot API в бизнес-логике | Абстрагировать через интерфейсы/менеджеры                |

---

## Полезные ресурсы

- [Godot 4 Docs](https://docs.godotengine.org/en/stable/)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## Критерии успешного MVP

- [ ] Генерация мира (лес + пещеры)
- [ ] Два макробиома с разным визуалом
- [ ] Переключение через Разлом
- [ ] Игрок: движение, прыжок, добыча, установка блоков
- [ ] Инвентарь (хотбар + основной)
- [ ] Крафт (верстак, деревянные/каменные инструменты)
- [ ] Ресурсы (дерево, земля, камень, руда)
- [ ] Враги (слизень светлый + темный)
- [ ] Боевая система (меч, кирка, топор, здоровье)
- [ ] Сохранение (мир, макробиомы, инвентарь, позиция)
- [ ] Debug + Cheat системы
