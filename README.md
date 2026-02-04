# Claude Code Voice

> Add voice input/output to Claude Code. Speak to Claude, hear responses.

**Status**: 🚧 In Development (v0.1.0)
**License**: MIT
**Platforms**: macOS, Linux

## Overview

Claude Code Voice adds **voice as an extra modality** to Claude Code, enabling:

- 🎤 **Voice Input** - Speak your prompts instead of typing
- 🔊 **Voice Output** - Hear Claude's responses as natural speech
- 💬 **Conversational Mode** - Real-time voice conversations with Claude
- ♿ **Accessibility** - Hands-free coding and documentation

## Quick Start

### One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/Aristoddle/claude-code-voice/main/install.sh | bash
```

This will:
- Install dependencies and build the MCP server
- Set up shell functions (`speak`, `speak-file`, `voice-list`)
- Configure Claude Code skill
- Create configuration template

After installation:

```bash
# 1. Get your API key from https://elevenlabs.io/app/settings/api-keys

# 2. Store it securely (1Password recommended)
op item create \
  --category=password \
  --title="ElevenLabs" \
  --vault="Private" \
  API_KEY="your-elevenlabs-api-key"

# OR: Edit config file
nano ~/.config/elevenlabs/.env

# 3. Reload shell and test
exec zsh
speak "Hello from Claude Code"
```

### Manual Installation

If you prefer manual installation, see [Setup Guide](docs/guides/setup.md).

## Features

| Feature | Status | Version |
|---------|--------|---------|
| Text-to-Speech (TTS) | ✅ Implemented | v0.1.0 |
| Speech-to-Text (STT) | 🚧 In Progress | v0.2.0 |
| Conversational Mode | 📋 Planned | v0.3.0 |
| Multi-language | 📋 Planned | v0.4.0 |
| Offline Mode | 📋 Planned | v1.0.0 |

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│         Claude Code + Voice (Dual Modality)              │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Input:  Text (keyboard) OR Voice (microphone)          │
│           ↓                                              │
│  Process: Claude Code (LLM reasoning)                    │
│           ↓                                              │
│  Output: Text (terminal) AND/OR Voice (speaker)          │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

Three MCP servers provide voice capabilities:

1. **elevenlabs-tts** - Text-to-Speech (ElevenLabs API)
2. **deepgram-stt** - Speech-to-Text (Deepgram API)
3. **livekit-orchestrator** - Real-time voice agent (LiveKit)

## Use Cases

### 1. Accessibility
```
User with mobility constraints speaks prompts
→ Claude processes verbally
→ Responds with both text + voice
```

### 2. Documentation Review
```
User: /speak "Summarize this PR description"
→ Claude reads summary aloud while user reviews code
```

### 3. Hands-Free Coding
```
User: /voice-mode
User: [speaks] "Create a function that validates email"
→ Claude shows code + explains verbally
User: [speaks] "Add error handling"
→ Claude updates code + confirms verbally
```

### 4. Long-Form Listening
```
User: /speak-file docs/architecture.md
→ Converts doc to audio for commute/workout
```

## Documentation

- **[Architecture](docs/ARCHITECTURE.md)** - Technical design and decisions
- **[Roadmap](ROADMAP.md)** - Features and milestones
- **[Setup Guide](docs/guides/setup.md)** - Installation instructions
- **[Usage Guide](docs/guides/usage.md)** - Commands and examples
- **[Planning Docs](docs/planning/)** - Requirements and decisions

## Development

```bash
# Clone repo
git clone https://github.com/Aristoddle/claude-code-voice
cd claude-code-voice

# Install dependencies
npm install

# Run tests
npm test

# Build packages
npm run build
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup.

## Roadmap

### Milestone 1: Foundation (v0.1.0) ✅ **COMPLETE**
- [x] Repository setup with security
- [x] Comprehensive documentation
- [x] Shell functions (`speak`, `speak-file`, `speak-save`)
- [x] ElevenLabs MCP server (TypeScript)
- [x] Claude Code skill definition
- [x] Cross-platform audio playback (macOS + Linux)
- [x] 1Password CLI integration

### Milestone 2: Voice Input (v0.2.0) 🚧
- [ ] Deepgram STT integration
- [ ] Push-to-talk interface
- [ ] Voice-to-text MCP tool
- [ ] Latency optimization

### Milestone 3: Conversational (v0.3.0) 📋
- [ ] LiveKit server setup
- [ ] Voice agent loop
- [ ] Interruption handling
- [ ] State management

### Milestone 4: Release (v1.0.0) 📋
- [ ] Comprehensive docs
- [ ] Demo videos
- [ ] Cross-platform testing
- [ ] Community feedback

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| STT | Deepgram Nova-2 | Speech recognition |
| TTS | ElevenLabs Flash v2.5 | Speech synthesis |
| Voice | Rachel (premade) | Natural, clear voice |
| Real-time | LiveKit | WebRTC streaming |
| Integration | MCP (Model Context Protocol) | Claude Code connection |
| Security | 1Password CLI | API key management |

## Requirements

- Claude Code v2.1.0+
- Node.js 18+
- Audio device (mic + speakers)
- Platform: macOS or Linux
- API keys: Deepgram + ElevenLabs

## Cost Estimate

| Service | Pricing | Typical Usage | Monthly Cost |
|---------|---------|---------------|--------------|
| Deepgram | $0.0043/min | 100 min/month | $0.43 |
| ElevenLabs | $0.02/min | 100 min/month | $2.00 |
| LiveKit | Self-hosted | Docker | $0.00 |
| **Total** | | 100 min/month | **~$2.50** |

Free tier available for both services.

## Contributing

Contributions welcome! Please see:

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - Community standards
- [Issues](https://github.com/Aristoddle/claude-code-voice/issues) - Bug reports and features

## License

MIT License - see [LICENSE](LICENSE) file.

## Acknowledgments

- [ElevenLabs](https://elevenlabs.io/) - Natural TTS
- [Deepgram](https://deepgram.com/) - Accurate STT
- [LiveKit](https://livekit.io/) - Real-time voice infrastructure
- [Claude Code](https://code.claude.com/) - AI-powered coding assistant

---

**Status**: Active development - contributions welcome!
**Maintainer**: [@Aristoddle](https://github.com/Aristoddle)
**Discussions**: [GitHub Discussions](https://github.com/Aristoddle/claude-code-voice/discussions)
