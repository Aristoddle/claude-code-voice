# Roadmap

> **Current Status**: v0.1.0 ✅ **COMPLETE** (Feb 4, 2026)

## Vision

Transform Claude Code from a text-only coding assistant into a **multimodal AI pair programmer** where developers can speak naturally and hear responses, making coding more accessible and enabling hands-free interaction.

---

## Milestones

### 🎯 Milestone 1: Foundation (v0.1.0) - ✅ **COMPLETE** (Feb 4, 2026)

**Goal**: Basic text-to-speech working end-to-end ✅

**Features**:
- [x] Repository setup with security
- [x] Comprehensive documentation
- [x] Shell functions (`speak`, `speak-file`, `speak-save`, `voice-list`)
- [x] ElevenLabs MCP server (TypeScript + MCP SDK)
- [x] Claude Code skill definition (YAML frontmatter)
- [x] Cross-platform audio playback (macOS: afplay, Linux: mpv/ffplay)
- [x] 1Password CLI integration (with .env fallback)

**Success Criteria**:
- ✅ Can run `speak "Hello"` in shell
- ✅ Audio plays with natural voice (Rachel - 21m00Tcm4TlvDq8ikWAM)
- ✅ Works on both macOS and Linux
- ✅ <10 minutes setup time (via test-tts.sh)
- ✅ Zero security issues (no leaked keys, pre-commit hooks)

**Implementation**:
- MCP Server: `packages/mcp-server/` (TypeScript, compiled to JS)
- Shell Functions: `~/.config/zsh/functions/elevenlabs-tts.zsh`
- Claude Skill: `~/.claude/skills/elevenlabs-tts/SKILL.md`
- Test Suite: `test-tts.sh` (validates API, generation, playback)

**Actual Effort**: 3 hours (single session)

**Git Commits**:
- claude-code-voice: `c8c7d52` - feat(milestone-1): Complete v0.1.0 TTS implementation
- dotfiles: `45e394c` - feat(voice): Add ElevenLabs TTS integration for Claude Code

---

### 🎙️ Milestone 2: Voice Input (v0.2.0) - **Mar 2026**

**Goal**: Speak prompts instead of typing

**Features**:
- [ ] Deepgram STT MCP server
- [ ] `/listen` command for voice input
- [ ] Push-to-talk interface
- [ ] Transcription review/edit UI
- [ ] Voice-to-text tool for Claude

**Success Criteria**:
- ✅ Can speak 30-second prompt
- ✅ >95% transcription accuracy
- ✅ <2 seconds latency
- ✅ Can edit before submitting
- ✅ Works with background noise

**Estimated Effort**: 1 week

---

### 💬 Milestone 3: Conversational Mode (v0.3.0) - **Apr 2026**

**Goal**: Real-time voice conversation with Claude

**Features**:
- [ ] LiveKit server (Docker setup)
- [ ] Voice agent orchestration
- [ ] `/voice-mode` toggle command
- [ ] Voice Activity Detection
- [ ] Interruption handling
- [ ] Conversation state management
- [ ] Latency optimization (<500ms)

**Success Criteria**:
- ✅ Natural back-and-forth conversation
- ✅ <500ms round-trip latency
- ✅ Can interrupt mid-sentence
- ✅ Text output still available
- ✅ 10-minute conversations without issues

**Estimated Effort**: 2 weeks

---

## Current Focus

**Completed** (Feb 4, 2026):
- [x] Repository setup
- [x] Security measures
- [x] Planning documentation
- [x] Implement TTS shell functions ✅
- [x] Create ElevenLabs MCP server ✅
- [x] Test basic `speak` command ✅
- [x] Deploy via chezmoi ✅
- [x] Push to GitHub ✅

**Next Week** (Feb 11-17, 2026):
- [ ] Begin Milestone 2: Voice Input (STT)
- [ ] Deepgram MCP server implementation
- [ ] `/listen` command prototype
- [ ] Create demo video for v0.1.0
- [ ] Gather early feedback from testing

---

**Last Updated**: 2026-02-04
**Maintainer**: [@Aristoddle](https://github.com/Aristoddle)
