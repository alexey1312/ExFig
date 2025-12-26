#!/bin/bash
# =============================================================================
# Code Coverage Script for ExFig
# =============================================================================
# Usage:
#   ./Scripts/coverage.sh [options]
#
# Options:
#   --run-tests     Run tests before generating coverage (default if no profdata)
#   --html          Generate HTML report and open in browser
#   --json          Output coverage as JSON (for CI badges)
#   --quiet         Only output the coverage percentage
#   --update-badge  Update coverage badge in README.md
#   --help          Show this help message
#
# Examples:
#   ./Scripts/coverage.sh                    # Show coverage report
#   ./Scripts/coverage.sh --html             # Generate HTML report
#   ./Scripts/coverage.sh --json             # Output JSON for badges
#   ./Scripts/coverage.sh --quiet            # Just the percentage
#   ./Scripts/coverage.sh --run-tests --update-badge  # Run tests and update badge
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Default options
RUN_TESTS=false
HTML_REPORT=false
JSON_OUTPUT=false
QUIET=false
UPDATE_BADGE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --run-tests)
            RUN_TESTS=true
            shift
            ;;
        --html)
            HTML_REPORT=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --update-badge)
            UPDATE_BADGE=true
            shift
            ;;
        --help|-h)
            sed -n '2,21p' "$0" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
PROFDATA_DIR=".build/debug/codecov"
PROFDATA_FILE="$PROFDATA_DIR/default.profdata"
HTML_OUTPUT_DIR=".build/coverage-html"

# Check if we need to run tests
if [[ ! -d "$PROFDATA_DIR" ]] || [[ -z "$(ls -A $PROFDATA_DIR/*.profraw 2>/dev/null)" ]]; then
    RUN_TESTS=true
fi

# Run tests if needed
if [[ "$RUN_TESTS" == "true" ]]; then
    if [[ "$QUIET" != "true" ]]; then
        echo "Running tests with coverage..."
    fi
    # Clean old profraw files to avoid mixing data from different runs
    rm -f "$PROFDATA_DIR"/*.profraw "$PROFDATA_DIR"/*.profdata 2>/dev/null || true
    # Run tests, ignore exit code (some test frameworks return non-zero even on success)
    swift test --enable-code-coverage > /dev/null 2>&1 || true

    # Verify tests produced coverage data
    if [[ -z "$(ls -A $PROFDATA_DIR/*.profraw 2>/dev/null)" ]]; then
        echo "Error: Tests failed to produce coverage data" >&2
        exit 1
    fi
fi

# Merge profdata
if [[ "$QUIET" != "true" ]] && [[ "$JSON_OUTPUT" != "true" ]]; then
    echo "Generating coverage report..."
fi

xcrun llvm-profdata merge -sparse "$PROFDATA_DIR"/*.profraw -o "$PROFDATA_FILE" 2>/dev/null

# Find test binary for native architecture
ARCH=$(uname -m)
TEST_BUNDLE=$(find .build -path "*/${ARCH}-apple-macosx/*" -name "*.xctest" -type d 2>/dev/null | head -1)
if [[ -z "$TEST_BUNDLE" ]]; then
    # Fallback: try any .xctest bundle
    TEST_BUNDLE=$(find .build -name "*.xctest" -type d 2>/dev/null | head -1)
fi
if [[ -z "$TEST_BUNDLE" ]]; then
    echo "Error: No .xctest bundle found. Run tests first." >&2
    exit 1
fi

TEST_BINARY_NAME=$(basename "$TEST_BUNDLE" .xctest)
TEST_BINARY="$TEST_BUNDLE/Contents/MacOS/$TEST_BINARY_NAME"

if [[ ! -f "$TEST_BINARY" ]]; then
    echo "Error: Test binary not found at $TEST_BINARY" >&2
    exit 1
fi

# Generate HTML report if requested
if [[ "$HTML_REPORT" == "true" ]]; then
    xcrun llvm-cov show "$TEST_BINARY" \
        -instr-profile="$PROFDATA_FILE" \
        --ignore-filename-regex='.build|Tests' \
        --format=html \
        --output-dir="$HTML_OUTPUT_DIR"

    echo "HTML report generated: $HTML_OUTPUT_DIR/index.html"

    # Open in browser (macOS only)
    if command -v open &> /dev/null; then
        open "$HTML_OUTPUT_DIR/index.html"
    fi
    exit 0
fi

# Get coverage report
REPORT=$(xcrun llvm-cov report "$TEST_BINARY" \
    -instr-profile="$PROFDATA_FILE" \
    --ignore-filename-regex='.build|Tests')

# Extract total coverage percentage
COVERAGE=$(echo "$REPORT" | tail -1 | awk '{print $10}' | tr -d '%')

# JSON output for CI
if [[ "$JSON_OUTPUT" == "true" ]]; then
    # Determine color based on coverage
    if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
        COLOR="brightgreen"
    elif (( $(echo "$COVERAGE >= 60" | bc -l) )); then
        COLOR="green"
    elif (( $(echo "$COVERAGE >= 40" | bc -l) )); then
        COLOR="yellow"
    else
        COLOR="red"
    fi

    echo "{\"schemaVersion\":1,\"label\":\"coverage\",\"message\":\"${COVERAGE}%\",\"color\":\"${COLOR}\"}"
    exit 0
fi

# Quiet output - just the percentage
if [[ "$QUIET" == "true" ]]; then
    echo "$COVERAGE"
    exit 0
fi

# Full report with colored summary
echo "$REPORT"
echo ""

# Colored summary
if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
    COLOR_CODE=$BRIGHT_GREEN
elif (( $(echo "$COVERAGE >= 60" | bc -l) )); then
    COLOR_CODE=$GREEN
elif (( $(echo "$COVERAGE >= 40" | bc -l) )); then
    COLOR_CODE=$YELLOW
else
    COLOR_CODE=$RED
fi

# Update badge in README.md if requested
if [[ "$UPDATE_BADGE" == "true" ]]; then
    # Determine badge color
    if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
        BADGE_COLOR="brightgreen"
    elif (( $(echo "$COVERAGE >= 60" | bc -l) )); then
        BADGE_COLOR="green"
    elif (( $(echo "$COVERAGE >= 40" | bc -l) )); then
        BADGE_COLOR="yellow"
    else
        BADGE_COLOR="red"
    fi

    perl -i -pe "s|coverage-[0-9.]+%25-[a-z]+|coverage-${COVERAGE}%25-${BADGE_COLOR}|g" README.md
    echo -e "Updated README.md badge: ${COLOR_CODE}${COVERAGE}%${NC} (${BADGE_COLOR})"
else
    echo -e "Total coverage: ${COLOR_CODE}${COVERAGE}%${NC}"
fi
