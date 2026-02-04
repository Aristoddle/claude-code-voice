# Requirements Document

## Project Goal

Enable voice as an additional input/output modality for Claude Code, making it accessible and enabling hands-free interaction while preserving text as the primary interface.

## User Stories

### US-1: Voice Output for Summaries
**As a** developer
**I want** to hear Claude's response as audio
**So that** I can review code while listening to explanations

**Acceptance Criteria**:
- [ ] `/speak` command generates audio from last response
- [ ] Audio plays automatically or saves to file
- [ ] Works cross-platform (macOS + Linux)
- [ ] Uses natural-sounding voice (Rachel)

---

### US-2: Voice Input for Long Prompts
**As a** developer with RSI
**I want** to speak my prompts instead of typing
**So that** I can use Claude without keyboard strain

**Acceptance Criteria**:
- [ ] `/listen` command activates microphone
- [ ] Speech transcribed to text accurately (>95% WER)
- [ ] User can review/edit before submitting
- [ ] Latency <2 seconds for transcription

---

### US-3: Conversational Mode
**As a** developer pair programming
**I want** real-time voice conversation with Claude
**So that** I can brainstorm ideas hands-free

**Acceptance Criteria**:
- [ ] `/voice-mode` toggles conversational AI
- [ ] Turn-taking works naturally (<500ms latency)
- [ ] User can interrupt Claude mid-sentence
- [ ] Text output still available simultaneously
- [ ] Can disable voice mode easily

---

### US-4: Accessibility
**As a** developer with visual impairment
**I want** audio output for all Claude responses
**So that** I can use Claude Code independently

**Acceptance Criteria**:
- [ ] Screen reader compatible
- [ ] Audio describes code structure
- [ ] Keyboard shortcuts for voice commands
- [ ] Works with existing assistive tech

---

## Functional Requirements

### FR-1: Text-to-Speech
- **Priority**: P0 (MVP)
- **Input**: Text string (up to 5000 characters)
- **Output**: Audio file (MP3) or direct playback
- **Latency**: <2 seconds for 100 words
- **Voice**: Rachel (ElevenLabs, premade)
- **Model**: `eleven_flash_v2_5`

### FR-2: Speech-to-Text
- **Priority**: P1
- **Input**: Audio stream (microphone)
- **Output**: Transcribed text
- **Accuracy**: >95% WER for clear speech
- **Latency**: <1 second for 10 seconds of audio
- **Language**: English (initial), expand later

### FR-3: Real-Time Voice Agent
- **Priority**: P2
- **Input**: Continuous audio stream
- **Output**: Interleaved audio response
- **Latency**: <500ms round-trip
- **Features**:
  - Voice Activity Detection
  - Interruption handling
  - Echo cancellation
  - Noise suppression

### FR-4: Claude Code Integration
- **Priority**: P0 (MVP)
- **Mechanism**: Model Context Protocol (MCP)
- **Tools**:
  - `text_to_speech(text, voice_id?, model_id?)`
  - `speech_to_text(audio_stream)`
  - `toggle_voice_mode(enabled)`
- **Skill**: `voice-mode` with usage guidance

### FR-5: API Key Management
- **Priority**: P0 (MVP)
- **Security**:
  - NEVER commit keys to git
  - Use environment variables (.env)
  - Support 1Password CLI integration
  - Provide clear error messages
- **Validation**: Check keys at startup

---

## Non-Functional Requirements

### NFR-1: Performance
- Text-to-Speech latency: <2 seconds
- Speech-to-Text latency: <1 second
- Conversational round-trip: <500ms
- Audio quality: 44.1kHz, 128kbps MP3

### NFR-2: Reliability
- Graceful degradation if API unavailable
- Fallback to text-only mode on error
- Retry logic with exponential backoff
- User-friendly error messages

### NFR-3: Security
- API keys stored securely (not in code)
- HTTPS for all API communication
- Secrets rotation every 90 days
- Pre-commit hooks to prevent key leaks

### NFR-4: Compatibility
- **Platforms**: macOS 12+, Linux (Ubuntu 20.04+, Fedora 38+)
- **Claude Code**: v2.1.0+
- **Node.js**: 18+
- **Audio**: Any USB/built-in microphone + speakers

### NFR-5: Cost
- Target: <$5/month for typical use (100 min/month)
- Free tier available for both services
- Usage tracking and warnings
- Cost breakdown in docs

### NFR-6: Documentation
- README with quick start
- Architecture docs with diagrams
- Setup guide with troubleshooting
- Usage examples for each command
- API reference for MCP tools

---

## Out of Scope (v1.0)

| Feature | Rationale | Future Version |
|---------|-----------|----------------|
| Video integration | Voice-only for MVP | v2.0 |
| Multi-language support | English first, expand later | v0.4.0 |
| Custom voice training | Use premade voices | v2.0 |
| Offline mode | Requires local models | v1.0.0 (separate branch) |
| Mobile support | Desktop/CLI focus | v3.0 |
| Group conversations | 1-on-1 with Claude only | v2.0 |

---

## Success Metrics

### Launch (v0.1.0)
- [ ] 10 users try the tool
- [ ] <5 setup issues reported
- [ ] Documentation rated 4/5+ stars

### Adoption (v0.3.0)
- [ ] 100 users actively using voice mode
- [ ] <2% error rate in production
- [ ] 4.5/5 average user satisfaction

### Maturity (v1.0.0)
- [ ] 500+ GitHub stars
- [ ] Featured in Claude Code skill marketplace
- [ ] <1% error rate, >99% uptime
- [ ] 10+ community contributions

---

## Dependencies

### External Services
1. **Deepgram** (Speech-to-Text)
   - Pricing: $0.0043/min
   - Free tier: $200 credit
   - Docs: https://developers.deepgram.com/

2. **ElevenLabs** (Text-to-Speech)
   - Pricing: $0.02/min (~$15/1M chars)
   - Free tier: 10,000 chars/month
   - Docs: https://elevenlabs.io/docs/

3. **LiveKit** (Real-time voice, optional)
   - Self-hosted: Docker
   - Cloud: $0.01/min (optional)
   - Docs: https://docs.livekit.io/

### Development Tools
- Node.js 18+ (runtime)
- Model Context Protocol SDK (Claude integration)
- Audio libraries: ffmpeg, sox (platform-specific)
- GitHub Actions (CI/CD)
- Pre-commit hooks (security)

---

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| API key leak | High | Medium | Pre-commit hooks, automated scanning |
| Service downtime | Medium | Low | Fallback to text mode, retry logic |
| High latency | Medium | Medium | Use fast models, optimize pipeline |
| Cost overrun | Medium | Low | Usage tracking, rate limiting |
| Poor audio quality | High | Low | Test with real users, tune settings |

---

## Timeline

### Week 1: Foundation (v0.1.0)
- Day 1-2: Repository setup, documentation
- Day 3-4: Implement TTS (shell functions)
- Day 5-7: MCP server + skill

### Week 2: Voice Input (v0.2.0)
- Day 1-3: Implement STT
- Day 4-5: Push-to-talk UI
- Day 6-7: Testing + docs

### Week 3-4: Conversational (v0.3.0)
- Day 1-5: LiveKit integration
- Day 6-10: Voice agent loop
- Day 11-14: Polish + demo

---

**Status**: Draft → Review → Approved
**Last Updated**: 2026-02-04
**Reviewers**: [@Aristoddle]
