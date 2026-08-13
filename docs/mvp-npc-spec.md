# Спецификация системы NPC, Диалогов и Отношений (MVP)

## 1. Назначение

Система NPC управляет неигровыми персонажами, обеспечивая:

- **Визуальное представление** в трех состояниях мира (`light`, `standard`, `dark`) с синхронизацией координат между состояниями.
- **Поведение** (расписание, перемещение, анимации) через `NPCStateMachine`.
- **Взаимодействие** с игроком (диалоги, торговля, подарки, раскрытие тайн).
- **Отношения** между NPC и игроком (балльная система, уровни), а также между NPC друг с другом (задел).
- **Реакцию на глобальные ивенты** (например, "Конфетный дождь", появление босса).
- **Сохранение** состояния (отношения, флаги, прогресс диалогов) в бинарном формате.

Система спроектирована с учетом **мультиплеера**: каждый игрок видит свою версию NPC (в зависимости от своего текущего макробиома), а отношения и прогресс хранятся индивидуально для каждого игрока. При этом **координаты NPC едины для всех** (серверная истина).

---

## 2. Принципы проектирования

- **Данные - в Resource.** Все настройки NPC, диалогов, расписаний, предпочтений подарков хранятся в `.tres`-файлах.
- **Композиция.** Функциональность разбита на компоненты (`DialogueComponent`, `ScheduleComponent`, `ShopComponent`, `GiftComponent`, `SecretComponent`, `RegularPhraseComponent`). NPCData содержит ссылки на эти компоненты.
- **Строгая типизация.** Использование `StringName` для идентификаторов, `enum` для состояний, типизированные массивы.
- **Событийно-ориентированность.** Сигналы для оповещения о смене состояния, изменении отношений, начале диалога и т.д.
- **Масштабируемость.** Архитектура позволяет добавлять новых NPC, новые типы действий, новые условия в диалогах без изменения ядра.
- **Подготовка к мультиплееру.** Состояние NPC определяется на клиенте по макробиому игрока, а отношения хранятся в `RelationshipComponent` с привязкой к `player_id`. Сервер синхронизирует только координаты и базовое состояние (активен/мертв).

---

## 3. Иерархия классов и структур данных

### 3.1. Основные перечисления (Enum)

```gdscript
enum WorldState { LIGHT, STANDARD, DARK }  # состояния мира / NPC
enum NPCState { IDLE, WALK, SIT, INTERACT, HURT, DEAD }  # состояния конечного автомата
enum Race { ETHEREAL, DRYAD, ASTRAL, LUMIN, WANDERER, INVENTOR }
enum RelationshipLevel { STRANGER, ACQUAINTANCE, FRIEND }
enum DialogueNodeType { TEXT, CHOICE, CONDITION, ACTION, END }
```

### 3.2. Базовый ресурс NPCData (extends Resource)

```gdscript
class_name NPCData
extends Resource

@export_group("Основное")
@export var id: StringName = &""               # уникальный идентификатор npc.mirei
@export var display_name: String = ""          # локализуемое имя
@export var last_name: String = ""             # может быть пустым
@export var description: String = ""           # RichText-описание (с поддержкой BBCode)
@export var race: Race = Race.ETHEREAL

@export_group("Внешность и анимации")
@export var sprite_light: Texture2D            # спрайт для состояний LIGHT и STANDARD
@export var sprite_dark: Texture2D             # спрайт для состояния DARK
@export var animation_player: AnimationPlayer  # компонент анимаций (ссылка на сцену)

@export_group("Параметры движения")
@export var move_speed: float = 60.0           # пикселей/сек
@export var interaction_radius: float = 80.0   # радиус для начала диалога

@export_group("Состояния и расписание")
@export var schedule_light: ScheduleData       # расписание для LIGHT
@export var schedule_standard: ScheduleData    # расписание для STANDARD (может быть null = копия light)
@export var schedule_dark: ScheduleData        # расписание для DARK

@export_group("Диалоги")
@export var dialogue_tree_light: DialogueTree  # дерево для LIGHT
@export var dialogue_tree_standard: DialogueTree
@export var dialogue_tree_dark: DialogueTree

@export_group("Торговля")
@export var shop_items_light: Array[ShopItem]  # список товаров для LIGHT
@export var shop_items_standard: Array[ShopItem]
@export var shop_items_dark: Array[ShopItem]
@export var price_modifier_from_relationship: float = 0.0   # скидка/наценка за уровень отношений (проценты)
@export var price_modifier_from_neighbors: float = 0.0      # влияние соседей (задел)

@export_group("Подарки")
@export var gift_preferences: GiftPreferences   # структура предпочтений для каждого состояния

@export_group("Тайна")
@export var secret: SecretData                 # тайна NPC

@export_group("Регулярные фразы")
@export var regular_phrases: RegularPhraseSet  # набор фраз для каждого состояния и условий

@export_group("Реакция на ивенты")
@export var event_reactions: Array[EventReaction]  # привязка к глобальным ивентам

@export_group("Отношения с другими NPC")
@export var relationship_with_npcs: Dictionary   # ключ - id NPC, значение - начальный балл (задел)
```

### 3.3. Компоненты (структуры данных)

#### 3.3.1. ScheduleData (Resource)

```gdscript
class_name ScheduleData
extends Resource

@export var actions: Array[ScheduleAction] = []

# Каждое действие:
class ScheduleAction:
    var type: ActionType        # enum { GO_TO_POINT, STAND, SIT, INTERACT }
    var target_point: Vector2   # для GO_TO_POINT - координаты в мире
    var target_object_id: StringName # для INTERACT - ID объекта (стул, разлом и т.п.)
    var duration: float = 0.0   # время выполнения (0 - бесконечно, до смены состояния)
    var time_of_day: float = -1.0 # задел под время суток (0..1), -1 - любое время
```

**Примечание:** координаты в расписании **одинаковы для всех состояний**. Это гарантирует синхронизацию позиции NPC. В каждом состоянии NPC может выполнять разные действия, но точки маршрута одни и те же (например, идти к одному и тому же стулу, но в темном состоянии - просто стоять на месте).

#### 3.3.2. DialogueTree (Resource)

```gdscript
class_name DialogueTree
extends Resource

@export var root_node: DialogueNode   # корневой узел (обычно TEXT или CHOICE)

# Узлы диалога:
class DialogueNode:
    var type: DialogueNodeType
    var text: String = ""              # отображаемый текст (может содержать BBCode)
    var condition: DialogueCondition = null   # условие для входа в узел
    var choices: Array[DialogueChoice] = []   # для TYPE.CHOICE
    var action: DialogueAction = null         # для TYPE.ACTION (выдать предмет, изменить отношения и т.д.)
    var next_node_id: StringName = ""         # переход к следующему узлу (для TEXT, ACTION, END)

class DialogueChoice:
    var text: String                   # текст варианта ответа
    var condition: DialogueCondition   # условие видимости варианта
    var next_node_id: StringName       # переход по выбору

class DialogueCondition:
    var type: ConditionType  # enum { RELATIONSHIP_LEVEL, QUEST_COMPLETED, HAS_ITEM, WORLD_STATE, FLAG }
    var value: Variant       # значение для сравнения
    var comparison: String   # "==", ">=", "<", "has" и т.д.

class DialogueAction:
    var action_type: ActionType  # enum { GIVE_ITEM, START_QUEST, COMPLETE_QUEST, CHANGE_RELATIONSHIP, SET_FLAG, UNLOCK_SECRET }
    var parameters: Dictionary   # например { "item_id": "item.wood", "count": 5 }
```

**Упрощение для MVP:** дерево будет небольшим, максимум 2-3 уровня вложенности. Условия проверяются на лету. Поддерживаются только простые действия (дать предмет, изменить отношения, установить флаг).

#### 3.3.3. ShopItem (структура)

```gdscript
class ShopItem:
    var item_id: StringName        # ID предмета из ItemRegistry
    var price_light: int = 0       # цена в "Светлых душах"
    var price_dark: int = 0        # цена в "Темных душах"
    var stock: int = -1            # -1 = бесконечно
    var required_relationship: RelationshipLevel = RelationshipLevel.STRANGER
```

#### 3.3.4. GiftPreferences (Resource)

```gdscript
class_name GiftPreferences
extends Resource

@export var preferences: Dictionary = {
    "light": [],    # массив GiftPreference для состояния LIGHT
    "standard": [],
    "dark": []
}

class GiftPreference:
    var item_id: StringName
    var score: int = 1   # изменение отношений при дарении
    var reject_chance: float = 0.0   # дополнительный шанс отказа (складывается с базовым)
```

**Примечание:** если предмет не указан в предпочтениях, применяются дефолтные значения: `score = 1`, `reject_chance = 0.0`.

**Дополнительное примечание (задел на будущее):**

> **Примечание:** В текущей MVP-версии подарок влияет только на отношения между дарителем (игроком) и получателем (NPC). Однако в будущем планируется реализовать **систему взаимовлияния подарков на отношения с другими NPC**.  
> Если подарок является **нелюбимым** для NPC (score < 0), то помимо снижения отношений с этим NPC, он может **вызвать негативную реакцию у других NPC**, которые имеют положительные отношения с получателем (например, друзья или союзники). Механика будет реализована через граф отношений между NPC: при дарении нелюбимого подарка выполняется поиск всех NPC, у которых отношение к получателю выше определённого порога, и для них также применяется штраф (масштабируемый). Аналогично, **любимый подарок** может дать бонус к отношениям с друзьями получателя. Эта логика будет настраиваться через отдельный компонент `SocialGraph` и не входит в MVP.

#### 3.3.5. SecretData (Resource)

```gdscript
class_name SecretData
extends Resource

@export var secret_name: String = ""
@export var description: String = ""   # RichText
@export var required_level: RelationshipLevel = RelationshipLevel.FRIEND
@export var reveal_trigger: RevealTrigger  # enum { IMMEDIATE, RANDOM_DAY, ON_EVENT }
@export var event_id: StringName = ""      # если ON_EVENT
@export var action_on_reveal: DialogueAction   # действие (дать предмет, запустить квест)
@export var dialogue_node_id: StringName   # ID узла диалога, в котором раскрывается тайна
```

#### 3.3.6. RegularPhraseSet (Resource)

```gdscript
class_name RegularPhraseSet
extends Resource

@export var phrases: Array[RegularPhrase] = []

class RegularPhrase:
    var text: String                         # фраза (может быть с BBCode)
    var world_state: WorldState              # для какого состояния
    var trigger: PhraseTrigger               # enum { ON_PLAYER_NEAR, ON_NPC_PASS, ON_EVENT }
    var event_id: StringName = ""            # если ON_EVENT
    var probability: float = 0.1             # шанс появления при каждом триггере
    var cooldown: float = 10.0               # секунд между повторениями
```

#### 3.3.7. EventReaction (структура)

```gdscript
class EventReaction:
    var event_id: StringName              # ID события (например, "candy_rain")
    var reaction_type: ReactionType       # enum { CHANGE_SCHEDULE, CHANGE_DIALOGUE, EMIT_PHRASE, TELEPORT }
    var parameter: Variant                # зависит от типа
```

### 3.4. Компоненты NPC (в составе NPCInstance)

В игровой сцене каждый NPC представлен узлом `NPCInstance` (extends CharacterBody2D), который содержит:

- **Sprite2D** (переключается в зависимости от состояния мира игрока).
- **AnimationPlayer** (управляет анимациями).
- **NPCStateMachine** (конечный автомат).
- **CollisionShape2D** для взаимодействия.
- **Area2D** для обнаружения игрока.
- Ссылки на компоненты: `DialogueComponent`, `ScheduleComponent`, `ShopComponent`, `GiftComponent`, `SecretComponent`, `RegularPhraseComponent`.

**NPCStateMachine** управляет состояниями: `idle`, `walk`, `sit`, `interact`, `hurt`, `dead`. Переходы зависят от текущего расписания и внешних команд (например, игрок начал диалог - переход в `interact`). Анимации синхронизируются с состоянием.

### 3.5. Менеджеры (Autoload)

#### 3.5.1. NPCManager (Autoload)

```gdscript
class_name NPCManager
extends Node

signal npc_spawned(npc_id: StringName, instance: NPCInstance)
signal npc_despawned(npc_id: StringName)
signal npc_state_changed(npc_id: StringName, new_state: NPCState)
signal relationship_changed(npc_id: StringName, player_id: int, new_score: int)

var npc_instances: Dictionary = {}   # key: npc_id, value: NPCInstance
var npc_data_cache: Dictionary = {}  # загруженные NPCData (по id)

func spawn_npc(npc_id: StringName, position: Vector2) -> NPCInstance
func despawn_npc(npc_id: StringName)
func get_npc(npc_id: StringName) -> NPCInstance
func get_relationship(npc_id: StringName, player_id: int) -> int
func change_relationship(npc_id: StringName, player_id: int, delta: int)
func set_relationship_level(npc_id: StringName, player_id: int, level: RelationshipLevel)
func get_current_world_state(player_id: int) -> WorldState  # определяется из WorldManager
```

#### 3.5.2. DialogueSystem (Autoload)

```gdscript
class_name DialogueSystem
extends Node

signal dialogue_started(npc_id: StringName)
signal dialogue_ended(npc_id: StringName)
signal dialogue_node_reached(npc_id: StringName, node_id: StringName)

func start_dialogue(npc_id: StringName, player_id: int) -> void
func select_choice(npc_id: StringName, choice_index: int) -> void
func get_current_node(npc_id: StringName) -> DialogueNode
func is_dialogue_active(npc_id: StringName) -> bool
```

Диалог ведется индивидуально для каждого игрока. Состояние диалога (текущий узел, пройденные ветки) хранится в `DialogueComponent` NPC, привязанное к `player_id`.

#### 3.5.3. RelationshipManager (Autoload)

`RelationshipManager` — центральный менеджер, отвечающий за хранение и изменение **баллов отношений** между игроками и NPC, а также между NPC друг с другом. Он предоставляет единый интерфейс для всех систем (диалоги, подарки, квесты).

**Структура данных:**

```gdscript
# Словарь: { npc_id: { player_id: relationship_data } }
var relationships: Dictionary = {}
# Для отношений NPC-NPC (задел):
var npc_to_npc_relationships: Dictionary = {}  # { npc_id: { other_npc_id: score } }
```

Где `relationship_data` — это словарь с ключами:

- `score`: int — текущее количество баллов.
- `level`: RelationshipLevel — вычисляемый уровень (STRANGER, ACQUAINTANCE, FRIEND) на основе порогов.
- `flags`: int — битовые флаги (например, `secret_revealed` и другие).

**Публичные методы:**

| Метод | Описание |
|-------|----------|
| `get_relationship(npc_id: StringName, player_id: int) -> int` | Возвращает текущее количество баллов. Если данные отсутствуют — возвращает 0 (начальное значение). |
| `get_relationship_level(npc_id: StringName, player_id: int) -> RelationshipLevel` | Возвращает уровень на основе порогов (0-19 → STRANGER, 20-39 → ACQUAINTANCE, 40+ → FRIEND). Пороги настраиваются через `@export` в менеджере. |
| `change_relationship(npc_id: StringName, player_id: int, delta: int, reason: String = "") -> void` | Изменяет баллы на `delta` (может быть отрицательным). Автоматически пересчитывает уровень. Генерирует сигнал `relationship_changed`. `reason` используется для отладки. |
| `set_relationship(npc_id: StringName, player_id: int, new_score: int) -> void` | Прямая установка баллов (для загрузки или дебага). |
| `reset_relationship(npc_id: StringName, player_id: int) -> void` | Сбрасывает баллы до 0. |
| `is_secret_revealed(npc_id: StringName, player_id: int) -> bool` | Проверяет флаг раскрытия тайны. |
| `set_secret_revealed(npc_id: StringName, player_id: int, value: bool) -> void` | Устанавливает флаг. |

**Сигналы:**

```gdscript
signal relationship_changed(npc_id: StringName, player_id: int, new_score: int, old_score: int)
signal relationship_level_changed(npc_id: StringName, player_id: int, new_level: RelationshipLevel, old_level: RelationshipLevel)
signal secret_revealed(npc_id: StringName, player_id: int)
```

**Инициализация:** При старте игры менеджер загружает сохранённые данные из `SaveManager` (через вызов `load_relationships(data)`). Если данные отсутствуют, создаются записи со значением 0 для всех известных NPC.

**Интеграция:**  

- `DialogueSystem` использует `RelationshipManager` для проверки условий в диалогах (например, `relationship_level >= FRIEND`).  
- `GiftComponent` вызывает `change_relationship` при успешном дарении.  
- `QuestSystem` может изменять отношения при завершении квеста через `change_relationship`.

**Задел на мультиплеер:** Все методы принимают `player_id`, что позволяет хранить отношения отдельно для каждого игрока. В синглплеере `player_id` всегда равен 0 (или уникальному идентификатору сессии).

---

## 4. Алгоритмы и логика

### 4.1. Спавн NPC

- **Мирей Астор** появляется сразу после генерации мира, в центре поверхности, рядом с игроком.
- **Грета** появляется при первом переходе игрока через Разлом (спавнится рядом с разломом).
- В MVP NPC не умирают и не исчезают (кроме дебаг-команд).

### 4.2. Синхронизация состояний мира и NPC

- Каждый игрок имеет свое состояние мира (`WorldState`), хранящееся в `WorldManager` (привязано к `player_id`).
- При отрисовке NPC на клиенте выбирается спрайт и анимации, соответствующие `WorldState` данного игрока.
- Координаты NPC едины для всех, и расписание выполняется на сервере (в синглплеере - локально) с синхронизацией позиции.

### 4.3. Расписание и StateMachine

- Каждую игровую секунду (или по таймеру) `ScheduleComponent` проверяет текущее время и определяет текущее действие из `ScheduleData` для текущего состояния мира.
- Если действие `GO_TO_POINT` - NPC двигается к заданной точке (используя простую линейную интерполяцию или `NavigationAgent2D` - в MVP без сложного пути, просто двигается по прямой, игнорируя препятствия).
- Если `STAND` - переходит в `idle`.
- Если `SIT` - ищет объект-стул в мире и садится (анимация `sit`, позиция фиксируется).
- Если `INTERACT` - поворачивается к цели (другой NPC или объект) и проигрывает анимацию взаимодействия.
- Координаты точек маршрута одинаковы для всех состояний, но само действие может отличаться (например, в свете - идти к столу и сесть, во тьме - идти к тому же столу и стоять).

### 4.4. Диалоговая система

1. Игрок нажимает ПКМ на NPC в радиусе `interaction_radius`.
2. `DialogueSystem.start_dialogue(npc_id, player_id)`:
   - Проверяет, не активен ли уже диалог у этого NPC для данного игрока.
   - Загружает `DialogueTree` для текущего состояния мира игрока.
   - Начинает с корневого узла, проверяет условия, отображает текст и варианты (если есть).
   - Отправляет сигнал `dialogue_started`.
3. Игрок выбирает вариант (или диалог автоматически переходит по `next_node_id` для узлов без выбора).
4. При достижении узла типа `ACTION` выполняются действия (выдача предмета, изменение отношений, установка флага, раскрытие тайны).
5. При достижении узла типа `END` диалог завершается.
6. В процессе диалога игрок может использовать кнопку "Подарок" (см. раздел 4.5) или "Торговля" (открывает окно магазина).

**Сохранение прогресса диалога:** для каждого игрока сохраняется множество пройденных `node_id` (или флагов), чтобы при повторном диалоге не показывать одни и те же ветки.

### 4.5. Подарки

1. В окне диалога есть кнопка "Подарок".
2. При нажатии открывается слот (как в инвентаре), куда игрок может перетащить предмет из своего инвентаря.
3. После подтверждения:
   - Проверяется, не превышен ли лимит подарков в неделю (2 штуки, сбрасывается раз в игровую неделю).
   - Определяется предпочтение для текущего состояния мира NPC (из `GiftPreferences`).
   - Рассчитывается шанс отказа: базовый 75% + `reject_chance` из предпочтения (если предмет нелюбимый - 100% отказ, если любимый - добавляется 10% к шансу принятия, т.е. отказ = 65%).
   - Если отказ - NPC произносит фразу отказа, предмет возвращается в инвентарь.
   - Если принят - предмет исчезает, отношения изменяются на `score` баллов (может быть отрицательным). NPC произносит благодарственную/негативную фразу.
4. Отношения обновляются, сигнал `relationship_changed`.

### 4.6. Отношения и уровни

- Баллы хранятся в `RelationshipComponent` для каждого игрока (по `player_id`).
- Уровни:
  - `STRANGER`: 0-19 баллов.
  - `ACQUAINTANCE`: 20-39.
  - `FRIEND`: 40 и выше (максимум не ограничен, но для уровней достаточно 60 - порог настраиваемый).
- Изменения:
  - +2 за первый диалог в день (только один раз).
  - +4-8 за выполнение квеста (настраивается в действии диалога).
  - +5 за любимый подарок, +1 за обычный, -5 за нелюбимый.
  - -2..-5 за грубый ответ (задается в диалоге).
- Достижение уровня `FRIEND` для большинства NPC разблокирует возможность раскрыть тайну (см. ниже).

### 4.7. Тайна

- Когда отношения достигают необходимого уровня (параметр `required_level`, по дефолту `FRIEND`), у NPC появляется индикатор (искра/огонек) над головой.
- Тайна может быть раскрыта:
  - Немедленно (при следующем диалоге).
  - Случайно через 1-2 игровых дня.
  - По событию (например, после убийства босса).
- При попытке раскрыть тайну запускается специальный диалог (узел, помеченный как `secret_reveal`), в котором NPC рассказывает тайну.
- После раскрытия выполняется действие (выдать предмет, запустить квест), и флаг `secret_revealed` для данного игрока устанавливается в `true`.
- Тайна может быть раскрыта только один раз для каждого игрока.

### 4.8. Реакция на ивенты

- Глобальные ивенты (например, "Конфетный дождь", появление босса) генерируют сигналы в `EventManager`.
- NPC подписываются на эти сигналы через `EventReaction`.
- Реакции могут включать: смену расписания (переключиться на альтернативное), вывод фразы, телепортацию (задел).

### 4.9. Регулярные фразы

- `RegularPhraseComponent` проверяет триггеры (игрок рядом, другой NPC проходит мимо, ивент).
- При срабатывании с заданной вероятностью и соблюдении кулдауна над NPC появляется текст (всплывающее облачко) на несколько секунд.
- Фразы выбираются в зависимости от текущего состояния мира.

---

## 5. Сохранение и загрузка

### 5.1. Структура файла сохранения (бинарный)

Расширяем формат из `mvp-generation-spec.md`, добавляя секцию для NPC:

```
[NPC Data]
    count_npcs: uint16
    для каждого NPC (по id):
        npc_id_length: uint16
        npc_id: String (UTF-8)
        
        position_x: float (32-bit)
        position_y: float (32-bit)
        
        player_count: uint16   # количество игроков, для которых есть данные
        для каждого игрока:
            player_id: uint32
            relationship_score: int32
            flags: uint32       # битовые флаги: бит 0 = secret_revealed, бит 1-... (задел)
            dialogue_progress: Dictionary  # сериализованный словарь { node_id: bool }
```

**Примечания:**  

- Позиция сохраняется в глобальных координатах (тип `Vector2`). При загрузке NPC спавнится именно в этой точке.  
- Если NPC ещё не был заспавнен (например, Грета ещё не появилась), его позиция может отсутствовать в сохранении; в этом случае при первом спавне используется стартовая позиция по умолчанию (задаётся в коде или сцене).  
- В MVP (один игрок) `player_count` всегда равен 1, но формат сразу поддерживает множество игроков.  
- `dialogue_progress` — сериализуется как словарь `{ StringName: bool }`, где ключ — ID узла диалога, значение — пройден ли этот узел. В MVP достаточно сохранять только пройденные узлы, чтобы при повторном диалоге не показывать уже виденные ветки. Сериализация выполняется через `var_to_bytes` (словарь преобразуется в массив байтов).

### 5.2. Загрузка

1. Читается заголовок, чанки, инвентарь (как раньше).
2. Читается секция NPC. Для каждого NPC восстанавливаются отношения и флаги для каждого игрока.
3. После загрузки мира NPC спавнятся согласно своим правилам (Мирей - сразу, Грета - после первого перехода, но это условие проверяется отдельно).

### 5.3. Сохранение

- Вызывается при сохранении игры (автосохранение или выход).
- Сохраняются все активные NPC (спавненные) и их данные для каждого игрока.

---

## 6. Интеграция с другими системами

- **WorldManager**: предоставляет текущее состояние мира для каждого игрока.
- **ItemRegistry / InventoryManager**: используются для выдачи предметов, проверки наличия, удаления при дарении.
- **QuestSystem** (MVP-базовая): диалоги могут запускать/завершать квесты. NPC могут выдавать квесты (через `DialogueAction`). Квесты хранятся в `QuestManager`.
- **EventManager**: генерирует ивенты, на которые подписываются NPC.
- **SaveManager**: координирует сохранение всех систем, включая NPC.

---

## 7. Дебаг-инструменты (интеграция с DebugSystem)

Добавляются следующие команды (через консоль или горячие клавиши):

- `npc_relationship <npc_id> <player_id> <value>` - установить отношения.
- `npc_hurt <npc_id> <damage>` - нанести урон NPC (если у NPC есть здоровье - в MVP нет, но задел).
- `npc_kill <npc_id>` - убить NPC (исчезает).
- `npc_heal <npc_id>` - восстановить здоровье (задел).
- `npc_teleport <npc_id>` - телепортировать NPC к игроку.
- `npc_debug_dialogue <npc_id>` - показать текущее дерево диалогов (для отладки).

Все команды доступны только в dev-сборке.

---

## 8. Критерии приемки MVP NPC-системы

1. **Мирей Астор** появляется сразу после генерации мира, **Грета** - после первого перехода через Разлом.
2. Обе NPC имеют разные спрайты для светлого и темного состояний (переключаются при смене макробиома игрока).
3. У каждой NPC есть базовое расписание (например, Мирей стоит на месте, Грета ходит по небольшому участку). Координаты расписания одинаковы в обоих состояниях.
4. При ПКМ по NPC открывается диалоговое окно с текстом, вариантами ответов, возможностью выбора.
5. Диалоги различаются для светлого и темного состояний.
6. У NPC есть магазин с разными товарами для каждого состояния. Товары покупаются за "Светлые души" и "Темные души".
7. Система отношений работает: после первого диалога +2 балла, после подарка - изменение согласно предпочтениям, после достижения уровня "друг" - появляется возможность раскрыть тайну.
8. Тайна раскрывается через специальный диалог, после чего выдается предмет (например, отцовский кинжал).
9. Регулярные фразы появляются над головой NPC при прохождении игрока рядом (с учетом состояния).
10. Сохранение и загрузка корректно восстанавливают отношения, флаги тайн и прогресс диалогов.
11. Дебаг-команды работают и позволяют тестировать отношения, телепортацию и т.д.

---

## 9. Пример ресурсов (для Мирей Астор)

**`npc_mirei.tres`** (NPCData):

```gdscript
id = "npc.mirei"
display_name = "Мирей Астор"
last_name = "Астор"
description = "[b]Хозяйка "Кривого Рога"[/b]\nОна была инженером Машины Раскола..."
race = Race.ETHEREAL
sprite_light = preload("res://assets/npcs/mirei_light.png")
sprite_dark = preload("res://assets/npcs/mirei_dark.png")
move_speed = 40.0
interaction_radius = 80.0

schedule_light = preload("res://resources/npcs/schedules/mirei_light_schedule.tres")
schedule_dark = preload("res://resources/npcs/schedules/mirei_dark_schedule.tres")

dialogue_tree_light = preload("res://resources/npcs/dialogues/mirei_light_dialogue.tres")
dialogue_tree_dark = preload("res://resources/npcs/dialogues/mirei_dark_dialogue.tres")

shop_items_light = [ ... ]
shop_items_dark = [ ... ]

gift_preferences = preload("res://resources/npcs/mirei_gift_prefs.tres")
secret = preload("res://resources/npcs/mirei_secret.tres")
regular_phrases = preload("res://resources/npcs/mirei_phrases.tres")
```

**`mirei_light_schedule.tres`** (ScheduleData):

```gdscript
actions = [
    { "type": "STAND", "duration": 5.0 },
    { "type": "GO_TO_POINT", "target_point": Vector2(100, 50), "duration": 3.0 },
    { "type": "SIT", "target_object_id": "chair_1", "duration": 10.0 },
]
```

**`mirei_gift_prefs.tres`** (GiftPreferences):

```gdscript
preferences = {
    "light": [ { "item_id": "item.cotton_candy", "score": 5, "reject_chance": 0.0 } ],
    "dark": [ { "item_id": "item.shadow_essence", "score": 5, "reject_chance": 0.0 } ],
    "standard": []
}
```

(нелюбимые подарки не указаны - они будут иметь score = -5 по умолчанию)

---

## 10. Будущие расширения (после MVP)

- Полноценная система времени суток для расписания.
- Поддержка навигации с препятствиями (`NavigationAgent2D`).
- Динамическая смена расписания под влиянием ивентов.
- Система отношений между NPC (влияние на цены, диалоги).
- Полноценная система квестов с несколькими этапами.
- Случайные встречи и странствующие NPC.
- Визуальные индикаторы уровня отношений (иконки над NPC).

---

## 11. Технические заметки

- Все `Resource` должны быть сохранены в бинарном формате (`.tres` с `save_as`).
- Использовать `@tool` для тестирования в редакторе (отображение NPC, их расписания).
- Строгие типы для всех экспортов.
- Документировать публичные методы в компонентах.
- Следовать принципам из `CLAUDE.md`.
- Использовать гибко настраиваемые экспортные переменные (`@export`, `@export_range`).
- Группировать логическеи связанные настройки в блоки `@export_group` (например, `@export_group("Анимации")`)
