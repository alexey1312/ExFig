# Palette's Journal

## 2025-01-28 - Initial Setup

**Learning:** This is a Swift CLI tool, so UX improvements will focus on terminal output, prompts, and feedback.
**Action:** Focus on text formatting, colors, progress indicators, and error messages.

# Palette's Journal - Critical Learnings

## 2025-12-29 - [CLI UI Constraints]

**Learning:** Visual verification of CLI output requires reliable build environments; when builds are fragile, rely on existing libraries like `Rainbow` for styling but double-check their availability in the target module.
**Action:** Always verify dependencies in `Package.swift` before adding imports, especially in environments where running the build is difficult.
