#!/usr/bin/env bash
# Integration test runner for claude-code-voice
# Usage: ./tests/run-integration-tests.sh [test-file]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests/integration"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_prerequisites() {
    local missing=0

    # Check for bats
    if ! command -v bats &>/dev/null; then
        print_error "BATS not found. Install: brew install bats-core"
        missing=1
    fi

    # Check for Node.js
    if ! command -v node &>/dev/null; then
        print_error "Node.js not found. Install: brew install node"
        missing=1
    fi

    # Check Node.js version
    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ $node_version -lt 18 ]]; then
        print_error "Node.js 18+ required (found: v$node_version)"
        missing=1
    fi

    # Check for shell functions
    if [[ ! -f "$HOME/.config/zsh/functions/elevenlabs-tts.zsh" ]]; then
        print_warning "Shell functions not installed at ~/.config/zsh/functions/elevenlabs-tts.zsh"
        print_info "Some tests will be skipped"
    fi

    # Check for MCP server
    if [[ ! -f "$PROJECT_ROOT/packages/mcp-server/dist/index.js" ]]; then
        print_warning "MCP server not built"
        print_info "Run: cd packages/mcp-server && npm run build"
        print_info "Some tests will be skipped"
    fi

    # Check for API key
    if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
        print_warning "ELEVENLABS_API_KEY not set"
        print_info "API-dependent tests will be skipped"
        print_info "Set with: export ELEVENLABS_API_KEY=your-key"
    fi

    if [[ $missing -eq 1 ]]; then
        return 1
    fi
    return 0
}

run_test_file() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .bats)

    echo
    print_header "Running: $test_name"

    # Run bats with tap output and capture results
    local output
    local exit_code

    if output=$(bats --tap "$test_file" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi

    # Parse TAP output for statistics
    local tests=$(echo "$output" | grep -c "^ok\|^not ok" || echo "0")
    local passed=$(echo "$output" | grep -c "^ok" || echo "0")
    local failed=$(echo "$output" | grep -c "^not ok" || echo "0")
    local skipped=$(echo "$output" | grep -c "# skip" || echo "0")

    # Update totals
    TOTAL_TESTS=$((TOTAL_TESTS + tests))
    PASSED_TESTS=$((PASSED_TESTS + passed))
    FAILED_TESTS=$((FAILED_TESTS + failed))
    SKIPPED_TESTS=$((SKIPPED_TESTS + skipped))

    # Show results
    echo
    echo "Results for $test_name:"
    echo "  Total:   $tests"
    echo "  Passed:  $passed"
    echo "  Failed:  $failed"
    echo "  Skipped: $skipped"

    # Show detailed output if failures
    if [[ $failed -gt 0 || $exit_code -ne 0 ]]; then
        echo
        print_error "Test failures detected. Full output:"
        echo "$output"
    fi

    return $exit_code
}

print_summary() {
    echo
    echo
    print_header "Test Summary"

    echo "Total tests:   $TOTAL_TESTS"
    echo "Passed:        $PASSED_TESTS"
    echo "Failed:        $FAILED_TESTS"
    echo "Skipped:       $SKIPPED_TESTS"
    echo

    if [[ $FAILED_TESTS -eq 0 ]]; then
        print_success "All tests passed!"
        return 0
    else
        print_error "$FAILED_TESTS test(s) failed"
        return 1
    fi
}

show_usage() {
    cat <<EOF
Integration Test Runner for claude-code-voice

Usage:
  $0 [test-file]

Examples:
  $0                                    # Run all tests
  $0 test-shell-functions.bats         # Run specific test file
  $0 test-mcp-server.bats              # Run MCP server tests
  $0 test-e2e.bats                     # Run end-to-end tests

Environment Variables:
  ELEVENLABS_API_KEY     API key for ElevenLabs (optional, tests will skip if missing)
  CI                     Set to skip interactive tests (audio playback)

Prerequisites:
  - bats-core (brew install bats-core)
  - Node.js 18+ (brew install node)
  - MCP server built (npm run build in packages/mcp-server)
  - Shell functions installed (~/.config/zsh/functions/elevenlabs-tts.zsh)

EOF
}

main() {
    # Show header
    clear
    print_header "Claude Code Voice - Integration Tests"

    # Parse arguments
    if [[ $# -gt 0 ]]; then
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            show_usage
            exit 0
        fi
    fi

    # Check prerequisites
    print_header "Checking Prerequisites"
    if ! check_prerequisites; then
        print_error "Missing prerequisites. Please install required tools."
        exit 1
    fi
    print_success "All prerequisites met"

    # Determine which tests to run
    local test_files=()
    if [[ $# -gt 0 ]]; then
        # Run specific test file
        local test_file="$TEST_DIR/$1"
        if [[ ! -f "$test_file" ]]; then
            test_file="$1"  # Try as absolute path
        fi

        if [[ ! -f "$test_file" ]]; then
            print_error "Test file not found: $1"
            exit 1
        fi

        test_files=("$test_file")
    else
        # Run all test files
        test_files=(
            "$TEST_DIR/test-shell-functions.bats"
            "$TEST_DIR/test-mcp-server.bats"
            "$TEST_DIR/test-e2e.bats"
        )
    fi

    # Run tests
    local overall_exit=0
    for test_file in "${test_files[@]}"; do
        if ! run_test_file "$test_file"; then
            overall_exit=1
        fi
    done

    # Print summary
    if ! print_summary; then
        overall_exit=1
    fi

    exit $overall_exit
}

# Run main
main "$@"
