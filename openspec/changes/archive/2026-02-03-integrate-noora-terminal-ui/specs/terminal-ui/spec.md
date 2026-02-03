# Terminal UI Spec Delta

## ADDED Requirements

### Requirement: NooraUI adapter SHALL provide semantic text formatting

The CLI SHALL provide a `NooraUI` adapter that wraps Noora library for semantic terminal text formatting with consistent theming.

#### Scenario: Format success message with semantic component

**Given** a message "Operation completed"
**When** formatted using `NooraUI.format("\(.success("✓")) Operation completed")`
**Then** the output contains ANSI green color codes for the checkmark
**And** the message text is uncolored

#### Scenario: Format error message with semantic component

**Given** an error message "Failed to connect"
**When** formatted using `NooraUI.format("\(.danger("✗")) Failed to connect")`
**Then** the output contains ANSI red color codes for the cross icon
**And** the message text is uncolored

#### Scenario: Format command reference in message

**Given** a help message mentioning command "exfig colors"
**When** formatted using `NooraUI.format("Run \(.command("exfig colors")) to export")`
**Then** the command is highlighted distinctly from surrounding text

---

### Requirement: TerminalUI MUST use NooraUI for message formatting

The TerminalUI facade MUST use NooraUI internally for consistent semantic formatting of info, success, warning, error, and debug messages.

#### Scenario: Success message uses Noora semantic formatting

**Given** TerminalUI with colors enabled
**When** `success("Export completed")` is called
**Then** the output uses `.success()` component for the checkmark icon
**And** the message is printed via TerminalOutputManager

#### Scenario: Warning message uses Noora semantic formatting

**Given** TerminalUI with colors enabled
**When** `warning("Config not found")` is called
**Then** the output uses `.accent()` component for the warning icon
**And** multi-line messages are properly indented

#### Scenario: Error message uses Noora semantic formatting

**Given** TerminalUI with colors enabled
**When** `error("Connection failed")` is called
**Then** the output uses `.danger()` component for the error icon
**And** multi-line messages are properly indented

---

### Requirement: Formatters SHALL return semantic TerminalText

Warning and error formatters SHALL provide methods to return `TerminalText` for semantic formatting in addition to plain string output.

#### Scenario: ExFigWarningFormatter returns TerminalText

**Given** an `ExFigWarning.configMissing` warning
**When** `formatAsTerminalText()` is called
**Then** the result is a `TerminalText` with semantic components
**And** the text can be formatted via `NooraUI.format()`

#### Scenario: ExFigErrorFormatter returns TerminalText

**Given** a `LocalizedError` with recovery suggestion
**When** `formatAsTerminalText()` is called
**Then** the error description uses `.danger()` component
**And** the recovery suggestion uses `.muted()` component

## MODIFIED Requirements

### Requirement: Custom animations SHALL remain unchanged

The Spinner, ProgressBar, and BatchProgressView components SHALL continue to use the existing Rainbow-based rendering for animation frames while message formatting migrates to Noora.

#### Scenario: Spinner animation uses Rainbow for frame colors

**Given** a Spinner with colors enabled
**When** the spinner is running
**Then** the Braille animation frames use Rainbow `.cyan` for coloring
**And** the spinner message can use Noora-formatted text

#### Scenario: ProgressBar uses Rainbow for bar rendering

**Given** a ProgressBar with colors enabled
**When** progress is updated
**Then** the filled bar uses Rainbow `.cyan` for coloring
**And** the empty bar uses Rainbow `.lightBlack` for coloring
