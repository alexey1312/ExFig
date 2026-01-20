---
name: prefer-mgrep
enabled: true
event: all
conditions:
  - field: tool_name
    operator: regex_match
    pattern: ^(Glob|Grep)$
---

**Use mgrep instead of Glob/Grep for code search.**

mgrep replaces the Glob → Grep → Read chain with a single semantic search:

```bash
./bin/mise exec -- mgrep "your query with domain terms" Sources
```

**Query tips:**
- Include domain terms: colors, icons, iOS, Android, config, export
- Describe what you're looking for: struct, handler, flow, processing

**Fall back to Glob/Grep only for:**
- Exact string matches (`class FigmaClient`)
- File listing in specific directory (`*.swift` in one folder)

If this IS an exact match search, proceed. Otherwise, use mgrep first.
