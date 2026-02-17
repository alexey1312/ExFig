# Proposal: PKL Schema v2 — Entry-Level Overrides + Defaults

**Status:** Draft
**Author:** Claude
**Created:** 2026-02-07

## Why

Реальные проекты вынуждены использовать **6 отдельных PKL-файлов** для одного проекта, потому что `xcassetsPath`, `templatesPath` живут на уровне `iOSConfig`, а `figma.lightFileId` — на корневом уровне. Все entries в одном конфиге обязаны использовать одни и те же значения. Это приводит к фрагментации конфигурации, дублированию общих настроек и усложнению batch-обработки.

Кроме того, PKL-схемы не используют возможности default values, из-за чего каждый конфиг обязан указывать очевидные значения вроде `nameStyle = "camelCase"` и `format = "pdf"`.

## What Changes

- Добавить **entry-level overrides** для `xcassetsPath`, `templatesPath`, `figmaFileId` и аналогичных полей на всех платформах — позволяет объединить 6 файлов в 1
- Добавить **default values** в PKL-схемы для часто используемых полей (`nameStyle`, `format`, `scales`, `useColorAssets` и др.) — сокращает бойлерплейт в конфигах
- Добавить **constraints** (`!isEmpty`, `isBetween`) для валидации на уровне PKL — ошибки ловятся до запуска Swift-кода
- Обновить Swift-код для resolution logic: entry-level override > config-level value
- Обновить example configs и документацию

Все изменения **обратно совместимы** — новые поля опциональны, defaults не меняют поведение существующих конфигов.

## Capabilities

### New Capabilities

- `entry-overrides`: Per-entry override полей, которые раньше жили только на уровне platform config (xcassetsPath, templatesPath, figmaFileId, mainRes, output и др.)

### Modified Capabilities

- `configuration`: Добавление default values и constraints в существующие PKL-схемы. Изменение resolution logic в Swift-коде для поддержки entry-level overrides.

## Impact

- **PKL Schemas**: `Common.pkl`, `iOS.pkl`, `Android.pkl`, `Flutter.pkl`, `Web.pkl`, `Figma.pkl` — новые поля + defaults + constraints
- **Generated Code**: `Sources/ExFigConfig/Generated/*.pkl.swift` — регенерация через `codegen:pkl`
- **Swift Logic**: `Sources/ExFigCLI/Subcommands/Export/Plugin*Export.swift`, `Sources/ExFig-*/Config/*Entry.swift`, `Sources/ExFigCLI/Loaders/*.swift` — resolution logic
- **Examples**: `Sources/ExFigCLI/Resources/Schemas/examples/` — обновление
- **Tests**: Новые тесты для entry-level overrides + обновление PKL fixtures
- **No breaking changes**: Все новые поля optional, defaults не меняют семантику
