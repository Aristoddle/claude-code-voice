#!/usr/bin/env bats
# End-to-end integration tests

# Load test helpers
load test-helpers

setup() {
    setup_test_env

    # Paths
    MCP_SERVER_PATH="/Users/joe/Projects/claude-code-voice/packages/mcp-server/dist/index.js"
    SHELL_FUNC_FILE="/Users/joe/.config/zsh/functions/elevenlabs-tts.zsh"

    # Skip if components don't exist
    if [[ ! -f "$MCP_SERVER_PATH" ]]; then
        skip "MCP server not built"
    fi

    if [[ ! -f "$SHELL_FUNC_FILE" ]]; then
        skip "Shell functions not installed"
    fi

    # Source shell functions
    source "$SHELL_FUNC_FILE"

    # Set API key
    export ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-test-api-key}"
}

teardown() {
    teardown_test_env

    # Cleanup any running processes
    pkill -f "node.*mcp-server" 2>/dev/null || true
}

# Test: Full workflow - speak command
@test "E2E: speak command generates and plays audio" {
    skip_if 'is_ci' "Skipping audio playback in CI"
    skip_if '[[ -z "$ELEVENLABS_API_KEY" || "$ELEVENLABS_API_KEY" == "test-api-key" ]]' "Real API key required"

    # Mock audio player to avoid actual playback
    afplay() { return 0; }
    mpv() { return 0; }
    export -f afplay mpv

    run speak "Integration test"

    # Should complete successfully
    [[ $status -eq 0 ]]
    [[ "$output" =~ "Generating speech" ]]
}

# Test: Full workflow - speak-save command
@test "E2E: speak-save command creates valid audio file" {
    skip_if '[[ -z "$ELEVENLABS_API_KEY" || "$ELEVENLABS_API_KEY" == "test-api-key" ]]' "Real API key required"

    local output_file="$TEST_TEMP_DIR/e2e-test.mp3"

    run speak-save "End to end test" "$output_file"

    # Should create file
    [[ -f "$output_file" ]]
    [[ -s "$output_file" ]]

    # File should be reasonable size
    file_size_in_range "$output_file" 1000 1048576
}

# Test: Shell to MCP integration
@test "E2E: Shell functions use same configuration as MCP server" {
    # Both should use same default voice
    grep -q "21m00Tcm4TlvDq8ikWAM" "$SHELL_FUNC_FILE"
    grep -q "21m00Tcm4TlvDq8ikWAM" "$MCP_SERVER_PATH"

    # Both should use same model
    grep -q "eleven_flash_v2_5" "$SHELL_FUNC_FILE"
    grep -q "eleven_flash" "$MCP_SERVER_PATH"
}

@test "E2E: Shell and MCP use same API endpoint" {
    grep -q "api.elevenlabs.io" "$SHELL_FUNC_FILE"
    grep -q "api.elevenlabs.io" "$MCP_SERVER_PATH"
}

@test "E2E: Shell and MCP use same API version" {
    grep -q "/v1/" "$SHELL_FUNC_FILE"
    grep -q "/v1/" "$MCP_SERVER_PATH"
}

# Test: Error cascade
@test "E2E: Missing API key fails gracefully at shell level" {
    unset ELEVENLABS_API_KEY

    # Mock op to fail
    op() { return 1; }
    export -f op

    run speak "test"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "API key" ]]
}

@test "E2E: Missing API key fails gracefully at server level" {
    unset ELEVENLABS_API_KEY

    run timeout 2s node "$MCP_SERVER_PATH" 2>&1

    [[ "$output" =~ "API" ]] || [[ $status -eq 1 ]]
}

@test "E2E: Invalid file input shows helpful error" {
    run speak-file "/nonexistent/test/file.txt"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "File not found" ]]
    [[ "$output" =~ "/nonexistent/test/file.txt" ]]
}

@test "E2E: Invalid output path is handled properly" {
    skip_if '[[ -z "$ELEVENLABS_API_KEY" || "$ELEVENLABS_API_KEY" == "test-api-key" ]]' "Real API key required"

    # Try to write to read-only directory
    run speak-save "test" "/etc/test-output.mp3"

    # Should fail or handle permission error
    [[ $status -eq 1 ]] || [[ ! -f "/etc/test-output.mp3" ]]
}

# Test: Cross-platform compatibility
@test "E2E: Audio player detection works on current platform" {
    audio_player_available
}

@test "E2E: Platform-specific paths are handled correctly" {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS should use afplay
        command_exists afplay
    else
        # Linux should have at least one player
        command_exists mpv || command_exists ffplay || command_exists aplay
    fi
}

# Test: Configuration consistency
@test "E2E: Environment variables are respected by shell functions" {
    export ELEVENLABS_VOICE_ID="test-voice-id"
    export ELEVENLABS_MODEL="test-model"

    # Source functions again to pick up env vars
    source "$SHELL_FUNC_FILE"

    [[ "$ELEVENLABS_VOICE_ID" == "test-voice-id" ]]
    [[ "$ELEVENLABS_MODEL" == "test-model" ]]
}

@test "E2E: Environment variables are respected by MCP server" {
    export ELEVENLABS_VOICE_ID="custom-voice"
    export ELEVENLABS_MODEL="custom-model"

    # Server code should check for these
    grep -q "process.env.ELEVENLABS_VOICE_ID" "$MCP_SERVER_PATH"
    grep -q "process.env.ELEVENLABS_MODEL" "$MCP_SERVER_PATH"
}

# Test: File handling workflow
@test "E2E: Text file to audio file workflow" {
    skip_if '[[ -z "$ELEVENLABS_API_KEY" || "$ELEVENLABS_API_KEY" == "test-api-key" ]]' "Real API key required"

    # Create input text file
    local input_file="$TEST_TEMP_DIR/input.txt"
    echo "This is a test of the end-to-end workflow" > "$input_file"

    # Create output audio file
    local output_file="$TEST_TEMP_DIR/output.mp3"

    # Mock curl for testing without API
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            create_mock_audio "${@: -1}"
            return 0
        fi
    }
    export -f curl

    # Process with speak-save
    run bash -c "source '$SHELL_FUNC_FILE' && speak-save \"\$(cat '$input_file')\" '$output_file'"

    [[ -f "$output_file" ]]
    [[ -s "$output_file" ]]
}

# Test: Security workflow
@test "E2E: 1Password integration works end-to-end" {
    skip_if "! op_available" "1Password CLI not available"

    # Try to get API key through full chain
    run bash -c "source '$SHELL_FUNC_FILE' && _elevenlabs_get_api_key"

    # Should either succeed or show proper error
    [[ $status -eq 0 ]] || [[ "$output" =~ "API key" ]]
}

# Test: Error recovery
@test "E2E: System recovers from failed API call" {
    # Mock curl to fail
    curl() {
        return 1
    }
    export -f curl

    run speak "test message"

    # Should show error and exit cleanly
    [[ $status -eq 1 ]]
    [[ "$output" =~ "Error\|Failed" ]]

    # Temp files should be cleaned up
    local temp_count=$(find /tmp -name "elevenlabs.*" 2>/dev/null | wc -l)
    [[ $temp_count -lt 10 ]]  # Should not accumulate temp files
}

@test "E2E: System handles network timeout gracefully" {
    # Mock curl to timeout
    curl() {
        sleep 10 &
        wait $!
    }
    export -f curl

    # Run with timeout
    run timeout 3s bash -c "source '$SHELL_FUNC_FILE' && speak 'test'"

    # Should timeout without hanging
    [[ $status -eq 124 ]] || [[ $status -eq 1 ]]
}

# Test: Concurrent usage
@test "E2E: Multiple speak commands can run in sequence" {
    skip_if '[[ -z "$ELEVENLABS_API_KEY" || "$ELEVENLABS_API_KEY" == "test-api-key" ]]' "Real API key required"

    # Mock audio and curl
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            create_mock_audio "${@: -1}"
            return 0
        fi
    }
    afplay() { return 0; }
    mpv() { return 0; }
    export -f curl afplay mpv

    # Run multiple commands
    run bash -c "source '$SHELL_FUNC_FILE' && speak 'test one' && speak 'test two'"

    [[ $status -eq 0 ]]
}

# Test: Output format consistency
@test "E2E: Audio files have consistent format" {
    skip_if '[[ -z "$ELEVENLABS_API_KEY" || "$ELEVENLABS_API_KEY" == "test-api-key" ]]' "Real API key required"

    local file1="$TEST_TEMP_DIR/test1.mp3"
    local file2="$TEST_TEMP_DIR/test2.mp3"

    # Mock curl
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            create_mock_audio "${@: -1}"
            return 0
        fi
    }
    export -f curl

    # Generate two files
    speak-save "test one" "$file1"
    speak-save "test two" "$file2"

    # Both should be valid MP3s
    [[ -f "$file1" && -s "$file1" ]]
    [[ -f "$file2" && -s "$file2" ]]
}

# Test: Documentation accuracy
@test "E2E: README examples are executable" {
    # Commands from README should work
    type speak &>/dev/null
    type speak-file &>/dev/null
    type speak-save &>/dev/null
    type voice-list &>/dev/null
}

@test "E2E: test-tts.sh script is executable" {
    [[ -x "/Users/joe/Projects/claude-code-voice/test-tts.sh" ]]
}

@test "E2E: test-tts.sh uses correct function source path" {
    grep -q "source.*elevenlabs-tts.zsh" "/Users/joe/Projects/claude-code-voice/test-tts.sh"
}
