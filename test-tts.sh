#!/usr/bin/env zsh

# Test script for ElevenLabs TTS integration
# Usage: ./test-tts.sh

# Load the functions
source ~/.config/zsh/functions/elevenlabs-tts.zsh

echo "=== ElevenLabs TTS Integration Test ==="
echo ""

# Test 1: API key retrieval
echo "[1/4] Testing API key retrieval..."
if api_key=$(_elevenlabs_get_api_key 2>/dev/null); then
    echo "✅ API key found (${#api_key} characters)"
else
    echo "❌ API key not found"
    echo ""
    echo "Setup required:"
    echo "  op read \"op://Private/ElevenLabs/API_KEY\""
    exit 1
fi
echo ""

# Test 2: Basic speech generation
echo "[2/4] Testing basic speech..."
if speak "Hello from Claude Code. This is a test of the ElevenLabs integration."; then
    echo "✅ Speech generated and played successfully"
else
    echo "❌ Speech generation failed"
    exit 1
fi
echo ""

# Test 3: Save to file
echo "[3/4] Testing save to file..."
test_file="/tmp/elevenlabs-test.mp3"
if speak-save "Testing file save functionality." "$test_file"; then
    if [[ -f "$test_file" && -s "$test_file" ]]; then
        file_size=$(du -h "$test_file" | cut -f1)
        echo "✅ File saved successfully ($file_size)"
        rm -f "$test_file"
    else
        echo "❌ File was not created properly"
        exit 1
    fi
else
    echo "❌ File save failed"
    exit 1
fi
echo ""

# Test 4: List voices
echo "[4/4] Testing voice list..."
echo "Available voices (first 5):"
voice-list | head -5
echo ""

echo "=== All Tests Passed ✅ ==="
echo ""
echo "Integration is working correctly!"
echo ""
echo "Try these commands:"
echo "  speak \"Your text here\""
echo "  speak-file input.txt"
echo "  speak-save \"text\" output.mp3"
echo "  voice-list"
