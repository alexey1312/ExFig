# ExFig: Стратегический анализ и пути развития

## Context

ExFig v2.8.0 — зрелый CLI для экспорта дизайн-ресурсов из Figma в iOS/Android/Flutter/Web. Написан на Swift 6.2, конфигурация через PKL. Есть Homebrew tap, Mint, mise, GitHub Action (отдельный репо `exfig-action`). Вопрос: куда развиваться и стоит ли реорганизовать структуру (отдельная GitHub org).

---

## 1. Конкурентный ландшафт

### Прямые конкуренты (Figma -> код)

| Инструмент                     | Тип                      | Платформы                     | Токены                | Цена            |
| ------------------------------ | ------------------------ | ----------------------------- | --------------------- | --------------- |
| **ExFig**                      | CLI (Swift)              | iOS, Android, Flutter, Web    | W3C DTCG v2025        | Бесплатно (MIT) |
| **figma-export** (RedMadRobot) | CLI (Swift)              | iOS, Android                  | Нет                   | Бесплатно       |
| **Figma Code Connect**         | Figma плагин + CLI       | React, SwiftUI, Compose, HTML | Нет (только сниппеты) | Бесплатно       |
| **Tokens Studio**              | Figma плагин + платформа | Web (CSS, JSON, CSS-in-JS)    | Полная поддержка      | Freemium        |
| **Style Dictionary**           | Node.js CLI              | Любые (трансформы)            | W3C DTCG              | Бесплатно       |
| **Specify**                    | SaaS платформа           | Любые (пайплайны)             | Да                    | Платно          |
| **Supernova**                  | SaaS платформа           | Любые                         | Да                    | Платно          |
| **Kigen**                      | Figma плагин             | Web (CSS, JSON)               | Частично              | Freemium        |

### Уникальные преимущества ExFig

1. **4 платформы в одном инструменте** — ни один CLI-конкурент этого не делает
2. **PKL конфигурация** — типобезопасность, валидация, наследование (уникально в нише)
3. **Batch processing** — параллельная обработка нескольких конфигов с общим rate limiting
4. **W3C DTCG v2025** — единственный Swift CLI с поддержкой нового стандарта
5. **Figma Code Connect** — генерация сниппетов для Dev Mode (iOS + Android)
6. **RTL, Dark Mode, High Contrast** — зрелая обработка вариантов
7. **Оффлайн работа** — `.tokens.json` без Figma API

### Слабые стороны / Gaps

1. **Нет GUI** — только CLI, порог входа выше чем у плагинов
2. **Нет веб-дашборда** — нет визуализации результатов
3. **Только Figma** — нет поддержки Penpot, Sketch, Adobe XD
4. **Нет Figma плагина** — всё через API, нет интерактивного выбора
5. **Документация только на English** — ограничивает русскоязычное сообщество

---

## 2. Тренды индустрии (2025-2026)

### W3C Design Tokens — стандарт созрел

- DTCG 2025.10 — первая стабильная версия (октябрь 2025)
- 20+ компаний-редакторов: Adobe, Google, Microsoft, Figma, Tokens Studio
- **ExFig уже поддерживает** — это сильная позиция

### Figma Code Connect UI + MCP

- Code Connect UI (2025) — маппинг компонентов прямо в Figma
- Figma Codex MCP (февраль 2026) — двунаправленный MCP-сервер для AI-агентов
- **ExFig генерирует Code Connect файлы** — но можно интегрироваться глубже

### AI-driven Design-to-Code

- Builder.io Visual Copilot, Locofy, Anima — AI-генерация кода из дизайна
- Figma MCP Server — AI-агенты получают доступ к дизайну напрямую
- **Возможность**: ExFig как часть AI-пайплайна (MCP server)

### Design System as Code

- Tokens Studio, Specify, Supernova — платформы управления дизайн-системами
- Infrastructure as Code паттерн пришёл в дизайн
- **ExFig с PKL** отлично вписывается в этот тренд

---

## 3. Пути развития

### A. Организационные

#### A1. GitHub Organization `exfig/`

**Рекомендация: ДА, пора.**

Текущая структура `alexey1312/ExFig` + `alexey1312/exfig-action` привязана к личному аккаунту.

**Что переносить в `exfig/` org:**

- `exfig/exfig` — основной CLI
- `exfig/exfig-action` — GitHub Action
- `exfig/homebrew-tap` — Homebrew формула
- `exfig/exfig.dev` — сайт/документация (будущее)
- `exfig/pkl-schemas` — PKL пакет (отдельная версионность)

**Зачем:**

- Профессиональный вид для пользователей и контрибьюторов
- Разделение ответственности (отдельные permissions для action)
- Возможность добавлять maintainers
- Брендинг: `brew install designpipe/tap/exfig` вместо `alexey1312/tap/exfig`
- GitHub Sponsors на уровне организации

**Риски:**

- Переименование сломает существующие ссылки (GitHub делает редиректы)
- Нужно обновить PKL package URI (`package://github.com/exfig/exfig/...`)
- Homebrew tap URL изменится

#### A2. Лицензия и монетизация

Оставить MIT для CLI. Доход через GitHub Sponsors / Open Collective.

---

### B. Продуктовые направления

#### B1. ExFig MCP Server (высокий приоритет)

Превратить ExFig в MCP-сервер для AI-агентов (Claude, Cursor, Codex).

**Возможности:**

- `exfig_export` — запуск экспорта по конфигу
- `exfig_inspect` — просмотр текущих ресурсов в Figma файле
- `exfig_diff` — сравнение версий (что изменилось в дизайне)
- `exfig_validate` — валидация PKL конфигурации
- `exfig_tokens_info` — инспекция W3C токенов

**Почему сейчас:** Figma Codex MCP (февраль 2026) открывает двусторонний канал Figma<->код. ExFig MCP + Figma MCP = полный AI-пайплайн.

#### B2. Style Dictionary интеграция

ExFig экспортирует W3C DTCG токены -> Style Dictionary трансформирует в любые форматы.

**Что добавить:**

- `exfig tokens transform` — встроенные трансформы (как Style Dictionary, но на Swift)
- Или: генерация Style Dictionary конфига из ExFig PKL
- Мост между двумя экосистемами

#### B3. Figma плагин-компаньон

Лёгкий Figma плагин для:

- Визуального выбора фреймов (вместо ручного ввода имён)
- Превью экспорта прямо в Figma
- Генерации `exfig.pkl` конфига из выбранных элементов
- Quick Actions: "Export this frame as icons"

#### B4. Веб-дашборд для дизайн-системы

`exfig dashboard` — локальный веб-сервер показывающий:

- Все экспортированные цвета/иконки/типографику
- Diff между версиями
- Покрытие (какие токены используются в коде)
- Статус CI/CD экспортов

#### B5. Поддержка Penpot

[Penpot](https://penpot.app/) — открытый конкурент Figma, растёт быстро. Добавить `PenpotAPI` модуль по аналогии с `FigmaAPI`.

#### B6. `exfig init --interactive`

Интерактивный мастер создания конфигурации:

- Выбор платформ
- Подключение к Figma (OAuth flow)
- Автоопределение фреймов с цветами/иконками
- Генерация PKL конфига

---

### C. Технические улучшения

#### C1. Plugin system (расширяемость)

Позволить сообществу создавать:

- Кастомные экспортеры (например, Kotlin Multiplatform)
- Кастомные трансформы токенов
- Интеграции с другими инструментами

#### C2. Watch mode

`exfig watch` — следить за изменениями в Figma через webhooks и автоматически ре-экспортировать.

#### C3. Figma REST API v2 / GraphQL

Следить за эволюцией Figma API, потенциальный переход на более эффективный протокол.

#### C4. WASM / cross-platform binary

Компиляция ExFig в WASM для запуска в браузере (для веб-дашборда) или через `npx`.

---

## 4. Решения

- **Аудитория**: Оба сегмента (indie + enterprise). Стратегия "easy to start, scales well" (как Tailwind).
- **Монетизация**: Open Source + GitHub Sponsors. CLI остаётся MIT, без платных tier'ов.
- **Направления**: Все четыре — MCP Server, GitHub Org, новые источники данных, веб-дашборд.

---

## 5. Дорожная карта

### Фаза 1 — GitHub Organization + фундамент

**Цель:** Профессиональная структура и видимость проекта.

1. **Создать GitHub org `exfig/`**
   - Перенести `ExFig` -> `exfig/exfig`
   - Перенести `exfig-action` -> `exfig/action`
   - Создать `exfig/homebrew-tap`
   - Настроить GitHub Sponsors на уровне org
   - GitHub автоматически создаёт редиректы со старых URL

2. **Обновить все ссылки**
   - PKL package URI: `package://github.com/exfig/exfig/...`
   - README installation instructions
   - DocC сайт -> GitHub Pages на org
   - CI workflows (если ссылаются на owner)

3. **Landing page `exfig.dev`**
   - Простой статический сайт (Hugo/Astro)
   - Конкурентная таблица (ExFig vs figma-export vs Tokens Studio vs Style Dictionary)
   - Quick Start для каждой платформы
   - Ссылка на DocC документацию

4. **`exfig init --interactive`**
   - Интерактивный выбор платформ (Noora UI)
   - OAuth flow для Figma (или ввод токена)
   - Автоопределение фреймов из Figma файла
   - Генерация готового `exfig.pkl`

### Фаза 2 — ExFig MCP Server

**Цель:** Сделать ExFig доступным для AI-агентов (Claude Code, Cursor, Codex).

5. **MCP Server (stdio transport)**
   - Отдельный таргет `ExFigMCP` в Package.swift
   - Инструменты: `exfig_export`, `exfig_inspect`, `exfig_diff`, `exfig_validate`, `exfig_tokens_info`
   - Ресурсы MCP: PKL схемы, шаблоны конфигов
   - Публикация: `npx @exfig/mcp` (обёртка) или `brew install exfig/tap/exfig-mcp`

6. **Интеграция с Figma MCP**
   - Документация: "ExFig MCP + Figma MCP = полный AI дизайн-пайплайн"
   - Пример Claude Code `.mcp.json` с обоими серверами
   - AI может: посмотреть дизайн (Figma MCP) -> экспортировать (ExFig MCP)

### Фаза 3 — Расширение источников данных

**Цель:** Выйти за пределы Figma.

7. **Абстракция DesignSource**
   - Протокол `DesignSource` вместо прямой зависимости от FigmaAPI
   - `FigmaDesignSource` (текущий), `PenpotDesignSource`, `TokensFileSource` (уже есть)
   - Позволяет подключать новые источники без переписывания экспортеров

8. **Penpot API поддержка**
   - Модуль `PenpotAPI` по аналогии с `FigmaAPI`
   - Penpot REST API для получения компонентов, цветов, типографики
   - PKL конфиг: `source = "penpot"` вместо `figma {}`

9. **Sketch / Tokens Studio JSON**
   - `.sketch` файлы — прямой парсинг (ZIP с JSON)
   - Tokens Studio JSON формат — прямой импорт (уже частично есть через `.tokens.json`)

### Фаза 4 — Веб-дашборд + экосистема

**Цель:** Визуализация и расширяемость.

10. **`exfig dashboard`**
    - Локальный веб-сервер (Swift + Hummingbird или встроенный HTTP)
    - Галерея цветов, иконок, типографики
    - Diff между экспортами (до/после)
    - Token coverage: какие токены используются в коде
    - JSON report -> визуализация

11. **Watch mode**
    - `exfig watch --webhook` — Figma webhook для реактивного ре-экспорта
    - `exfig watch --poll 5m` — polling как fallback
    - Интеграция с дашбордом (live reload)

12. **Plugin system**
    - Swift Package Plugin или динамические библиотеки
    - Кастомные экспортеры (Kotlin Multiplatform, .NET MAUI)
    - Кастомные трансформы токенов
    - Community registry

---

## Sources

- [Tokens Studio](https://tokens.studio/) — основной конкурент в токенах
- [Style Dictionary](https://styledictionary.com/) — де-факто стандарт трансформации токенов
- [W3C DTCG 2025.10](https://tr.designtokens.org/format/) — стабильная спецификация
- [Figma Code Connect](https://github.com/figma/code-connect) — официальный SDK
- [Figma Codex MCP](https://alexbobes.com/tech/figma-mcp-the-cto-guide-to-design-to-code-in-2026/) — AI интеграция
- [Kigen](https://kigen.design/) — Figma плагин для токенов
- [Design Token Management Tools Guide](https://cssauthor.com/design-token-management-tools/)
