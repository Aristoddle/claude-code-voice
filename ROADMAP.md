# Roadmap

> **Current Status**: v0.1.0 in development

## Vision

Transform Claude Code from a text-only coding assistant into a **multimodal AI pair programmer** where developers can speak naturally and hear responses, making coding more accessible and enabling hands-free interaction.

---

## Milestones

### 🎯 Milestone 1: Foundation (v0.1.0) - **Feb 2026**

**Goal**: Basic text-to-speech working end-to-end

**Features**:
- [x] Repository setup with security
- [x] Comprehensive documentation
- [ ] Shell functions (`speak`, `speak-file`, `speak-save`)
- [ ] ElevenLabs MCP server
- [ ] Claude Code skill definition
- [ ] Cross-platform audio playback (macOS + Linux)
- [ ] 1Password CLI integration

**Success Criteria**:
- ✅ Can run `/speak "Hello"` in Claude Code
- ✅ Audio plays with natural voice (Rachel)
- ✅ Works on both macOS and Linux
- ✅ <10 minutes setup time
- ✅ Zero security issues (no leaked keys)

**Estimated Effort**: 2-3 days

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

**This Week** (Feb 4-10, 2026):
- [x] Repository setup
- [x] Security measures
- [x] Planning documentation
- [ ] Implement TTS shell functions
- [ ] Create ElevenLabs MCP server
- [ ] Test basic `/speak` command

**Next Week** (Feb 11-17, 2026):
- [ ] Polish TTS implementation
- [ ] Write comprehensive setup guide
- [ ] Create demo video
- [ ] Gather early feedback

---

**Last Updated**: 2026-02-04
**Maintainer**: [@Aristoddle](https://github.com/Aristoddle)
