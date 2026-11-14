# FeatherCage Cheats

Cheat / research mod for the local **Hello Neighbor — Project FeatherCage** build (UE 4.27.2, Shipping).
Written as a **UE4SS v4.0.0** Lua mod: the game executable is **not** patched, everything lives in Lua.

Чит-мод для локальной сборки Hello Neighbor «Project FeatherCage»: полёт, noclip и спавн любого
предмета в любом количестве. Плюс инструменты для изучения игры изнутри (классы, акторы, свойства,
функции).

```
F1  fly          F2  noclip        F3/F11  spawn item
F12 next item    Ctrl+F12 prev     PageUp/PageDown  count
```

---

## Возможности

| Возможность | Как включить |
|---|---|
| Полёт | `F1` |
| Noclip (полёт + без коллизии) | `F2` |
| Спавн выбранного предмета | `F3` или `F11` |
| Выбор предмета из списка | `F12` (следующий), `Ctrl+F12` (предыдущий) |
| Количество при спавне | `PageUp` / `PageDown` (±1), `Ctrl+PageUp/PageDown` (±10), `Ctrl+F3` — пресеты 1/5/10/25/50/100/250/500 |
| Удалить заспавненное модом | `Ctrl+F11` |
| Телепорт вперёд по камере | `F4` |
| Сохранить / вернуть позицию | `F5` / `F6` |
| Дамп всех actor-классов игры | `F7` |
| Список предметов | `F8` |
| Скан инвентаря пешки | `F9` |
| God mode | `fc god` |

- **Полёт** — `CharacterMovement.MovementMode = MOVE_Flying` (`5`), скорость через `MaxFlySpeed`.
- **Noclip** — полёт + `SetActorEnableCollision(false)` у пешки.
- **Спавн** — `UWorld:SpawnActor` перед камерой (сеткой 5 в ряд), заспавненные акторы
  полноценные: их можно подобрать и использовать.
- **Список предметов** строится по иерархии: всё, что наследуется от `ItemHN` / `ItemLogic.Item`
  (146 классов в уровне), с запасным вариантом по имени `BP_Item_*`.
- **Спавнить можно не только предметы**, а вообще любой actor-класс из `fc list`
  (605 классов в уровне) — двери, NPC, триггеры, что угодно.
- Уведомления рисуются прямо на экране через `KismetSystemLibrary:PrintString`
  (+ `ClientMessage` как fallback), поэтому видно, что произошло.

## Консольные команды

Если открывается консоль игры (`~` или `F10`):

```
fc help
fc fly | fc noclip | fc speed 3000
fc spawn <class> [n] [dist] [spread]   # например: fc spawn BP_Item_Key 5
fc items [фильтр]                      # список предметов + item_candidates.txt
fc item 12 10 go                       # 12-й предмет, 10 штук, сразу заспавнить
fc next | fc prev                      # листать список предметов
fc sel <класс> | fc count <n>
fc tp <x> <y> <z> | fc tpf [dist]
fc kill BP_Item_AlarmClock             # удалить все такие акторы в уровне
fc clear                               # удалить заспавненное модом
fc list [фильтр]                       # все actor-классы (можно спавнить любой)
fc keys [фильтр]                       # доступные имена клавиш (для своих биндов)
fc actors [фильтр]                     # дамп акторов уровня
fc dump | fc study <класс> | fc inv
fc cheats | fc cheat <fn>              # функции CheatManager самой игры
fc save | fc load | fc god | fc status | fc test
```

`fc study` проходит по цепочке `SuperStruct` и печатает свойства (с типами) и функции класса,
включая унаследованные.

## Очередь команд через файл

Встроенная консоль UE может не открываться от синтетического ввода, поэтому есть надёжный обходной
путь: мод раз в секунду проверяет файл

```
<Win64>\ue4ss\Mods\FeatherCageCheats\commands.txt
```

Каждая строка — команда (можно с префиксом `fc` или без). После выполнения файл удаляется.

```powershell
# положить команду в очередь
powershell -ExecutionPolicy Bypass -File .\tools\send_cmd.ps1 fc status
powershell -ExecutionPolicy Bypass -File .\tools\send_cmd.ps1 fc spawn BP_Item_Key 20
```

Это же используется для автоматизации: см. `tools/`.

## Установка

### Вариант 1 — установщик (проще всего)

Скачать **`FeatherCageCheats-Setup-1.0.0.exe`** из [Releases](https://github.com/gemerte/HNRenovated-all-possibilities/releases)
(или взять из `installer/dist/`) и запустить. Если игра лежит на рабочем столе, папка определится сама,
иначе укажите её вручную — это корень, где находятся `HNRenovated` и `Project Feathercage.exe`.

Установщик делает всё сам:

- `dwmapi.dll` + папку `ue4ss\` → `HNRenovated\Binaries\Win64\`
- включает консоль UE4SS в `UE4SS-settings.ini`
- копирует мод в `ue4ss\Mods\FeatherCageCheats\`
- прописывает `FeatherCageCheats : 1` в `mods.txt` (перед `Keybinds`, без дублей)
- существующие `UE4SS-settings.ini` и `mods.txt` не затирает, только дополняет

Удаление — обычное, через «Программы и компоненты»; настройки UE4SS при этом остаются.

Пересобрать установщик: `installer\build.ps1` (нужен [Inno Setup 6](https://jrsoftware.org/isinfo.php),
`winget install JRSoftware.InnoSetup`).

### Вариант 2 — вручную

#### 1. UE4SS

Нужен [UE4SS v4.0.0](https://github.com/UE4SS-RE/RE-UE4SS/releases) (Lua API, UE 4.27).

```
<Game>\HNRenovated\Binaries\Win64\
    dwmapi.dll          <- прокси-DLL из архива UE4SS
    ue4ss\
        UE4SS.dll
        UE4SS-settings.ini
        Mods\
```

В `UE4SS-settings.ini` включить консоль (по желанию, но с ней удобнее):

```ini
[Debug]
ConsoleEnabled = 1
GuiConsoleEnabled = 1
GuiConsoleVisible = 1
```

#### 2. Мод

```powershell
# путь к игре можно не указывать, если она лежит на рабочем столе
.\deploy.ps1
.\deploy.ps1 -Game "D:\Games\Project FeatherCage"
```

Скрипт копирует `mod\FeatherCageCheats` в `<Game>\HNRenovated\Binaries\Win64\ue4ss\Mods\`
и дописывает `FeatherCageCheats : 1` в `mods.txt`.

Запустить игру. В логе `ue4ss\UE4SS.log` должно появиться `[FeatherCage] mod loaded`.

#### 3. Горячая перезагрузка

Окно **UE4SS Debugging Tools** → кнопка **Restart All Mods**. Перезапускать игру не нужно.

## Файлы, которые создаёт мод

В `<Win64>\` и в `ue4ss\Mods\FeatherCageCheats\`:

| Файл | Что внутри |
|---|---|
| `actor_classes.txt` | все actor-классы игры: имя + полный путь |
| `item_candidates.txt` | предметы-кандидаты с индексами для `fc item` |
| `world_actors.txt` | акторы текущего уровня (`fc actors`) |

Дампы пересобираются автоматически при загрузке уровня и по `F7` / `F8`.

## Структура репозитория

```
mod/FeatherCageCheats/Scripts/main.lua   сам мод (весь код)
deploy.ps1                               установка/обновление в игру (PowerShell)
installer/                               исходник установщика (Inno Setup) + build.ps1
  dist/FeatherCageCheats-Setup-*.exe     готовый установщик
vendor/UE4SS_v4.0.0/                     UE4SS v4.0.0 (dwmapi.dll + ue4ss\), кладётся установщиком
tools/                                   автоматизация и отладка (PowerShell/Python)
  send_cmd.ps1       команда в файловую очередь
  gui_click.ps1      надёжный клик по кнопке в окне UE4SS
  windows.ps1        список окон игры / UE4SS
  focus_send.ps1     фокус окну + SendKeys
  post_keys.ps1      PostMessage-ввод в окно игры
  click.ps1          клик по экранным координатам
  screenshot.ps1     скриншот экрана
  crop.ps1           обрезка скриншота
  play.ps1           запуск игры и ожидание загрузки уровня
  mock_test.py       офлайн-прогон мода на Lua-мокапе UE4SS API (lupa)
  scan_build.py      поиск версии движка/пакетов в бинарниках
  fix_encoding.py    нормализация main.lua (тире -> дефис, LF)
```

`tools/mock_test.py` позволяет проверить, что мод загружается и команды диспатчатся, вообще не
запуская игру:

```powershell
pip install lupa
python tools\mock_test.py
```

## Как это работает

- `RegisterConsoleCommandHandler("fc", ...)` — обработчик консольных команд.
- `RegisterKeyBind(Key.F1, fn)` / `RegisterKeyBind(Key.F12, { ModifierKey.CONTROL }, fn)` — хоткеи.
- `StaticFindObject("/Script/Engine.Actor")`, `FindObjects(0, UClassClass, nil, nil, 0, false)` —
  каталог классов (шестой параметр `false` = включая наследников).
- `UStruct:ForEachFunction` / `ForEachProperty` перебирают только члены самого структуры, поэтому
  для полного списка нужен обход `GetSuperStruct()`.
- `ExecuteInGameThreadWithDelay` / `LoopInGameThreadWithDelay` — отложенный авто-дамп и опрос
  `commands.txt`.
- `RegisterLoadMapPostHook` — сброс каталога при смене уровня.

## Ограничения

- Мод рассчитан на конкретную сборку (UE 4.27.2 Shipping) и имена вида `ItemHN` / `ItemLogic.Item`.
  На других версиях игры список предметов может быть пустым — тогда работает `fc list` + `fc spawn`.
- Кап спавна — 500 акторов за раз, чтобы не убить производительность.
- Консоль игры от `SendKeys`/`PostMessage` не открывается (raw input) — используйте файловую очередь.
- `fc clear` удаляет только то, что заспавнил мод в текущей сессии (после перезагрузки мода список
  пуст); `fc kill <class>` удаляет все акторы класса в уровне.

## Дисклеймер

Проект для локальной отладочной сборки и изучения UE4 изнутри. Используйте на своей копии игры.
Код предоставляется как есть, без гарантий. UE4SS распространяется под MIT (см. его репозиторий);
бинарники UE4SS в этот репозиторий не входят.
