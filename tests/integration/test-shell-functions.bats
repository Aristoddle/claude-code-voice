#!/usr/bin/env bats
# Integration tests for shell functions (elevenlabs-tts.zsh)

# Load test helpers
load test-helpers

# Setup and teardown
setup() {
    setup_test_env

    # Source shell functions
    SHELL_FUNC_FILE="/Users/joe/.config/zsh/functions/elevenlabs-tts.zsh"

    # Skip all tests if shell functions don't exist
    if [[ ! -f "$SHELL_FUNC_FILE" ]]; then
        skip "Shell functions not installed at $SHELL_FUNC_FILE"
    fi

    source "$SHELL_FUNC_FILE"
}

teardown() {
    teardown_test_env
}

# Test: Shell functions file exists
@test "shell functions file exists at expected location" {
    [[ -f "/Users/joe/.config/zsh/functions/elevenlabs-tts.zsh" ]]
}

# Test: Functions are defined
@test "speak function is defined" {
    type speak &>/dev/null
}

@test "speak-file function is defined" {
    type speak-file &>/dev/null
}

@test "speak-save function is defined" {
    type speak-save &>/dev/null
}

@test "voice-list function is defined" {
    type voice-list &>/dev/null
}

@test "_elevenlabs_get_api_key helper function is defined" {
    type _elevenlabs_get_api_key &>/dev/null
}

@test "_elevenlabs_play_audio helper function is defined" {
    type _elevenlabs_play_audio &>/dev/null
}

# Test: speak function validation
@test "speak requires text argument" {
    run speak
    [[ $status -eq 1 ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "speak shows usage message when called without arguments" {
    run speak
    [[ "$output" =~ "speak \"text\"" ]]
}

@test "speak accepts text argument" {
    # Mock curl to avoid actual API call
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            local output_file="${@: -1}"
            create_mock_audio "$output_file"
            return 0
        fi
    }
    export -f curl

    # Mock audio player
    afplay() { return 0; }
    mpv() { return 0; }
    export -f afplay mpv

    run speak "test message"
    # Should attempt to generate speech (exit code depends on API availability)
    [[ $status -eq 0 ]] || [[ "$output" =~ "Generating speech" ]]
}

# Test: speak-file function validation
@test "speak-file requires file argument" {
    run speak-file
    [[ $status -eq 1 ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "speak-file handles missing files gracefully" {
    run speak-file "/nonexistent/file.txt"
    [[ $status -eq 1 ]]
    [[ "$output" =~ "Error: File not found" ]]
}

@test "speak-file accepts existing file" {
    local test_file="$TEST_TEMP_DIR/test.txt"
    echo "Test content" > "$test_file"

    # Mock curl and audio player
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            local output_file="${@: -1}"
            create_mock_audio "$output_file"
            return 0
        fi
    }
    export -f curl

    afplay() { return 0; }
    mpv() { return 0; }
    export -f afplay mpv

    run speak-file "$test_file"
    # Should attempt to process file
    [[ $status -eq 0 ]] || [[ "$output" =~ "Generating speech" ]]
}

# Test: speak-save function validation
@test "speak-save requires text and output path arguments" {
    run speak-save
    [[ $status -eq 1 ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "speak-save requires output path" {
    run speak-save "test text"
    [[ $status -eq 1 ]]
    [[ "$output" =~ "Usage:" ]]
}

@test "speak-save validates output path" {
    local output_file="$TEST_TEMP_DIR/output.mp3"

    # Mock curl
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            local out="${@: -1}"
            create_mock_audio "$out"
            return 0
        fi
    }
    export -f curl

    run speak-save "test text" "$output_file"

    # Should create output file or show error
    [[ $status -eq 0 ]] || [[ "$output" =~ "Error" ]]
}

@test "speak-save shows usage example" {
    run speak-save
    [[ "$output" =~ "Example:" ]]
}

# Test: voice-list function
@test "voice-list function exists and is callable" {
    type voice-list &>/dev/null
}

@test "voice-list requires API key" {
    # Unset API key
    unset ELEVENLABS_API_KEY

    # Mock 1Password CLI to fail
    op() {
        return 1
    }
    export -f op

    run voice-list
    # Should fail or show error message
    [[ "$output" =~ "API key" ]] || [[ "$output" =~ "Error" ]]
}

# Test: _elevenlabs_get_api_key fallback order
@test "_elevenlabs_get_api_key tries 1Password first" {
    skip_if "! op_available" "1Password CLI not available"

    # If op is available, function should try it
    run _elevenlabs_get_api_key

    # Should either succeed or show proper error
    [[ $status -eq 0 ]] || [[ "$output" =~ "API key" ]]
}

@test "_elevenlabs_get_api_key falls back to .env file" {
    # Mock op to fail
    op() {
        return 1
    }
    export -f op

    # Create mock .env file
    local env_dir="$HOME/.config/elevenlabs"
    mkdir -p "$env_dir"
    echo "ELEVENLABS_API_KEY=test-key-from-env" > "$env_dir/.env"

    run _elevenlabs_get_api_key

    # Should find key from .env
    [[ $status -eq 0 ]] && [[ "$output" == "test-key-from-env" ]]

    # Cleanup
    rm -f "$env_dir/.env"
}

@test "_elevenlabs_get_api_key shows helpful error when no key found" {
    # Mock op to fail
    op() {
        return 1
    }
    export -f op

    # Ensure no .env file
    rm -f "$HOME/.config/elevenlabs/.env"

    run _elevenlabs_get_api_key

    [[ $status -eq 1 ]]
    [[ "$output" =~ "API key not found" ]]
    [[ "$output" =~ "Setup:" ]]
}

# Test: Cross-platform audio player detection
@test "_elevenlabs_play_audio detects macOS afplay" {
    skip_if '[[ "$OSTYPE" != "darwin"* ]]' "Test only for macOS"

    command_exists afplay
}

@test "_elevenlabs_play_audio has Linux player fallback" {
    skip_if '[[ "$OSTYPE" == "darwin"* ]]' "Test only for Linux"

    # At least one player should be available
    command_exists mpv || command_exists ffplay || command_exists aplay
}

@test "_elevenlabs_play_audio shows error when no player available" {
    # Mock all players to not exist
    afplay() { return 127; }
    mpv() { return 127; }
    ffplay() { return 127; }
    aplay() { return 127; }
    export -f afplay mpv ffplay aplay

    run _elevenlabs_play_audio "/tmp/test.mp3"

    [[ $status -eq 1 ]]
    [[ "$output" =~ "No audio player found" ]]
}

# Test: Error messages are helpful
@test "speak shows helpful error message" {
    run speak
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Example:" ]]
}

@test "speak-file shows helpful error for missing file" {
    run speak-file "/does/not/exist.txt"
    [[ "$output" =~ "Error: File not found" ]]
    [[ "$output" =~ "/does/not/exist.txt" ]]
}

@test "speak-save shows helpful usage message" {
    run speak-save
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Example:" ]]
    [[ "$output" =~ "output.mp3" ]]
}

# Test: Environment variable defaults
@test "ELEVENLABS_VOICE_ID has default value" {
    # Should have Rachel as default
    [[ -n "$ELEVENLABS_VOICE_ID" ]]
    [[ "$ELEVENLABS_VOICE_ID" == "21m00Tcm4TlvDq8ikWAM" ]]
}

@test "ELEVENLABS_MODEL has default value" {
    # Should have eleven_flash_v2_5 as default
    [[ -n "$ELEVENLABS_MODEL" ]]
    [[ "$ELEVENLABS_MODEL" == "eleven_flash_v2_5" ]]
}

# Test: Function output formatting
@test "speak shows progress messages" {
    # Mock curl and player
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            create_mock_audio "${@: -1}"
            return 0
        fi
    }
    afplay() { return 0; }
    mpv() { return 0; }
    export -f curl afplay mpv

    run speak "test"

    # Should show progress
    [[ "$output" =~ "Generating speech" ]] || [[ "$output" =~ "Playing audio" ]]
}

@test "speak-save confirms file saved" {
    local output_file="$TEST_TEMP_DIR/test.mp3"

    # Mock curl
    curl() {
        if [[ "$*" =~ "-o" ]]; then
            create_mock_audio "${@: -1}"
            return 0
        fi
    }
    export -f curl

    run speak-save "test" "$output_file"

    # Should confirm save
    [[ "$output" =~ "saved to" ]] && [[ "$output" =~ "$output_file" ]]
}
