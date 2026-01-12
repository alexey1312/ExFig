---
paths:
  - "Sources/FigmaAPI/**"
---

# Figma API Reference

This rule covers Figma API endpoints and response mapping.

## Official Documentation

**URL:** https://www.figma.com/developers/api

## When to Consult Figma API Docs

| Scenario                      | What to Look For                        |
| ----------------------------- | --------------------------------------- |
| Adding new endpoint           | Request/response schema, authentication |
| Debugging API errors          | Error codes, rate limits, permissions   |
| Understanding node structure  | GET file nodes, component properties    |
| Working with Variables/Styles | Variables API, Styles API endpoints     |
| Image export options          | GET image endpoint, format/scale params |
| Unexpected response format    | Response schema changes, API versioning |

## Key API Endpoints Used

| Endpoint                        | Purpose                       | File in Project                 |
| ------------------------------- | ----------------------------- | ------------------------------- |
| `GET /v1/files/:key`            | File structure, nodes, styles | `NodesEndpoint.swift`           |
| `GET /v1/images/:key`           | Export images (PNG/SVG/PDF)   | `ImageEndpoint.swift`           |
| `GET /v1/files/:key/components` | Components list               | `ComponentsEndpoint.swift`      |
| `GET /v1/files/:key/styles`     | Styles (colors, text)         | `StylesEndpoint.swift`          |
| `GET /v1/files/:key/variables`  | Figma Variables               | `VariablesEndpoint.swift`       |
| `POST /v1/files/:key/variables` | Update Variables codeSyntax   | `UpdateVariablesEndpoint.swift` |

## API Response Mapping

When Figma API response structure differs from project models, check:

1. `Sources/FigmaAPI/Model/` - current response models
2. Figma API docs - actual response schema
3. Create/update `Decodable` structs to match API response

## Rate Limits

**Official docs:** https://developers.figma.com/docs/rest-api/rate-limits/

| Tier | Endpoints           | Rate (req/min)        |
| ---- | ------------------- | --------------------- |
| 1    | files, images       | 10-20 (plan-dependent)|
| 2    | components, styles  | 25-100                |
| 3    | variables           | 50-150                |

- Use `maxConcurrentBatches = 3` for parallel requests
- On 429 error: respect `Retry-After` header
