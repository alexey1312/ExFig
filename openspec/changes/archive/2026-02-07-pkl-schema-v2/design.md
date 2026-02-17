# Design: PKL Schema v2 — Entry-Level Overrides + Defaults

## Context

ExFig v2.0 перешёл на PKL-конфигурацию с plugin architecture. Реальный проект выявил ограничение: `xcassetsPath`, `templatesPath` задаются на уровне `iOSConfig`, а `figma.lightFileId` — на корневом уровне `figma`. Все entries в одном конфиге вынуждены использовать одинаковые значения, что приводит к 6 отдельным PKL-файлам вместо одного.

Текущие PKL-схемы также не используют default values — каждый конфиг обязан явно указывать очевидные значения (`nameStyle = "camelCase"`, `format = "pdf"`).

## Goals / Non-Goals

**Goals:**

- Позволить задавать `xcassetsPath`, `templatesPath`, `figmaFileId` на уровне каждого entry
- Добавить sensible defaults для часто используемых полей
- Добавить PKL constraints для раннего обнаружения ошибок
- Полная обратная совместимость — существующие конфиги работают без изменений

**Non-Goals:**

- Изменение структуры plugin architecture
- Изменение CLI интерфейса
- Миграция пользовательских конфигов (они продолжают работать)
- Публикация PKL package registry

## Decisions

### 1. Entry-level overrides через optional поля

**Решение:** Добавить optional поля (`xcassetsPath: String?`, `templatesPath: String?`, `figmaFileId: String?`) непосредственно в entry классы PKL-схем.

**Альтернатива:** Вложенная структура `overrides { xcassetsPath = "..." }` — отклонена: добавляет лишний уровень вложенности без пользы.

**Альтернатива:** Отдельный `defaults` блок на уровне config — отклонена: не решает задачу per-entry различий (разные entries могут указывать на разные Figma-файлы).

**Rationale:** Optional поля — самый простой и идиоматичный подход в PKL. Resolution logic `entry.field ?? config.field` уже используется в проекте для других полей.

### 2. figmaFileId на FrameSource

**Решение:** Добавить `figmaFileId: String?` в `Common.FrameSource` (base class для Icons/Images entries).

**Rationale:** Icons и Images наследуют от `FrameSource` и используют `figma.lightFileId` для загрузки данных. `ColorsEntry` наследует от `VariablesSource`, где уже есть `tokensFileId` — симметрично.

**Не добавляем** `figmaFileId` в `VariablesSource` — colors entries уже имеют собственный `tokensFileId`.

### 3. Defaults в PKL, не в Swift

**Решение:** PKL defaults применяются при `pkl eval` до Swift. Сгенерированный Swift-код НЕ меняется.

**Rationale:**

- PKL defaults — идиоматичный подход
- Один источник правды (schema)
- `pkl eval --format json` покажет resolved values
- Zero diff в сгенерированном Swift-коде (`codegen:pkl`)
- Существующие конфиги получают defaults автоматически

### 4. Constraints в PKL

**Решение:** Использовать PKL constraints (`!isEmpty`, `isBetween`) для обязательных строковых полей и числовых диапазонов.

**Rationale:** PKL ловит ошибки на этапе evaluation, до Swift runtime. Это улучшает developer experience — ошибки понятнее и раньше.

### 5. Resolution order: entry > config

**Решение:** Для каждого overridable поля: `entry.xcassetsPath ?? config.xcassetsPath`.

**Где менять:**

- `Plugin*Export.swift` — передача resolved paths в exporters
- `*Entry.swift` extensions — computed properties для resolved URLs
- Loaders — `entry.figmaFileId ?? figma.lightFileId`

**Принцип:** Один resolution point на поле, не разбросанный по коду.

## Risks / Trade-offs

| Risk                                                               | Mitigation                                                                                                                |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| Пользователи могут не понять, что entry-level overrides существуют | Документация + example configs с комментариями                                                                            |
| Defaults могут не совпадать с ожиданиями пользователей             | Defaults выбраны из реальных конфигов (iOS: camelCase, PDF; Android: snake_case, PNG)                                     |
| Constraints могут сломать существующие невалидные конфиги          | Constraints только на полях, которые и раньше были required; `!isEmpty` только для строк, которые не имеют смысла пустыми |
| Рост количества optional полей в entry типах                       | Приемлемо — PKL optional поля не требуют указания, IDE подсказывает                                                       |

## Open Questions

- Нужен ли `figmaFileId` на `VariablesSource` (colors)? Сейчас colors используют `tokensFileId`, что уже per-entry. Ответ: нет, не нужен.
