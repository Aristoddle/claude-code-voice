# ElevenLabs Voice Integration for Claude Code

**Status**: Design Complete - Ready for Implementation
**Date**: 2026-02-04
**API Key**: Stored in 1Password
**Target Voice**: Rachel (ID: `21m00Tcm4TlvDq8ikWAM`)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    ElevenLabs Integration Layers                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Layer 1: Environment (API Key Management)                       │
│    ├─ 1Password CLI (primary)                                    │
│    │   └─ op://Private/ElevenLabs/API_KEY                       │
│    └─ .env fallback (manual deployment)                          │
│        └─ ~/.config/elevenlabs/.env                              │
│                                                                   │
│  Layer 2: Shell Functions (CLI Usage)                            │
│    └─ ~/.config/zsh/functions/elevenlabs-tts.zsh               │
│        ├─ speak "text"         → Generate audio, play locally    │
│        ├─ speak-file input.txt → Convert file to audio           │
│        ├─ speak-save "text" out.mp3 → Save without playing      │
│        └─ voice-list           → List available voices           │
│                                                                   │
│  Layer 3: MCP Server (Claude Integration)                        │
│    └─ ~/.local/share/mcp-servers/elevenlabs/                    │
│        ├─ index.js             → MCP server implementation       │
│        ├─ package.json         → Dependencies                    │
│        └─ tools/                                                 │
│            ├─ text_to_speech   → Generate audio from text        │
│            ├─ list_voices      → Get available voices            │
│            └─ get_voice_info   → Query voice details             │
│                                                                   │
│  Layer 4: Skill (Usage Guidance)                                 │
│    └─ ~/.claude/skills/elevenlabs-tts/SKILL.md                  │
│        └─ Context for Claude on when/how to use TTS             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Design Decisions

### 1. API Key Management

**Decision**: Use 1Password CLI as primary, with .env fallback for portability.

| Approach | Pros | Cons | Selected |
|----------|------|------|----------|
| 1Password CLI | Secure, audited, cross-device sync | Requires op signin | ✅ Primary |
| .env file | Simple, portable | Manual management, git-ignored | ✅ Fallback |
| chezmoi template | Version-controlled deployment | Key in git history | ❌ No |
| Hardcoded | None | Security nightmare | ❌ Never |

**Implementation**:
```zsh
# ~/.config/zsh/functions/elevenlabs-tts.zsh
_elevenlabs_get_api_key() {
    # Try 1Password first (secure, recommended)
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
    echo "Setup: op item create --category=password --title=ElevenLabs API_KEY=<key>" >&2
    echo "OR: echo 'ELEVENLABS_API_KEY=<key>' > ~/.config/elevenlabs/.env" >&2
    return 1
}
```

**1Password Setup**:
```bash
# Store API key (run once)
op item create \
  --category=password \
  --title="ElevenLabs" \
  --vault="Private" \
  API_KEY="f2f31b8a80aba53078b8852a23a8ccdfe4e081b24b5642ec4c1a4d90aa8a2fb8"

# Verify storage
op item get ElevenLabs --fields label=API_KEY
```

**Manual .env Fallback** (for machines without 1Password):
```bash
mkdir -p ~/.config/elevenlabs
echo 'ELEVENLABS_API_KEY=f2f31b8a80aba53078b8852a23a8ccdfe4e081b24b5642ec4c1a4d90aa8a2fb8' > ~/.config/elevenlabs/.env
chmod 600 ~/.config/elevenlabs/.env
```

---

### 2. Integration Architecture

**Decision**: Implement all layers for maximum flexibility.

| Layer | Use Case | User |
|-------|----------|------|
| Shell functions | Direct CLI usage, scripts | Human (terminal) |
| MCP server | Claude Code integration | Claude (AI agent) |
| Skill | Usage context/guidance | Claude (always-active) |

**Why all layers?**
- Shell functions: `speak "Hello"` for quick testing, scripting
- MCP server: Claude can generate audio during conversations
- Skill: Guides Claude on when TTS is appropriate (e.g., long responses, summaries)

---

### 3. Voice Selection

**Target Voice**: Rachel (ID: `21m00Tcm4TlvDq8ikWAM`)

**API Research**:
- Rachel is a premade voice (no legacy deprecation risk)
- Available in all models: `eleven_multilingual_v2`, `eleven_flash_v2_5`
- Recommended model: `eleven_flash_v2_5` (75ms latency, high quality)

**Configuration**:
```zsh
# Default voice (can be overridden with --voice flag)
ELEVENLABS_VOICE_ID="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
ELEVENLABS_VOICE_NAME="${ELEVENLABS_VOICE_NAME:-Rachel}"
ELEVENLABS_MODEL="${ELEVENLABS_MODEL:-eleven_flash_v2_5}"
```

---

### 4. Platform-Level Design

**Cross-Platform Strategy**: Use chezmoi templates for platform-specific audio playback.

| Platform | Audio Player | Install Command |
|----------|--------------|-----------------|
| macOS | `afplay` (built-in) | N/A |
| Linux | `mpv`, `ffplay`, `aplay` | `apt install mpv` / `dnf install mpv` |
| Fallback | Save file only | N/A |

**Implementation**:
```zsh
# ~/.config/zsh/functions/elevenlabs-tts.zsh
_elevenlabs_play_audio() {
    local audio_file="$1"

    # Platform detection (from existing dotfiles pattern)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        afplay "$audio_file"
    elif command -v mpv &>/dev/null; then
        mpv --no-video --quiet "$audio_file"
    elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit -hide_banner "$audio_file" 2>/dev/null
    elif command -v aplay &>/dev/null; then
        aplay -q "$audio_file"
    else
        echo "Audio saved to: $audio_file (no player found)" >&2
        echo "Install: brew install mpv (macOS) or apt install mpv (Linux)" >&2
        return 1
    fi
}
```

**Chezmoi Template** (optional, for future auto-install):
```zsh
# ~/.local/share/chezmoi/private_dot_config/zsh/functions/elevenlabs-tts.zsh.tmpl
{{ if eq .chezmoi.os "darwin" }}
# macOS: afplay is built-in
{{ else if eq .chezmoi.os "linux" }}
# Linux: Check for audio player
if ! command -v mpv &>/dev/null; then
    echo "Hint: Install mpv for audio playback (apt install mpv)" >&2
fi
{{ end }}
```

---

## Implementation Plan

### Phase 1: Shell Functions (CLI Layer)

**File**: `~/.local/share/chezmoi/private_dot_config/zsh/functions/elevenlabs-tts.zsh`

**Functions**:
```zsh
# speak "Hello world"
speak() {
    local text="$1"
    local voice="${2:-$ELEVENLABS_VOICE_ID}"
    local model="${3:-$ELEVENLABS_MODEL}"

    # Get API key
    local api_key
    api_key=$(_elevenlabs_get_api_key) || return 1

    # Generate audio (save to temp file)
    local temp_file=$(mktemp /tmp/elevenlabs.XXXXXX.mp3)

    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${voice}" \
        -H "xi-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"${text}\",\"model_id\":\"${model}\"}" \
        -o "$temp_file"

    if [[ $? -eq 0 && -s "$temp_file" ]]; then
        _elevenlabs_play_audio "$temp_file"
        rm -f "$temp_file"
    else
        echo "Error: Failed to generate audio" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# speak-file input.txt [voice_id] [model]
speak-file() {
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
speak-save() {
    local text="$1"
    local output="$2"
    local voice="${3:-$ELEVENLABS_VOICE_ID}"
    local model="${4:-$ELEVENLABS_MODEL}"

    if [[ -z "$output" ]]; then
        echo "Usage: speak-save \"text\" output.mp3 [voice_id] [model]" >&2
        return 1
    fi

    # Get API key
    local api_key
    api_key=$(_elevenlabs_get_api_key) || return 1

    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/${voice}" \
        -H "xi-api-key: ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"${text}\",\"model_id\":\"${model}\"}" \
        -o "$output"

    if [[ $? -eq 0 && -s "$output" ]]; then
        echo "Audio saved to: $output" >&2
    else
        echo "Error: Failed to generate audio" >&2
        rm -f "$output"
        return 1
    fi
}

# voice-list
voice-list() {
    local api_key
    api_key=$(_elevenlabs_get_api_key) || return 1

    curl -s -X GET "https://api.elevenlabs.io/v1/voices" \
        -H "xi-api-key: ${api_key}" \
        | jq -r '.voices[] | "\(.voice_id)\t\(.name)\t\(.category)"'
}
```

**Testing**:
```bash
# Test API key retrieval
_elevenlabs_get_api_key

# Test basic speech
speak "Hello from Claude Code"

# Test file input
echo "This is a test" > /tmp/test.txt
speak-file /tmp/test.txt

# Test save without playing
speak-save "Save this audio" /tmp/output.mp3

# List available voices
voice-list
```

---

### Phase 2: MCP Server (Claude Integration)

**Directory**: `~/.local/share/mcp-servers/elevenlabs/`

**File**: `package.json`
```json
{
  "name": "elevenlabs-mcp-server",
  "version": "1.0.0",
  "description": "ElevenLabs TTS integration for Claude Code via MCP",
  "type": "module",
  "main": "index.js",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.5.0",
    "node-fetch": "^3.3.2"
  },
  "scripts": {
    "start": "node index.js"
  }
}
```

**File**: `index.js`
```javascript
#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import fetch from 'node-fetch';
import { spawn } from 'child_process';
import { writeFileSync, unlinkSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

// Configuration
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
const ELEVENLABS_VOICE_ID = process.env.ELEVENLABS_VOICE_ID || '21m00Tcm4TlvDq8ikWAM';
const ELEVENLABS_MODEL = process.env.ELEVENLABS_MODEL || 'eleven_flash_v2_5';

if (!ELEVENLABS_API_KEY) {
  console.error('Error: ELEVENLABS_API_KEY environment variable not set');
  process.exit(1);
}

// MCP Server
const server = new Server(
  {
    name: 'elevenlabs-tts',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Tool: text_to_speech
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'text_to_speech',
        description: 'Convert text to speech using ElevenLabs API (Rachel voice)',
        inputSchema: {
          type: 'object',
          properties: {
            text: {
              type: 'string',
              description: 'Text to convert to speech',
            },
            save_path: {
              type: 'string',
              description: 'Optional: Path to save audio file (if not provided, audio plays immediately)',
            },
            voice_id: {
              type: 'string',
              description: 'Optional: Voice ID (default: Rachel)',
            },
            model_id: {
              type: 'string',
              description: 'Optional: Model ID (default: eleven_flash_v2_5)',
            },
          },
          required: ['text'],
        },
      },
      {
        name: 'list_voices',
        description: 'List available ElevenLabs voices',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'text_to_speech') {
    const { text, save_path, voice_id, model_id } = args;
    const voice = voice_id || ELEVENLABS_VOICE_ID;
    const model = model_id || ELEVENLABS_MODEL;

    try {
      const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice}`, {
        method: 'POST',
        headers: {
          'xi-api-key': ELEVENLABS_API_KEY,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          model_id: model,
        }),
      });

      if (!response.ok) {
        throw new Error(`ElevenLabs API error: ${response.statusText}`);
      }

      const audioBuffer = await response.arrayBuffer();
      const audioPath = save_path || join(tmpdir(), `elevenlabs-${Date.now()}.mp3`);
      writeFileSync(audioPath, Buffer.from(audioBuffer));

      // Play audio if no save path specified
      if (!save_path) {
        const platform = process.platform;
        let player;

        if (platform === 'darwin') {
          player = spawn('afplay', [audioPath]);
        } else {
          // Try mpv, fallback to message
          player = spawn('mpv', ['--no-video', '--quiet', audioPath]);
        }

        await new Promise((resolve) => {
          player.on('close', () => {
            unlinkSync(audioPath);
            resolve();
          });
        });

        return {
          content: [{ type: 'text', text: 'Audio played successfully' }],
        };
      }

      return {
        content: [{ type: 'text', text: `Audio saved to: ${audioPath}` }],
      };
    } catch (error) {
      return {
        content: [{ type: 'text', text: `Error: ${error.message}` }],
        isError: true,
      };
    }
  }

  if (name === 'list_voices') {
    try {
      const response = await fetch('https://api.elevenlabs.io/v1/voices', {
        headers: {
          'xi-api-key': ELEVENLABS_API_KEY,
        },
      });

      if (!response.ok) {
        throw new Error(`ElevenLabs API error: ${response.statusText}`);
      }

      const data = await response.json();
      const voiceList = data.voices.map((v) => `${v.name} (${v.voice_id})`).join('\n');

      return {
        content: [{ type: 'text', text: voiceList }],
      };
    } catch (error) {
      return {
        content: [{ type: 'text', text: `Error: ${error.message}` }],
        isError: true,
      };
    }
  }

  return {
    content: [{ type: 'text', text: `Unknown tool: ${name}` }],
    isError: true,
  };
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('ElevenLabs MCP server running on stdio');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
```

**MCP Configuration**: `~/.config/claude/mcp-servers.json`
```json
{
  "mcpServers": {
    "elevenlabs": {
      "type": "stdio",
      "command": "node",
      "args": ["/Users/joe/.local/share/mcp-servers/elevenlabs/index.js"],
      "env": {
        "ELEVENLABS_API_KEY": "op://Private/ElevenLabs/API_KEY",
        "ELEVENLABS_VOICE_ID": "21m00Tcm4TlvDq8ikWAM",
        "ELEVENLABS_MODEL": "eleven_flash_v2_5"
      }
    }
  }
}
```

**NOTE**: The `op://` syntax in `mcp-servers.json` requires 1Password integration. If not supported, use:
```json
"env": {
  "ELEVENLABS_API_KEY": "f2f31b8a80aba53078b8852a23a8ccdfe4e081b24b5642ec4c1a4d90aa8a2fb8"
}
```

**Testing**:
```bash
# Install dependencies
cd ~/.local/share/mcp-servers/elevenlabs
npm install

# Test server directly
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ELEVENLABS_API_KEY="<key>" node index.js
```

---

### Phase 3: Skill (Usage Guidance)

**File**: `~/.local/share/chezmoi/dot_claude/skills/elevenlabs-tts/SKILL.md`

```markdown
---
name: elevenlabs-tts
description: ElevenLabs text-to-speech integration. Use for generating audio summaries, reading long content, or providing voice responses. Rachel voice (natural, clear, professional).
allowed-tools:
  - mcp__elevenlabs__text_to_speech
  - mcp__elevenlabs__list_voices
---

# ElevenLabs Text-to-Speech Skill

## Purpose
Enable Claude to generate natural-sounding audio using ElevenLabs API.

## When to Use

**Appropriate Use Cases**:
- User explicitly requests audio output ("read this aloud", "generate audio")
- Summarizing long documents for audio consumption
- Creating audio versions of written content
- Accessibility: User indicates preference for audio over text

**Inappropriate Use Cases**:
- ❌ Default response mode (text is primary)
- ❌ Short responses (<100 words) unless requested
- ❌ Technical content with code/symbols (TTS struggles with syntax)
- ❌ Unsolicited audio (always ask first)

## Default Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| Voice | Rachel (`21m00Tcm4TlvDq8ikWAM`) | Natural, clear, professional |
| Model | `eleven_flash_v2_5` | 75ms latency, high quality |
| Output | Play immediately | Save to file if path provided |

## Usage Patterns

### Pattern 1: Generate and Play
```
User: "Read this summary aloud"
Claude: [Call text_to_speech with summary text]
Result: Audio plays immediately
```

### Pattern 2: Save Audio File
```
User: "Save this as an audio file"
Claude: [Call text_to_speech with save_path parameter]
Result: Audio saved to specified path
```

### Pattern 3: Summarize + Audio
```
User: "Summarize this document and create an audio version"
Claude:
  1. Generate summary (text)
  2. Show summary to user
  3. Ask: "Would you like me to generate an audio version?"
  4. If yes: [Call text_to_speech]
```

## Best Practices

1. **Always ask before generating audio** (unless explicitly requested)
2. **Keep audio segments under 500 words** (better UX, faster generation)
3. **Warn about code/technical content** ("Audio may not render syntax clearly")
4. **Provide text version first** (audio is supplementary, not replacement)

## Error Handling

If TTS fails:
1. Inform user of failure
2. Provide text version as fallback
3. Suggest checking API key configuration

## Integration with Other Skills

- **manga-visual-assessment**: Generate audio summaries of visual quality reports
- **notion-manager**: Create audio versions of research notes
- **documentation-structure-enforcer**: Generate audio docs for accessibility

## Technical Notes

- API key managed via 1Password CLI (secure)
- Fallback to .env file for portability
- Cross-platform audio playback (macOS: afplay, Linux: mpv)
- MCP server handles API communication

## Quick Reference

| Task | MCP Tool | Parameters |
|------|----------|------------|
| Generate audio | `text_to_speech` | `text`, optional `save_path` |
| List voices | `list_voices` | None |
| Custom voice | `text_to_speech` | `text`, `voice_id` |

## References
- ElevenLabs API: https://elevenlabs.io/docs/api-reference
- Voice Library: https://elevenlabs.io/docs/creative-platform/voices/voice-library
```

---

## Deployment Checklist

### Step 1: Store API Key
```bash
# Option 1: 1Password (recommended)
op item create \
  --category=password \
  --title="ElevenLabs" \
  --vault="Private" \
  API_KEY="f2f31b8a80aba53078b8852a23a8ccdfe4e081b24b5642ec4c1a4d90aa8a2fb8"

# Option 2: .env file (manual)
mkdir -p ~/.config/elevenlabs
echo 'ELEVENLABS_API_KEY=f2f31b8a80aba53078b8852a23a8ccdfe4e081b24b5642ec4c1a4d90aa8a2fb8' > ~/.config/elevenlabs/.env
chmod 600 ~/.config/elevenlabs/.env
```

### Step 2: Deploy Shell Functions
```bash
# Add to chezmoi
cd ~/.local/share/chezmoi
# Create elevenlabs-tts.zsh (see Phase 1 implementation)
vim private_dot_config/zsh/functions/elevenlabs-tts.zsh

# Deploy
chezmoi diff
chezmoi apply

# Test
speak "Hello from Claude Code"
```

### Step 3: Deploy MCP Server
```bash
# Create server directory
mkdir -p ~/.local/share/mcp-servers/elevenlabs
cd ~/.local/share/mcp-servers/elevenlabs

# Create files (see Phase 2 implementation)
# - package.json
# - index.js

# Install dependencies
npm install

# Test
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | \
  ELEVENLABS_API_KEY="$(op read op://Private/ElevenLabs/API_KEY)" node index.js
```

### Step 4: Configure MCP in Claude Code
```bash
# Edit mcp-servers.json
vim ~/.config/claude/mcp-servers.json

# Add elevenlabs server (see Phase 2 configuration)

# Restart Claude Code to load MCP server
```

### Step 5: Deploy Skill
```bash
# Add skill to chezmoi
cd ~/.local/share/chezmoi
mkdir -p dot_claude/skills/elevenlabs-tts
vim dot_claude/skills/elevenlabs-tts/SKILL.md

# Deploy
chezmoi diff
chezmoi apply

# Verify deployment
ls -la ~/.claude/skills/elevenlabs-tts/SKILL.md
```

### Step 6: Verify Integration
```bash
# Test shell function
speak "Testing ElevenLabs integration"

# Test MCP server (within Claude Code)
# Claude should now have access to text_to_speech tool

# Test skill context (automatic, no action needed)
```

---

## Platform-Specific Notes

### macOS
- Audio player: `afplay` (built-in, no install needed)
- 1Password CLI: `brew install 1password-cli`
- Node.js: Already installed via mise

### Linux (Bazzite/SteamOS)
- Audio player: Install mpv (`flatpak install mpv` or `apt install mpv`)
- 1Password CLI: Manual install from 1Password website
- Node.js: Already installed via mise

### Cross-Platform Testing
```bash
# Test on macOS
speak "macOS test"

# Test on Linux (via SSH to steambox)
ssh steambox
speak "Linux test"

# Test fallback (no audio player)
speak-save "Fallback test" /tmp/test.mp3
```

---

## Future Enhancements

### Conversational Mode
**Goal**: Real-time voice conversation with Claude Code.

**Architecture**:
```
┌─────────────────────────────────────────────────┐
│  User speaks → Speech-to-Text (Whisper API)     │
│         ↓                                        │
│  Claude processes → Text response                │
│         ↓                                        │
│  ElevenLabs TTS → Audio response                 │
│         ↓                                        │
│  User hears → Loop                               │
└─────────────────────────────────────────────────┘
```

**Implementation**:
- Add Speech-to-Text MCP server (OpenAI Whisper API)
- Create `/voice-mode` skill command
- Handle audio input/output in real-time

**Challenges**:
- Latency: Need <500ms round-trip for natural conversation
- Context: Maintain conversation state across audio exchanges
- Error handling: Background noise, accents, interruptions

**Status**: Deferred (Phase 4)

---

## Troubleshooting

### Issue: "API key not found"
**Solution**:
```bash
# Check 1Password
op item get ElevenLabs --fields label=API_KEY

# Check .env fallback
cat ~/.config/elevenlabs/.env

# Verify function can retrieve key
_elevenlabs_get_api_key
```

### Issue: "No audio player found"
**Solution**:
```bash
# macOS
# afplay is built-in, should always work

# Linux
sudo apt install mpv  # Debian/Ubuntu
sudo dnf install mpv  # Fedora/Bazzite

# Verify
which mpv
```

### Issue: "MCP server not loading"
**Solution**:
```bash
# Check mcp-servers.json syntax
jq . ~/.config/claude/mcp-servers.json

# Check Node.js is installed
which node
node --version

# Check dependencies
cd ~/.local/share/mcp-servers/elevenlabs
npm ls

# Test server manually
ELEVENLABS_API_KEY="$(op read op://Private/ElevenLabs/API_KEY)" node index.js
```

### Issue: "Audio plays but sounds garbled"
**Solution**:
- Check model: Use `eleven_flash_v2_5` (not deprecated voices)
- Check text: Remove code blocks, special characters
- Check rate limit: ElevenLabs free tier = 10,000 chars/month

---

## References

### Official Documentation
- [ElevenLabs API](https://elevenlabs.io/docs/api-reference/text-to-speech)
- [ElevenLabs Voice Library](https://elevenlabs.io/docs/creative-platform/voices/voice-library)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [1Password CLI Secret References](https://developer.1password.com/docs/cli/secret-references/)

### Implementation Examples
- [ElevenLabs Examples Repository](https://github.com/elevenlabs/elevenlabs-examples)
- [Claude Code MCP Documentation](https://code.claude.com/docs/en/mcp)
- [1Password ZSH Integration](https://www.gruntwork.io/blog/how-to-securely-store-secrets-in-1password-cli-and-load-them-into-your-zsh-shell-when-needed)

### Related Dotfiles Components
- Shell functions: `~/.config/zsh/functions/`
- MCP servers: `~/.local/share/mcp-servers/`
- Skills: `~/.claude/skills/`
- 1Password helpers: `~/.config/zsh/functions/op-helpers.zsh`

---

**Status**: Design Complete - Ready for Phase 1 Implementation
**Next Action**: Implement shell functions (Phase 1)
**Estimated Time**: 2-3 hours total (all phases)
