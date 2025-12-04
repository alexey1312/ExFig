## ADDED Requirements

### Requirement: Fault Tolerance CLI Options for Individual Commands

Individual export commands SHALL support fault tolerance configuration via CLI flags.

#### Scenario: Rate limit option on colors command

- **WHEN** running `exfig colors --rate-limit 20`
- **THEN** the command uses 20 requests per minute limit
- **AND** uses `RateLimitedClient` for API calls

#### Scenario: Max retries option on icons command

- **WHEN** running `exfig icons --max-retries 6`
- **THEN** the command retries failed requests up to 6 times
- **AND** uses exponential backoff between attempts

#### Scenario: Fail-fast option on images command

- **WHEN** running `exfig images --fail-fast`
- **THEN** the command stops on first download error without retrying

#### Scenario: Resume option on fetch command

- **WHEN** running `exfig fetch --resume` after a previous interrupted export
- **THEN** the command loads checkpoint from `.exfig-checkpoint.json`
- **AND** skips already downloaded files
- **AND** continues from where it left off

#### Scenario: Default behavior without flags

- **WHEN** running individual commands without fault tolerance flags
- **THEN** the command uses default values (4 retries, 10 req/min)
- **AND** behaves consistently with batch command defaults

### Requirement: Checkpoint Support for Heavy Commands

Commands that download multiple files (`icons`, `images`, `fetch`) SHALL support checkpoint/resume.

#### Scenario: Checkpoint created during icons export

- **GIVEN** running `exfig icons` with 100 icons to download
- **WHEN** 50 icons have been downloaded
- **AND** the process is interrupted (Ctrl+C, network error, etc.)
- **THEN** a checkpoint file is saved with completed downloads
- **AND** running `exfig icons --resume` continues from icon 51

#### Scenario: Checkpoint cleared on successful completion

- **GIVEN** running `exfig images` with --resume flag
- **WHEN** all images are successfully downloaded
- **THEN** the checkpoint file is deleted
- **AND** a success message is displayed

#### Scenario: Checkpoint not created for light commands

- **WHEN** running `exfig colors` or `exfig typography`
- **THEN** no checkpoint file is created
- **AND** --resume flag is not available for these commands
