# Contributing to Claude Code Voice

Thank you for your interest in contributing to Claude Code Voice! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Node version, Claude Code version)
- Relevant logs or error messages

### Suggesting Features

Feature suggestions are welcome! Please:

- Check existing issues and roadmap first
- Explain the use case and benefits
- Consider implementation complexity
- Be open to discussion and iteration

### Pull Request Process

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/claude-code-voice.git
   cd claude-code-voice
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Changes**
   - Follow the code style guidelines below
   - Add tests for new functionality
   - Update documentation as needed

4. **Test Your Changes**
   ```bash
   # Test shell functions
   ./test-tts.sh

   # Build and test MCP server
   cd packages/mcp-server
   npm install
   npm run build
   npm test

   # Test integration
   cd ../..
   source ~/.config/zsh/functions/elevenlabs-tts.zsh
   speak "Test message"
   ```

5. **Commit Changes**
   Use [Conventional Commits](https://www.conventionalcommits.org/) format:
   ```
   <type>(<scope>): <description>

   [optional body]

   [optional footer]
   ```

   Types:
   - `feat`: New feature
   - `fix`: Bug fix
   - `docs`: Documentation changes
   - `refactor`: Code refactoring
   - `test`: Test additions or changes
   - `chore`: Maintenance tasks

   Examples:
   ```bash
   git commit -m "feat(tts): Add voice selection support"
   git commit -m "fix(mcp): Handle network timeout errors"
   git commit -m "docs: Update setup guide with Linux instructions"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

   Then open a Pull Request on GitHub with:
   - Clear title and description
   - Link to related issues
   - Screenshots/demos if applicable
   - Test results

## Development Setup

### Prerequisites

- Node.js 18+
- npm or yarn
- Claude Code v2.1.0+
- Audio device (mic + speakers)
- macOS or Linux

### Installation

```bash
# Clone repository
git clone https://github.com/Aristoddle/claude-code-voice.git
cd claude-code-voice

# Install MCP server dependencies
cd packages/mcp-server
npm install

# Build TypeScript
npm run build

# Run in development mode (watch for changes)
npm run dev
```

### Testing

```bash
# Test shell functions
./test-tts.sh

# Test MCP server
cd packages/mcp-server
npm test

# Manual integration test
source ~/.config/zsh/functions/elevenlabs-tts.zsh
speak "Hello from Claude Code Voice"
speak-file README.md
```

## Code Style Guidelines

### TypeScript

- Use TypeScript strict mode
- Follow existing code patterns
- Use meaningful variable and function names
- Add JSDoc comments for public APIs
- Use async/await over promises
- Handle errors explicitly

Example:
```typescript
/**
 * Convert text to speech using ElevenLabs API
 * @param text - The text to convert to speech
 * @param voiceId - Optional voice ID (default: Rachel)
 * @returns Audio buffer
 */
async function textToSpeech(
  text: string,
  voiceId: string = "21m00Tcm4TlvDq8ikWAM"
): Promise<Buffer> {
  try {
    // Implementation
  } catch (error) {
    console.error("TTS conversion failed:", error);
    throw new Error(`Failed to convert text to speech: ${error.message}`);
  }
}
```

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Run `shellcheck` on all scripts
- Use meaningful variable names (lowercase with underscores)
- Quote variables to prevent word splitting
- Add error handling with `set -euo pipefail`
- Add usage documentation in comments

Example:
```bash
#!/usr/bin/env bash
set -euo pipefail

# speak - Convert text to speech using ElevenLabs
# Usage: speak "text to speak"

speak() {
  local text="$1"
  local voice_id="${2:-21m00Tcm4TlvDq8ikWAM}"

  if [[ -z "$text" ]]; then
    echo "Error: No text provided" >&2
    return 1
  fi

  # Implementation
}
```

### Documentation

- Update README.md for user-facing changes
- Update ARCHITECTURE.md for design changes
- Add inline comments for complex logic
- Keep documentation synchronized with code
- Use markdown formatting consistently

## Testing Requirements

All contributions should include appropriate tests:

### Unit Tests
- Test individual functions in isolation
- Mock external dependencies
- Cover edge cases and error conditions

### Integration Tests
- Test end-to-end workflows
- Verify MCP server communication
- Test shell function integration

### Manual Testing Checklist
- [ ] Shell functions work correctly
- [ ] MCP server starts without errors
- [ ] Audio playback works on target platforms
- [ ] Error messages are clear and helpful
- [ ] Documentation is accurate

## Project Structure

```
claude-code-voice/
├── packages/
│   └── mcp-server/          # ElevenLabs MCP server
│       ├── src/
│       │   └── index.ts     # Main server implementation
│       ├── package.json
│       └── tsconfig.json
├── scripts/                 # Shell scripts and functions
│   └── elevenlabs-tts.zsh   # Shell function implementations
├── docs/
│   ├── ARCHITECTURE.md      # Technical design
│   ├── guides/              # User guides
│   └── planning/            # Planning documents
├── tests/                   # Test files
├── test-tts.sh             # Integration test script
└── README.md               # Main documentation
```

## Release Process

Maintainers follow this process for releases:

1. Update version in `package.json`
2. Update CHANGELOG.md
3. Create git tag: `git tag -a v0.1.0 -m "Release v0.1.0"`
4. Push tag: `git push origin v0.1.0`
5. Create GitHub release with release notes

## Questions?

- Open an issue for questions
- Join discussions in GitHub Discussions
- Check existing documentation in `docs/`

## Recognition

Contributors will be recognized in:
- GitHub Contributors page
- Release notes
- Project documentation

Thank you for contributing to Claude Code Voice!
