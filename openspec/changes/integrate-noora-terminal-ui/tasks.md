# Tasks: Integrate Noora Terminal UI

## Phase 1: Semantic Text Formatting (P0)

- [x] **1.1** Extend `NooraUI` adapter with convenience methods for common patterns
  - Add `formatSuccess(icon:message:)`, `formatError(icon:message:)`, etc.
  - Map to `.success()`, `.danger()`, `.muted()` components

- [x] **1.2** Migrate `TerminalUI.info()` to use `NooraUI.format()`
  - Replace `message.cyan` with `TerminalText` `.primary()` component
  - Preserve batch mode suppression logic

- [x] **1.3** Migrate `TerminalUI.success()` to use `NooraUI.format()`
  - Replace `"✓".green` with `.success("✓")`
  - Preserve batch mode suppression logic

- [x] **1.4** Migrate `TerminalUI.warning()` to use `NooraUI.format()`
  - Replace `"⚠".yellow` with `.accent("⚠")` or custom warning component
  - Preserve multi-line formatting logic

- [x] **1.5** Migrate `TerminalUI.error()` to use `NooraUI.format()`
  - Replace `"✗".red` with `.danger("✗")`
  - Preserve multi-line formatting logic

- [x] **1.6** Migrate `TerminalUI.debug()` to use `NooraUI.format()`
  - Replace `"[DEBUG]".lightBlack` with `.muted("[DEBUG]")`

- [x] **1.7** Update `ExFigWarningFormatter` to return `TerminalText`
  - Convert string-based formatting to semantic components
  - Add `formatAsTerminalText()` method alongside existing `format()`

- [x] **1.8** Update `ExFigErrorFormatter` to return `TerminalText`
  - Use `.danger()` for error messages
  - Use `.muted()` for recovery suggestions

- [x] **1.9** Update tests for formatters
  - Verify output matches expected semantic structure
  - Add tests for `NooraUI.format()` output

## Phase 2: Progress Components (P1)

- [x] **2.1** Add `NooraUI.progressBarStep()` wrapper
  - Added `NooraUI.progressBarStep()` and `NooraUI.progressStep()` wrappers
  - Note: These bypass `TerminalOutputManager`, use only for standalone operations

- [x] **2.2** Evaluate replacing simple `withSpinner` with `progressBarStep`
  - **Decision: Keep both, no migration**
  - Custom `Spinner` is deeply integrated with `TerminalOutputManager` and batch mode
  - 80+ call sites depend on batch mode suppression and output coordination
  - Noora wrappers available for new isolated use cases only

- [x] **2.3** Document when to use Noora vs custom components
  - Updated `.claude/rules/terminal-ui.md` with decision matrix
  - Added Noora progress wrappers documentation

## Validation

- [x] **V1** Run full test suite: `./bin/mise run test`
- [ ] **V2** Manual testing: verify colors in TTY terminal
- [ ] **V3** Manual testing: verify plain output in non-TTY (CI)
- [ ] **V4** Build on Linux: verify no Noora-specific issues

## Documentation

- [x] **D1** Update CLAUDE.md dependencies table (done)
- [x] **D2** Update `.claude/rules/terminal-ui.md` with Noora patterns (done)
- [x] **D3** Add migration guide for future formatters
  - Added "Migration Guide: Rainbow to Noora" section to terminal-ui.md
