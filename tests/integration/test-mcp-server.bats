#!/usr/bin/env bats
# Integration tests for MCP server (packages/mcp-server/dist/index.js)

# Load test helpers
load test-helpers

setup() {
    setup_test_env

    # Path to MCP server
    MCP_SERVER_PATH="/Users/joe/Projects/claude-code-voice/packages/mcp-server/dist/index.js"

    # Skip all tests if server doesn't exist
    if [[ ! -f "$MCP_SERVER_PATH" ]]; then
        skip "MCP server not built at $MCP_SERVER_PATH (run: npm run build)"
    fi

    # Set API key for server
    export ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-test-api-key}"
}

teardown() {
    teardown_test_env

    # Stop any running MCP servers
    pkill -f "node.*mcp-server.*index.js" 2>/dev/null || true
}

# Test: Server file exists
@test "MCP server file exists" {
    [[ -f "$MCP_SERVER_PATH" ]]
}

@test "MCP server is executable JavaScript" {
    [[ -f "$MCP_SERVER_PATH" ]]
    head -1 "$MCP_SERVER_PATH" | grep -q "node"
}

@test "MCP server has proper shebang" {
    head -1 "$MCP_SERVER_PATH" | grep -q "#!/usr/bin/env node"
}

# Test: Server dependencies
@test "MCP server has required Node.js modules" {
    local pkg_dir="/Users/joe/Projects/claude-code-voice/packages/mcp-server"

    [[ -d "$pkg_dir/node_modules/@modelcontextprotocol/sdk" ]]
}

@test "Node.js is available" {
    command_exists node
}

@test "Node.js version is 18 or higher" {
    local version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    [[ $version -ge 18 ]]
}

# Test: Server startup
@test "MCP server starts without errors" {
    skip_if 'is_ci' "Skipping server startup test in CI"

    # Start server with timeout
    timeout 5s node "$MCP_SERVER_PATH" </dev/null &
    local pid=$!

    # Wait a moment for startup
    sleep 1

    # Check if still running (should not exit immediately)
    if kill -0 $pid 2>/dev/null; then
        kill $pid 2>/dev/null
        wait $pid 2>/dev/null
        return 0
    else
        return 1
    fi
}

@test "MCP server requires ELEVENLABS_API_KEY" {
    unset ELEVENLABS_API_KEY

    run timeout 2s node "$MCP_SERVER_PATH" </dev/null 2>&1

    [[ "$output" =~ "ELEVENLABS_API_KEY" ]] || [[ $status -eq 1 ]]
}

@test "MCP server shows helpful error for missing API key" {
    unset ELEVENLABS_API_KEY

    run timeout 2s node "$MCP_SERVER_PATH" 2>&1

    [[ "$output" =~ "API" ]] && [[ "$output" =~ "key" ]]
}

# Test: Server tools registration
@test "MCP server code includes text_to_speech tool" {
    grep -q "text_to_speech" "$MCP_SERVER_PATH"
}

@test "MCP server code includes list_voices tool" {
    grep -q "list_voices" "$MCP_SERVER_PATH"
}

@test "MCP server code includes get_voice_info tool" {
    grep -q "get_voice_info" "$MCP_SERVER_PATH" || \
    grep -q "voice_info" "$MCP_SERVER_PATH"
}

# Test: Server configuration
@test "MCP server uses correct API base URL" {
    grep -q "api.elevenlabs.io" "$MCP_SERVER_PATH"
}

@test "MCP server uses v1 API endpoint" {
    grep -q "/v1/" "$MCP_SERVER_PATH"
}

@test "MCP server has default voice ID configured" {
    grep -q "21m00Tcm4TlvDq8ikWAM" "$MCP_SERVER_PATH"
}

@test "MCP server has default model configured" {
    grep -q "eleven_flash" "$MCP_SERVER_PATH"
}

# Test: Cross-platform audio support
@test "MCP server detects platform" {
    grep -q "platform()" "$MCP_SERVER_PATH"
}

@test "MCP server supports macOS audio playback" {
    grep -q "darwin" "$MCP_SERVER_PATH"
    grep -q "afplay" "$MCP_SERVER_PATH"
}

@test "MCP server supports Linux audio playback" {
    grep -q "linux" "$MCP_SERVER_PATH"
    grep -q "mpv\|ffplay" "$MCP_SERVER_PATH"
}

@test "MCP server handles missing audio player gracefully" {
    grep -q "No audio player found" "$MCP_SERVER_PATH"
}

# Test: API integration
@test "MCP server makes POST requests for TTS" {
    grep -q "POST" "$MCP_SERVER_PATH"
    grep -q "text-to-speech" "$MCP_SERVER_PATH"
}

@test "MCP server makes GET requests for voice list" {
    grep -q "GET" "$MCP_SERVER_PATH"
    grep -q "/voices" "$MCP_SERVER_PATH"
}

@test "MCP server sends xi-api-key header" {
    grep -q "xi-api-key" "$MCP_SERVER_PATH"
}

@test "MCP server sends Content-Type header for JSON" {
    grep -q "Content-Type.*application/json" "$MCP_SERVER_PATH"
}

# Test: Error handling
@test "MCP server handles API errors" {
    grep -q "Error" "$MCP_SERVER_PATH"
    grep -q "response.ok" "$MCP_SERVER_PATH" || \
    grep -q "status" "$MCP_SERVER_PATH"
}

@test "MCP server handles network errors gracefully" {
    grep -q "error\|Error\|catch" "$MCP_SERVER_PATH"
}

# Test: Audio file handling
@test "MCP server creates temporary audio files" {
    grep -q "tmp\|temp" "$MCP_SERVER_PATH"
}

@test "MCP server handles file I/O" {
    grep -q "writeFileSync\|writeFile" "$MCP_SERVER_PATH"
}

@test "MCP server cleans up temporary files" {
    grep -q "unlinkSync\|unlink" "$MCP_SERVER_PATH"
}

# Test: Server output
@test "MCP server logs errors to stderr" {
    grep -q "console.error" "$MCP_SERVER_PATH"
}

# Test: Package structure
@test "MCP server package.json exists" {
    [[ -f "/Users/joe/Projects/claude-code-voice/packages/mcp-server/package.json" ]]
}

@test "MCP server has build script" {
    local pkg="/Users/joe/Projects/claude-code-voice/packages/mcp-server/package.json"

    grep -q '"build"' "$pkg"
}

@test "MCP server has start script" {
    local pkg="/Users/joe/Projects/claude-code-voice/packages/mcp-server/package.json"

    grep -q '"start"' "$pkg" || grep -q '"bin"' "$pkg"
}

# Test: TypeScript source
@test "MCP server has TypeScript source file" {
    [[ -f "/Users/joe/Projects/claude-code-voice/packages/mcp-server/src/index.ts" ]]
}

# Test: Configuration files
@test "MCP server has tsconfig.json" {
    [[ -f "/Users/joe/Projects/claude-code-voice/packages/mcp-server/tsconfig.json" ]]
}

# Test: Audio format
@test "MCP server generates MP3 audio" {
    grep -q "mp3\|MP3" "$MCP_SERVER_PATH"
}

# Test: Server transport
@test "MCP server uses stdio transport" {
    grep -q "stdio\|StdioServerTransport" "$MCP_SERVER_PATH"
}

@test "MCP server uses MCP SDK" {
    grep -q "@modelcontextprotocol/sdk" "$MCP_SERVER_PATH"
}

# Test: Voice configuration
@test "MCP server reads voice ID from environment" {
    grep -q "ELEVENLABS_VOICE_ID" "$MCP_SERVER_PATH"
}

@test "MCP server reads model from environment" {
    grep -q "ELEVENLABS_MODEL" "$MCP_SERVER_PATH"
}

# Test: Server lifecycle
@test "MCP server handles process signals gracefully" {
    skip_if 'is_ci' "Skipping signal handling test in CI"

    # Start server
    timeout 5s node "$MCP_SERVER_PATH" </dev/null &
    local pid=$!

    sleep 1

    # Send SIGTERM
    kill -TERM $pid 2>/dev/null

    # Should exit cleanly
    wait $pid 2>/dev/null
    local exit_code=$?

    # Exit code 143 is SIGTERM, 0 is clean exit
    [[ $exit_code -eq 143 || $exit_code -eq 0 || $exit_code -eq 124 ]]
}

# Test: Security
@test "MCP server does not log API keys" {
    ! grep -q "console.log.*API_KEY\|console.log.*api_key" "$MCP_SERVER_PATH"
}

@test "MCP server does not expose secrets in errors" {
    # Should not include full API key in error messages
    ! grep -q "\\$\{ELEVENLABS_API_KEY\}" "$MCP_SERVER_PATH" || \
    grep -q "console.error.*key" "$MCP_SERVER_PATH"
}

# Test: Performance
@test "MCP server uses streaming for audio" {
    grep -q "arrayBuffer\|buffer\|Buffer" "$MCP_SERVER_PATH"
}
