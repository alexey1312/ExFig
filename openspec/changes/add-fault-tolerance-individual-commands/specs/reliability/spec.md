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
- **THEN** the command stops on first error without retrying

#### Scenario: Default behavior without flags

- **WHEN** running individual commands without fault tolerance flags
- **THEN** the command uses default values (4 retries, 10 req/min)
- **AND** behaves consistently with batch command defaults
