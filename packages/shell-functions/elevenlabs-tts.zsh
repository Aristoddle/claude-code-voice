# ElevenLabs Text-to-Speech Integration
# Provides: speak, speak-file, speak-save, voice-list

# Configuration
export ELEVENLABS_VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"  # Rachel
export ELEVENLABS_MODEL="${ELEVENLABS_MODEL:-eleven_flash_v2_5}"

# Get API key from 1Password or .env
_elevenlabs_get_api_key() {
    # Try 1Password CLI first (secure, recommended)
    if command -v op &>/dev/null; then
        local key
        key=$(op read "op://Private/ElevenLabs/API_KEY" 2>/dev/null)
        if [[ -n "$key" ]]; then
            echo "$key"
            return 0
        fi
    fi

    # Fallback to .env file (manual deployment)
    if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/elevenlabs/.env" ]]; then
        source "${XDG_CONFIG_HOME:-$HOME/.config}/elevenlabs/.env"
        if [[ -n "$ELEVENLABS_API_KEY" ]]; then
            echo "$ELEVENLABS_API_KEY"
            return 0
        fi
    fi

    echo "Error: ElevenLabs API key not found" >&2
    echo "Setup: op item create --category=password --title=\"ElevenLabs\" API_KEY=<key>" >&2
    echo "OR: echo 'ELEVENLABS_API_KEY=<key>' > ~/.config/elevenlabs/.env" >&2
    return 1
}

# Cross-platform audio playback
_elevenlabs_play_audio() {
    local file="$1"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use afplay
        afplay "$file"
    elif command -v mpv &>/dev/null; then
        # Linux: prefer mpv (quiet mode)
        mpv --really-quiet "$file"
    elif command -v ffplay &>/dev/null; then
        # Linux: fallback to ffplay
        ffplay -nodisp -autoexit -loglevel quiet "$file"
    elif command -v aplay &>/dev/null; then
        # Linux: last resort (MP3 may not work)
        aplay "$file" 2>/dev/null
    else
        echo "Error: No audio player found. Install mpv or ffplay." >&2
        return 1
    fi
}

# speak "text" [voice_id] [model]
# Generate audio from text and play immediately
speak() {
    if [[ -z "$1" ]]; then
        echo "Usage: speak \"text\" [voice_id] [model]" >&2
        echo "Example: speak \"Hello from Claude Code\"" >&2
        return 1
    fi

    local text="$1"
    local voice="${2:-$ELEVENLABS_VOICE_ID}"
    local model="${3:-$ELEVENLABS_MODEL}"

    # Get API key
    local api_key
    api_key=$(_elevenlabs_get_api_key) || return 1

    # Generate audio (save to temp file)
    local temp_file=$(mktemp /tmp/elevenlabs.XXXXXX.mp3)

    echo "🎙️  Generating speech..." >&2
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${voice}" \
        -H "xi-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"${text}\",\"model_id\":\"${model}\"}" \
        -o "$temp_file"

    if [[ $? -eq 0 && -s "$temp_file" ]]; then
        echo "🔊 Playing audio..." >&2
        _elevenlabs_play_audio "$temp_file"
        rm -f "$temp_file"
        echo "✅ Done" >&2
    else
        echo "❌ Error: Failed to generate audio" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# speak-file input.txt [voice_id] [model]
# Convert text file to speech
speak-file() {
    if [[ -z "$1" ]]; then
        echo "Usage: speak-file input.txt [voice_id] [model]" >&2
        return 1
    fi

    local file="$1"
    local voice="${2:-$ELEVENLABS_VOICE_ID}"
    local model="${3:-$ELEVENLABS_MODEL}"

    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi

    local text=$(<"$file")
    speak "$text" "$voice" "$model"
}

# speak-save "text" output.mp3 [voice_id] [model]
# Generate audio and save to file (no playback)
speak-save() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: speak-save \"text\" output.mp3 [voice_id] [model]" >&2
        echo "Example: speak-save \"Hello world\" ~/audio.mp3" >&2
        return 1
    fi

    local text="$1"
    local output="$2"
    local voice="${3:-$ELEVENLABS_VOICE_ID}"
    local model="${4:-$ELEVENLABS_MODEL}"

    # Get API key
    local api_key
    api_key=$(_elevenlabs_get_api_key) || return 1

    echo "🎙️  Generating speech..." >&2
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${voice}" \
        -H "xi-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"${text}\",\"model_id\":\"${model}\"}" \
        -o "$output"

    if [[ $? -eq 0 && -s "$output" ]]; then
        echo "✅ Audio saved to: $output" >&2
    else
        echo "❌ Error: Failed to generate audio" >&2
        rm -f "$output"
        return 1
    fi
}

# voice-list
# List all available ElevenLabs voices
voice-list() {
    local api_key
    api_key=$(_elevenlabs_get_api_key) || return 1

    echo "🎤 Fetching available voices..." >&2
    curl -s -X GET "https://api.elevenlabs.io/v1/voices" \
        -H "xi-api-key: ${api_key}" \
        | jq -r '.voices[] | "\(.voice_id)\t\(.name)\t\(.category)"' \
        | column -t -s $'\t'

    echo "" >&2
    echo "Current default: Rachel ($ELEVENLABS_VOICE_ID)" >&2
}
