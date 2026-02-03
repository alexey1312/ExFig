# Proposal: Integrate Noora Terminal UI

**Change ID:** `integrate-noora-terminal-ui`
**Status:** Draft
**Created:** 2026-02-03

## Summary

Интеграция библиотеки [Noora](https://github.com/tuist/Noora) (tuist/Noora v0.54.0) для семантического форматирования терминального вывода. Частичная замена кастомных компонентов на стандартизированные API Noora.

## Motivation

### Текущее состояние

TerminalUI содержит 18 файлов с кастомными реализациями:

| Компонент             | LOC  | Назначение                   |
| --------------------- | ---- | ---------------------------- |
| Spinner               | 150  | Braille-анимация загрузки    |
| ProgressBar           | 250  | Прогресс с ETA               |
| BatchProgressView     | 400+ | Многострочный batch-прогресс |
| TerminalOutputManager | 150  | Координация вывода           |
| ANSICodes             | 60   | ANSI escape-коды             |
| TTYDetector           | 50   | Определение TTY              |
| Lock<T>               | 30   | Thread-safe wrapper          |
| TerminalUI            | 430  | Фасад                        |
| Formatters (4 файла)  | 300  | Форматирование сообщений     |

### Проблемы

1. **Rainbow для цветов** — низкоуровневый, требует явных `.red`, `.green` вызовов
2. **Дублирование логики** — icon + color паттерн повторяется в info/success/warning/error
3. **Нет семантики** — цвета применяются напрямую, а не через intent (success, danger)

### Преимущества Noora

1. **Семантический API** — `.success("OK")`, `.danger("error")`, `.command("exfig")`
2. **Темизация** — единая цветовая схема через Noora theme
3. **Готовые компоненты** — `progressBarStep`, `yesOrNoChoicePrompt`
4. **Используется в экосистеме** — tuist, swift-index

## Scope

### Заменить на Noora

| Текущее               | Noora API                 | Приоритет |
| --------------------- | ------------------------- | --------- |
| Rainbow color calls   | `TerminalText` components | P0        |
| Icon + color patterns | `.success()`, `.danger()` | P0        |
| Simple progress       | `progressBarStep`         | P1        |

### Оставить кастомным

| Компонент                 | Причина                                                      |
| ------------------------- | ------------------------------------------------------------ |
| **Spinner**               | Braille-анимация с 12.5 FPS, уникальный UX                   |
| **ProgressBar**           | ETA calculation, детальный счётчик (current/total)           |
| **BatchProgressView**     | Сложный многострочный UI с rate-limit статусом               |
| **TerminalOutputManager** | Координация анимаций и логов, race condition prevention      |
| **ANSICodes**             | Низкоуровневые коды (cursor hide/show), не связаны с цветами |
| **Lock<T>**               | Utility, не UI                                               |

## Design Decision

### Подход: Постепенная миграция

1. **Phase 1 (P0)**: Семантическое форматирование
   - Заменить Rainbow на `TerminalText` в форматтерах
   - Использовать `NooraUI.format()` для вывода
   - Сохранить структуру TerminalUI facade

2. **Phase 2 (P1)**: Простой progress
   - Использовать `progressBarStep` для одиночных операций без детального ETA
   - Оставить кастомный ProgressBar для детального прогресса

### Архитектурное решение

```
┌─────────────────────────────────────────────────────────┐
│                    TerminalUI (facade)                   │
├─────────────────────────────────────────────────────────┤
│  NooraUI.format()  │  Spinner  │  ProgressBar  │  Batch │
│  (semantic text)   │ (custom)  │   (custom)    │(custom)│
├─────────────────────────────────────────────────────────┤
│                    TerminalOutputManager                 │
│                  (coordination layer)                    │
└─────────────────────────────────────────────────────────┘
```

## Non-Goals

- Полная замена всех компонентов на Noora
- Изменение публичного API TerminalUI
- Удаление Rainbow (останется для legacy и edge cases)

## Risks

| Risk                | Mitigation                                          |
| ------------------- | --------------------------------------------------- |
| Noora API изменится | Закрепить версию 0.54.0+, NooraUI адаптер изолирует |
| Производительность  | Noora format() — O(1), не критично                  |
| Совместимость тем   | Использовать default theme                          |

## Success Criteria

1. Форматтеры используют `TerminalText` для семантики
2. Вывод визуально идентичен (цвета сохранены)
3. Тесты форматтеров проходят
4. Build без warnings
