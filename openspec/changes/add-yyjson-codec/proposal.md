# Proposal: Add YYJSON Codec

**Status:** Draft
**Author:** Claude
**Created:** 2026-02-03

## Summary

Добавить высокопроизводительный JSON кодек на основе [swift-yyjson](https://github.com/mattt/swift-yyjson), по образцу реализации из [swift-index](https://github.com/alexey1312/swift-index).

## Motivation

### Текущее состояние

Проект использует Foundation `JSONEncoder`/`JSONDecoder` в 17+ местах:

- FigmaAPI: декодирование ответов API (критичный путь)
- ExFig: кэширование (checkpoint, image tracking, node hashing)
- XcodeExport: генерация Contents.json для xcassets

### Проблема

Foundation JSON кодеки:

- Медленные (~16× медленнее YYJSON на twitter.json benchmark)
- Много аллокаций (6,600+ vs 3 у YYJSON)
- Особенно заметно при batch-обработке больших Figma файлов

### Решение

Централизованный `JSONCodec` адаптер:

- Drop-in замена через статические методы
- Единая точка конфигурации
- Поддержка sorted keys для детерминированного вывода (нужно для хэширования)

## Scope

### В scope

- Добавить swift-yyjson зависимость
- Создать `JSONCodec` enum в ExFigCore
- Мигрировать существующие использования JSONEncoder/JSONDecoder

### Вне scope

- YYJSONValue DOM API (не нужен для текущих use cases)
- JSON5 парсинг

## Design Decisions

### Почему ExFigCore?

`JSONCodec` будет использоваться в:

- FigmaAPI (декодирование)
- ExFig (кэширование)
- XcodeExport (Contents.json)

ExFigCore — общий модуль, от которого зависят все остальные.

### API Design

```swift
public enum JSONCodec {
    // Factory
    static func makeEncoder() -> YYJSONEncoder
    static func makeDecoder() -> YYJSONDecoder

    // Convenience
    static func encode(_ value: some Encodable) throws -> Data
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T

    // Sorted keys (для хэширования)
    static func encodeSorted(_ value: some Encodable) throws -> Data
}
```

## Risks

| Risk                   | Mitigation                           |
| ---------------------- | ------------------------------------ |
| Linux совместимость    | swift-yyjson поддерживает Linux      |
| Breaking changes в API | Используем адаптер, не прямые вызовы |

## Success Criteria

- [ ] Все тесты проходят
- [ ] Batch export работает корректно
- [ ] Кэш совместим (те же хэши для тех же данных)
