#!/usr/bin/env bash
# Test helper functions for integration tests

# Color output for test results
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test environment setup
setup_test_env() {
    # Create temp directory for test files
    export TEST_TEMP_DIR="$(mktemp -d)"

    # Set up mock API key if not in environment
    if [[ -z "$ELEVENLABS_API_KEY" ]]; then
        export ELEVENLABS_API_KEY="test-api-key-mock"
    fi

    # Export default voice settings
    export ELEVENLABS_VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
    export ELEVENLABS_MODEL="${ELEVENLABS_MODEL:-eleven_flash_v2_5}"
}

# Cleanup test environment
teardown_test_env() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if running on CI (skip audio playback tests)
is_ci() {
    [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]
}

# Skip test if condition not met
skip_if() {
    local condition="$1"
    local reason="$2"

    if eval "$condition"; then
        skip "$reason"
    fi
}

# Create mock audio file
create_mock_audio() {
    local file="$1"
    # Create a minimal valid MP3 header
    printf '\xff\xfb\x90\x00' > "$file"
    echo "Mock MP3 audio data" >> "$file"
}

# Validate MP3 file structure
is_valid_mp3() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    [[ -s "$file" ]] || return 1
    # Check for MP3 header (0xFFE or 0xFFF at start)
    local header=$(xxd -p -l 2 "$file" 2>/dev/null)
    [[ "$header" =~ ^ff(f|e) ]]
}

# Mock curl for API tests (without actual API calls)
mock_curl_success() {
    local output_file="$1"
    create_mock_audio "$output_file"
    return 0
}

# Check if 1Password CLI is available and authenticated
op_available() {
    command_exists op && op account list &>/dev/null
}

# Source shell functions safely
source_shell_functions() {
    local func_file="$1"
    if [[ -f "$func_file" ]]; then
        source "$func_file"
        return 0
    else
        return 1
    fi
}

# Wait for process with timeout
wait_for_process() {
    local pid="$1"
    local timeout="${2:-10}"
    local elapsed=0

    while kill -0 "$pid" 2>/dev/null; do
        sleep 0.1
        elapsed=$((elapsed + 1))
        if [[ $elapsed -gt $((timeout * 10)) ]]; then
            kill -9 "$pid" 2>/dev/null
            return 1
        fi
    done
    return 0
}

# Check if MCP server is runnable
mcp_server_exists() {
    local server_path="/Users/joe/Projects/claude-code-voice/packages/mcp-server/dist/index.js"
    [[ -f "$server_path" ]]
}

# Start MCP server in background
start_mcp_server() {
    local server_path="/Users/joe/Projects/claude-code-voice/packages/mcp-server/dist/index.js"

    if [[ ! -f "$server_path" ]]; then
        return 1
    fi

    # Set API key for server
    export ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-test-key}"

    # Start server and capture PID
    node "$server_path" &
    echo $!
}

# Stop MCP server
stop_mcp_server() {
    local pid="$1"
    if [[ -n "$pid" ]]; then
        kill -TERM "$pid" 2>/dev/null
        wait_for_process "$pid" 5
    fi
}

# Test JSON output parsing
validate_json() {
    local json="$1"
    echo "$json" | jq empty 2>/dev/null
}

# Compare file sizes (for audio file validation)
file_size_in_range() {
    local file="$1"
    local min_size="${2:-100}"  # Minimum 100 bytes
    local max_size="${3:-10485760}"  # Maximum 10MB

    [[ -f "$file" ]] || return 1

    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    [[ $size -ge $min_size && $size -le $max_size ]]
}

# Check audio player availability
audio_player_available() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        command_exists afplay
    else
        command_exists mpv || command_exists ffplay || command_exists aplay
    fi
}

# Generate random test string
random_string() {
    local length="${1:-20}"
    LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Print test section header
test_header() {
    echo ""
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
}
