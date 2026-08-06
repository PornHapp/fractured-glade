# Игрок - Скрипты

Архитектура игрока построена по принципу **композиции**: корневой скрипт `player.gd`
связывает компоненты сигналами и делегирует им всю логику. Игрок сам ничего не
вычисляет - он координирует.

---

## Структура

```
scripts/player/
├── player.gd                          # Корневой скрипт (facade)
├── README.md                          # Этот файл
│
└── components/
    ├── input_handler.gd               # Ввод (клавиатура/геймпад)
    ├── movement_controller.gd         # Физика движения и прыжка
    ├── animation_controller.gd        # Анимации и зеркалирование
    ├── health_component.gd            # Здоровье и неуязвимость
    │
    └── state_machine/
        ├── state.gd                   # Базовый класс состояния
        ├── state_machine.gd           # Менеджер состояний
        └── states/
            ├── idle_state.gd          # Покой (стоит на полу)
            ├── run_state.gd           # Движение (идёт/бежит)
            ├── jump_state.gd          # Подъём (в воздухе, Y < 0)
            ├── fall_state.gd          # Падение (в воздухе, Y ≥ 0)
            ├── attack_state.gd        # Атака (взаимодействие)
            ├── hurt_state.gd          # Получение урона
            └── dead_state.gd          # Смерть
```

---

## Как это работает

### Цикл физического такта (`_physics_process`)

```
InputHandler.poll()          →  читаем ввод
HealthComponent.update()     →  таймер неуязвимости
StateMachine.update()        →  текущее состояние → physics_update()
MovementController.update()  →  физика: гравитация, движение, прыжок
AnimationController.update() →  выбираем анимацию по состоянию и facing
```

### Поток данных

```
Ввод (клавиши) → InputHandler → MovementController (физика)
                              → StateMachine (переходы)
                              → AnimationController (визуал)

Здоровье → HealthComponent → StateMachine (урон/смерть)
                            → AnimationController (мигание)
```

---

## Компоненты

### Player (`player.gd`)

Корневой узел `CharacterBody2D`. Фасад: собирает компоненты, связывает
сигналами, выдаёт публичный API для внешних систем.

**Сигналы** (публичный контракт):

- `attack_started(tool_name: StringName)` - атака началась
- `attack_finished(tool_name: StringName)` - атака закончилась
- `health_changed(new_value: int, old_value: int)` - здоровье изменилось
- `damaged(amount: int, new_health: int)` - получен урон
- `died` - игрок умер

**Публичные методы:**

- `play_attack(tool_name)` - начать атаку
- `play_interact()` - проиграть анимацию взаимодействия
- `take_damage(amount)` - нанести урон
- `die()` - убить игрока
- `revive()` - восстановить игрока

**Свойства:**

- `current_tool: StringName` - текущий инструмент (устанавливается хотбаром)
- `health: int` - текущее здоровье (только чтение)

---

### InputHandler (`input_handler.gd`)

Единственный модуль, который работает с `Input`. Опрашивает действия
каждый такт и публикует состояние через переменные и сигналы.

**Сигналы:** `jump_pressed`, `jump_released`, `attack_pressed`
**Переменная:** `direction: float` (-1, 0, 1)

---

### MovementController (`movement_controller.gd`)

Физика движения: горизонталь (с ускорением/трением), гравитация,
прыжок (койот-таймер + буфер нажатия + переменная высота).

Не читает Input - получает данные из InputHandler через setup().

**Ключевые настройки:**

- `move_speed` - базовая скорость (150 px/с)
- `speed_multiplier` - множитель от внешних факторов
- `jump_velocity` - скорость прыжка (-320)
- `coyote_time` - койот-таймер (0.1 сек)
- `jump_buffer_time` - буфер прыжка (0.12 сек)

---

### AnimationController (`animation_controller.gd`)

Выбирает анимацию по имени состояния и ставит `flip_h` по направлению
взгляда. Единственный модуль, который знает имена анимаций из SpriteFrames.

**Принцип зеркалирования:** исходник спрайта смотрит влево. При
`facing > 0` (вправо) ставится `flip_h = true`. Все анимации единые
на оба направления.

**Методы:**

- `update(state_name, facing, horizontal_speed)` - обновление каждым тактом
- `play_interact()` - анимация взаимодействия
- `play_hurt()` - анимация получения урона
- `play_dead()` - анимация смерти
- `play(anim)` - универсальный проигрыватель с фолбэком

---

### HealthComponent (`health_component.gd`)

Здоровье, окно неуязвимости и смерть. Чистая логика без визуала.

**Сигналы:** `health_changed`, `damaged`, `died`, `invulnerability_changed`
**Настройки:** `max_health` (100), `invulnerability_time` (1.0 сек)

---

### StateMachine (`state_machine.gd`)

Управляет переходами между состояниями. Состояния - узлы-дети.
Текущее состояние делегирует физику в `physics_update()`.

**Константы имён состояний:** `IdleState`, `RunState`, `JumpState`,
`FallState`, `AttackState`, `HurtState`, `DeadState`

**Ключевой метод:** `get_movement_target()` - возвращает целевое
состояние движения на основе пола, скорости по Y и ввода.

---

### State (`state.gd`)

Базовый класс. Каждое состояние - узел-ребёнок StateMachine.

**Доступные ссылки** (заполняются автоматически):
`player`, `state_machine`, `input`, `movement`, `animation`, `health`

**Методы для переопределения:** `enter()`, `exit()`, `physics_update()`

---

## Состояния

| Состояние | Описание | Визуал | Переход |
|---|---|---|---|
| **IdleState** | Стоит на полу, нет ввода | idle | Ввод → RunState |
| **RunState** | Двигается по полу | idle / run | Ввод прекратился → IdleState |
| **JumpState** | В воздухе, Y < 0 | jump | Y ≥ 0 → FallState |
| **FallState** | В воздухе, Y ≥ 0 | fall | Приземлился → IdleState / RunState |
| **AttackState** | Атака/взаимодействие | interact | Таймер истёк → IdleState / RunState |
| **HurtState** | Получение урона | hurt | Таймер истёк → IdleState / RunState |
| **DeadState** | Смерть: hurt → die | hurt → die | (пока ничего) |

---

## Анимации (SpriteFrames)

Все анимации - одни на оба направления (зеркалирование через flip_h).

| Имя | Кол-во кадров | Loop | Источник |
|---|---|---|---|
| idle | 6 | да | idle_left.png |
| run | 6 | да | run_left.png |
| jump | 4 | нет | jump_left.png |
| fall | 5 | нет | fall_left.png |
| die | 9 | нет | death_left.png |
| hurt | 5 | нет | dmg_left.png |
| interact | 5 | нет | interact_left.png |

Спрайты находятся в `assets/textures/player/astral_f/`.

---

## Добавление нового состояния

1. Создать скрипт в `states/`, наследовать `State`
2. Переопределить `enter()`, `exit()`, `physics_update()`
3. Добавить узел-ребёнок в `StateMachine` в сцене `player.tscn`
4. При необходимости - добавить имя в `StateMachine` как константу `STATE_*`
