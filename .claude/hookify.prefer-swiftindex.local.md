---
name: prefer-swiftindex
enabled: true
event: all
conditions:
  - field: tool_name
    operator: regex_match
    pattern: ^(Glob|Grep)$
---

**Check: Is SwiftIndex MCP available?**

If `mcp__swiftindex__*` tools exist and `.swiftindex/` directory is present:
- `search_code` — semantic code search (semantic_weight=0.7) or exact symbols (semantic_weight=0.0)
- `search_docs` — documentation search
- `code_research` — architecture exploration

If SwiftIndex unavailable — use Grep/Glob.

**Fall back to Grep/Glob only for:**
- Exact regex patterns (`class FigmaClient`)
- Non-Swift files (configs, logs, shell scripts)
- Files outside indexed paths
