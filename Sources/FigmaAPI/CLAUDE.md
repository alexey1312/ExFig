# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

FigmaAPI is the Figma REST API client layer. It handles HTTP communication, JSON decoding, rate limiting, and retry logic. The module has a single dependency on ExFigCore (for `JSONCodec` used in response decoding).

**Key constraint:** ExFigCore does NOT import FigmaAPI (see root CLAUDE.md "Module Boundaries").

## Architecture

### Client Chain (decorator pattern)

```
FigmaClient (auth + base URL)
  └─ wrapped by RateLimitedClient (retry + rate limiting)
       └─ uses SharedRateLimiter (token bucket + fair round-robin)
```

- `Client` — protocol with single method: `request<T: Endpoint>(_ endpoint: T) async throws -> T.Content`
- `BaseClient` — URLSession-based implementation, extracts `Retry-After` header on HTTP errors, throws `HTTPError`
- `FigmaClient` — subclass of `BaseClient`, sets `X-Figma-Token` header and base URL `https://api.figma.com/v1/`
- `GitHubClient` — subclass of `BaseClient` for GitHub API (used for version check only)
- `RateLimitedClient` — wraps any `Client`, adds exponential backoff retry via `RetryPolicy` and token-bucket rate limiting via `SharedRateLimiter`

### Endpoint Pattern

All endpoints conform to `Endpoint` protocol (two methods: `makeRequest(baseURL:)` and `content(from:with:)`).

Concrete endpoints use `BaseEndpoint` refinement which:

1. Adds `Root` associated type for response wrappers (e.g., `ComponentsResponse` wraps `[Component]`)
2. Decodes JSON via `JSONCodec.decode` (from ExFigCore, uses swift-yyjson)
3. Falls back to decoding `FigmaClientError` on decode failure (extracts Figma's error message)

To add a new endpoint:

1. Create struct conforming to `BaseEndpoint` in `Endpoint/`
2. Set `Content` typealias to your desired return type
3. If API response wraps content, add `Root` typealias and implement `content(from root:) -> Content`
4. Implement `makeRequest(baseURL:)` — build URL path and query items

### CodingKeys Convention

Figma API uses `snake_case`. Models use explicit `CodingKeys` enums for mapping (not `keyDecodingStrategy`), because `JSONCodec` (yyjson) does not support `keyDecodingStrategy`.

Exception: `ContainingFrame` uses default Codable (camelCase property names match JSON keys `nodeId`, `pageName` — Figma returns camelCase for this specific type).

### Error Handling

```
HTTPError (raw status + retryAfter + body)
  └─ converted to FigmaAPIError (user-friendly messages + recovery suggestions)
FigmaClientError (Figma's own error JSON: {"status": 404, "err": "Not found"})
```

`RateLimitedClient.convertToFigmaAPIError()` maps `HTTPError` and `URLError` into `FigmaAPIError`. The `FigmaAPIError.errorDescription` provides human-readable messages for common status codes (401, 403, 404, 429, 5xx) and network errors.

### Rate Limiting

`SharedRateLimiter` is an actor implementing token-bucket with fair round-robin across configs:

- Default: 10 req/min (conservative Tier 1 for Starter plans)
- Burst capacity: 3 tokens
- On 429: global pause for all configs using `Retry-After` (or 60s default)
- `ConfigID` tracks per-config request counts for fair scheduling in batch mode

### Retry Policy

`RetryPolicy` — exponential backoff with jitter:

- Defaults: 4 retries, 3s base delay, 30s max delay, 0.2 jitter
- Retryable HTTP codes: 429, 500, 502, 503, 504
- Retryable URL errors: timeout, connection lost, DNS failure, etc.
- For 429: prefers `Retry-After` header over calculated delay

## Endpoints Summary

| Endpoint                  | Figma API Path                  | Content Type              | Notes                     |
| ------------------------- | ------------------------------- | ------------------------- | ------------------------- |
| `ComponentsEndpoint`      | `GET files/:id/components`      | `[Component]`             | Unwraps `meta.components` |
| `NodesEndpoint`           | `GET files/:id/nodes?ids=`      | `[NodeId: Node]`          | Batch node fetch          |
| `ImageEndpoint`           | `GET images/:id?ids=&format=`   | `[NodeId: ImagePath?]`    | SVG/PNG/PDF export URLs   |
| `StylesEndpoint`          | `GET files/:id/styles`          | `[Style]`                 | Unwraps `meta.styles`     |
| `VariablesEndpoint`       | `GET files/:id/variables/local` | `VariablesMeta`           | Collections + values      |
| `UpdateVariablesEndpoint` | `POST files/:id/variables`      | `UpdateVariablesResponse` | codeSyntax updates        |
| `FileMetadataEndpoint`    | `GET files/:id?depth=1`         | `FileMetadata`            | Lightweight version check |
| `LatestReleaseEndpoint`   | `GET repos/.../releases/latest` | `LatestReleaseResponse`   | GitHub, not Figma         |

## Model Layer

### Node tree (`Node.swift`)

`NodesResponse` → `Node` → `Document` (recursive via `children`). `Document` contains fills, strokes, effects, opacity, style (typography), blend mode. All Figma enum values use `SCREAMING_CASE` raw values.

### Change detection (`NodeHashableProperties.swift`, `FloatNormalization.swift`)

`Document.toHashableProperties()` creates stable hashable snapshots:

- Float normalization to 6 decimal places (`Double.normalized`) to handle Figma API precision drift
- Children sorted by name for order-independent hashing

### Variables (`Variables.swift`, `VariableUpdate.swift`)

`ValuesByMode` is a tagged union decoded via try-chain: `VariableAlias` → `PaintColor` → `String` → `Double` → `Bool`.

## Testing

Tests use `MockClient` (thread-safe via DispatchQueue) and JSON fixtures in `Tests/FigmaAPITests/Fixtures/`.

```bash
./bin/mise run test:filter FigmaAPITests
```

`MockClient` allows setting responses/errors per endpoint type, tracking request logs, and verifying parallel execution timing via `requestsStartedWithin(seconds:)`.

`FixtureLoader` loads JSON from `Bundle.module` — use `JSONDecoder()` (not `JSONCodec`) in fixture loader since fixtures may use default key strategies.
