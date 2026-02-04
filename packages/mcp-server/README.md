# ElevenLabs MCP Server

Model Context Protocol (MCP) server providing ElevenLabs Text-to-Speech integration for Claude Code.

## Features

- ✅ Text-to-speech with natural voices (default: Rachel)
- ✅ Cross-platform audio playback (macOS + Linux)
- ✅ Voice listing and information queries
- ✅ Secure API key management via 1Password CLI
- ✅ Fast model (eleven_flash_v2_5) for low latency

## Installation

### 1. Build the Server

```bash
npm install
npm run build
```

### 2. Configure API Key

**Option A: 1Password CLI (Recommended)**

```bash
# Already done if you followed setup
op read "op://Private/ElevenLabs/API_KEY"
```

**Option B: Environment Variable**

```bash
export ELEVENLABS_API_KEY="your-api-key-here"
```

### 3. Register with Claude Code

Add to `~/.config/claude/mcp-servers.json`:

```json
{
  "mcpServers": {
    "elevenlabs-tts": {
      "command": "node",
      "args": ["/Users/joe/Projects/claude-code-voice/packages/mcp-server/dist/index.js"],
      "env": {
        "ELEVENLABS_API_KEY": "<from-1password-or-env>"
      }
    }
  }
}
```

**Using 1Password CLI**:

```json
{
  "mcpServers": {
    "elevenlabs-tts": {
      "command": "sh",
      "args": [
        "-c",
        "ELEVENLABS_API_KEY=$(op read 'op://Private/ElevenLabs/API_KEY') node /Users/joe/Projects/claude-code-voice/packages/mcp-server/dist/index.js"
      ]
    }
  }
}
```

### 4. Restart Claude Code

```bash
# Restart Claude Code to load the new MCP server
# The server will appear in available tools
```

## Available Tools

### `text_to_speech`

Convert text to audio and optionally play it.

**Parameters**:
- `text` (required): Text to convert to speech
- `voice_id` (optional): Voice ID (default: Rachel - 21m00Tcm4TlvDq8ikWAM)
- `model_id` (optional): Model ID (default: eleven_flash_v2_5)
- `play` (optional): Play audio after generation (default: true)
- `save_path` (optional): Path to save audio file

**Example**:
```typescript
{
  "text": "Hello from Claude Code",
  "play": true
}
```

### `list_voices`

List all available voices from ElevenLabs.

**Example**:
```typescript
{}
```

### `get_voice_info`

Get detailed information about a specific voice.

**Parameters**:
- `voice_id` (required): Voice ID to query

**Example**:
```typescript
{
  "voice_id": "21m00Tcm4TlvDq8ikWAM"
}
```

## Testing

### Test the Server Directly

```bash
# Set API key
export ELEVENLABS_API_KEY=$(op read "op://Private/ElevenLabs/API_KEY")

# Run server (stdio mode)
npm start
```

### Test via Claude Code

Once registered, use the `/speak` command:

```
User: /speak "Testing ElevenLabs integration"
Claude: [Uses text_to_speech tool and plays audio]
```

## Configuration

### Default Voice: Rachel

**Voice ID**: `21m00Tcm4TlvDq8ikWAM`
**Characteristics**: Warm, natural, professional
**Best for**: Explanations, summaries, technical content

### Model: eleven_flash_v2_5

**Speed**: ~2 seconds for 100 words
**Quality**: High (comparable to eleven_turbo_v2)
**Cost**: ~$0.02/minute (~$15/1M characters)

### Change Voice

Export different voice ID:

```bash
export ELEVENLABS_VOICE_ID="<another-voice-id>"
```

Or pass explicitly in tool calls:

```typescript
{
  "text": "Different voice test",
  "voice_id": "another-voice-id"
}
```

## Audio Playback

### macOS
Uses `afplay` (built-in)

### Linux
Auto-detects and uses (in order):
1. `mpv` (recommended)
2. `ffplay` (ffmpeg)
3. `aplay` (basic, MP3 may not work)

Install mpv for best experience:

```bash
# Ubuntu/Debian
sudo apt install mpv

# Fedora
sudo dnf install mpv

# Arch
sudo pacman -S mpv
```

## Troubleshooting

### Error: ELEVENLABS_API_KEY not set

**Solution**:
```bash
# Check 1Password CLI
op read "op://Private/ElevenLabs/API_KEY"

# Or set directly
export ELEVENLABS_API_KEY="your-key-here"
```

### Error: No audio player found

**macOS**: `afplay` should be built-in
**Linux**: Install `mpv` or `ffplay`

```bash
sudo apt install mpv  # Ubuntu/Debian
```

### Error: API rate limit exceeded

**Solution**:
- Free tier: 10,000 characters/month
- Upgrade: https://elevenlabs.io/pricing
- Monitor usage: https://elevenlabs.io/app/usage

### Audio doesn't play but file is created

**Check**:
1. Audio output device is connected
2. Volume is not muted
3. Player binary exists (`which afplay` or `which mpv`)

## Cost Management

### Free Tier
- 10,000 characters/month
- ~15 minutes of audio
- Good for testing

### Paid Tiers
- Starter: $5/month (30,000 characters)
- Creator: $11/month (100,000 characters)
- Pro: $99/month (500,000 characters)

### Cost Estimation

| Usage | Characters | Cost |
|-------|------------|------|
| 10 summaries (200 words each) | ~10,000 | Free |
| 100 summaries | ~100,000 | ~$1.50 |
| Daily TTS (1000 words) | ~750,000/mo | ~$11 |

**Optimize costs**:
- Use TTS for summaries, not incremental responses
- Batch multiple explanations
- Use text for code snippets
- Monitor via [ElevenLabs dashboard](https://elevenlabs.io/app/usage)

## Development

### Build

```bash
npm run build
```

### Watch Mode

```bash
npm run dev
```

### Project Structure

```
packages/mcp-server/
├── src/
│   └── index.ts          # MCP server implementation
├── dist/                 # Compiled JavaScript
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
└── README.md             # This file
```

## Related

- [ElevenLabs API Docs](https://elevenlabs.io/docs/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Claude Code](https://claude.com/claude-code)
- [Shell Functions](../../README.md#shell-functions)
- [Claude Skill](../../README.md#claude-code-skill)

## License

MIT

---

**Version**: 0.1.0
**Last Updated**: 2026-02-04
**Maintainer**: [@Aristoddle](https://github.com/Aristoddle)
