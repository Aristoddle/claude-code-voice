---
name: elevenlabs-tts
description: "Text-to-Speech integration for generating natural audio from text. Use when: (1) User requests audio output ('read aloud', '/speak'), (2) Creating accessible content for visually impaired users, (3) Converting long explanations to audio for background listening, (4) Hands-free coding workflows"
allowed-tools:
  - text_to_speech
  - list_voices
  - get_voice_info
---

# ElevenLabs Text-to-Speech Integration

## Purpose

Provides natural text-to-speech capabilities for Claude Code using ElevenLabs API. Enables audio output for explanations, summaries, and accessibility.

## When to Use

Use TTS in these scenarios:

1. **User explicitly requests audio**:
   - "Read that aloud"
   - "Speak this summary"
   - "/speak <text>"

2. **Accessibility features**:
   - User mentions visual impairment
   - Screen reader compatibility
   - Hands-free coding sessions

3. **Long explanations**:
   - Architecture overviews (>500 words)
   - Code review summaries
   - Tutorial content

4. **Output review**:
   - User says "I'm away from keyboard"
   - Multi-tasking scenarios
   - Background listening while coding

## When NOT to Use

**Do not** use TTS automatically for:
- Short responses (<100 words)
- Code snippets (text is more useful)
- Error messages (visual scanning is faster)
- Interactive Q&A (interrupts flow)

**Always ask first** unless user has explicitly enabled voice mode.

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
await use_mcp_tool("elevenlabs-tts", "text_to_speech", {
  text: "Here's a summary of the codebase architecture...",
  play: true
});
```

### `list_voices`

List all available voices from ElevenLabs.

**Example**:
```typescript
await use_mcp_tool("elevenlabs-tts", "list_voices", {});
```

### `get_voice_info`

Get detailed information about a specific voice.

**Parameters**:
- `voice_id` (required): Voice ID to query

**Example**:
```typescript
await use_mcp_tool("elevenlabs-tts", "get_voice_info", {
  voice_id: "21m00Tcm4TlvDq8ikWAM"
});
```

## Shell Functions

Users can also use these shell functions directly:

- `speak "text"` - Generate and play audio
- `speak-file input.txt` - Convert file to audio
- `speak-save "text" output.mp3` - Save without playing
- `voice-list` - List available voices

## Configuration

**Voice**: Rachel (warm, natural, professional)
**Model**: eleven_flash_v2_5 (fast, cost-effective)
**API Key**: Retrieved from 1Password CLI or .env fallback

## Cost Considerations

- ElevenLabs charges ~$0.02/minute (~$15/1M characters)
- Free tier: 10,000 characters/month
- Typical use: 100 min/month = ~$2

**Best practices**:
- Use for summaries, not incremental responses
- Batch multiple explanations
- Prefer text for code snippets
- Monitor usage via ElevenLabs dashboard

## Integration Patterns

### Pattern 1: Summary with Audio

```
User: "Explain the authentication flow"

Claude: [Provides detailed text explanation]

Claude: "Would you like me to generate an audio version of this summary?"

User: "Yes"

Claude: [Calls text_to_speech with summary]
```

### Pattern 2: Hands-Free Workflow

```
User: "/speak Enable voice mode for this session"

Claude: [Calls text_to_speech]
"Voice mode enabled. I'll provide audio for all responses over 200 words."

[Subsequent responses automatically include audio]
```

### Pattern 3: Accessibility

```
User: "I'm using a screen reader, can you help?"

Claude: "I can provide audio output for my responses. Would you like me to enable that?"

User: "Yes please"

Claude: [Uses text_to_speech for all subsequent responses]
```

## Error Handling

If TTS fails:
1. Fall back to text-only mode gracefully
2. Inform user of the failure
3. Suggest checking API key configuration
4. Continue conversation normally

**Never block** on TTS failures - text output always takes priority.

## Testing

```bash
# Test shell function
speak "Hello from Claude Code"

# Test MCP integration (via Claude Code)
# User: /speak "Testing ElevenLabs integration"

# List available voices
voice-list
```

## Related Skills

- `chezmoi-expert` - Dotfiles integration
- `agent-validator` - Skill validation
- `deep-thinker` - Long-form content that benefits from audio

## Maintenance

**API Key Rotation**: Every 90 days
**Voice Updates**: Check ElevenLabs for new voices quarterly
**Cost Monitoring**: Review usage monthly

---

**Version**: 0.1.0
**Last Updated**: 2026-02-04
**Maintainer**: [@Aristoddle](https://github.com/Aristoddle)
