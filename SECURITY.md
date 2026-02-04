# Security Policy

## ⚠️ CRITICAL: Never Commit API Keys

**API keys are sensitive credentials that must NEVER be committed to this repository.**

### Protected Files (in `.gitignore`)

```
.env                    # Environment variables with keys
.env.*                  # Any env file variants
*.key                   # Key files
secrets/                # Any secrets directory
config.local.json       # Local config overrides
.claude/mcp-servers.json  # Claude config with keys
```

### Safe Configuration Methods

#### Method 1: Environment Variables (Recommended)
```bash
# Copy example file
cp .env.example .env

# Edit .env with your actual keys (NEVER commit this file!)
vim .env

# Load in shell
export $(cat .env | xargs)
```

#### Method 2: 1Password CLI (Most Secure)
```bash
# Store in 1Password
op item create --category=password \
  --title="Deepgram API Key" \
  --vault="Private" \
  credential="your-key-here"

# Retrieve at runtime
export DEEPGRAM_API_KEY=$(op item get "Deepgram API Key" --fields credential)
```

#### Method 3: System Keychain
```bash
# macOS Keychain
security add-generic-password \
  -s "claude-code-voice" \
  -a "deepgram" \
  -w "your-key-here"

# Retrieve
export DEEPGRAM_API_KEY=$(security find-generic-password \
  -s "claude-code-voice" -a "deepgram" -w)
```

### Pre-Commit Hooks

We use pre-commit hooks to scan for accidental key commits:

```bash
# Install pre-commit
pip install pre-commit

# Set up hooks
pre-commit install

# Hooks will scan for:
# - API key patterns
# - .env files
# - Common secret formats
```

### If You Accidentally Commit a Key

1. **Revoke the key immediately** at the provider:
   - Deepgram: https://console.deepgram.com/
   - ElevenLabs: https://elevenlabs.io/app/settings/api-keys

2. **Remove from git history**:
   ```bash
   # Install BFG Repo Cleaner
   brew install bfg

   # Remove sensitive data
   bfg --delete-files .env

   # Force push (destructive!)
   git push --force
   ```

3. **Generate new keys** and update your local config

### Reporting Security Issues

If you discover a security vulnerability, please:

1. **Do NOT open a public issue**
2. Email: [your-security-email]
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact

We will respond within 48 hours.

### Security Checklist for Contributors

- [ ] I have not committed any `.env` files
- [ ] I have not committed any API keys in code
- [ ] I have used `.env.example` or `config.example.*` for examples
- [ ] I have verified `.gitignore` excludes sensitive files
- [ ] I have tested pre-commit hooks locally
- [ ] I have reviewed my changes for accidental secrets

### Key Rotation Policy

**Best practices**:
- Rotate API keys every 90 days
- Use separate keys for dev/prod environments
- Never share keys in chat, email, or screenshots
- Use minimal permissions (read-only when possible)

### Audit Commands

```bash
# Check for potential secrets in repo
git log -p | grep -i "api.key\|secret\|password"

# Scan current branch
git diff --cached | grep -i "api.key\|secret\|password"

# Use gitleaks (automated scanner)
brew install gitleaks
gitleaks detect --source . --verbose
```

### Environment Variable Validation

All scripts validate that required keys are set:

```bash
if [[ -z "$DEEPGRAM_API_KEY" ]]; then
  echo "Error: DEEPGRAM_API_KEY not set"
  echo "See SECURITY.md for configuration options"
  exit 1
fi
```

### Additional Resources

- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [1Password Developer Docs](https://developer.1password.com/docs/cli/)

---

**Remember**: Leaked keys can result in:
- Unauthorized API usage charges
- Account compromise
- Service abuse
- Data breaches

**When in doubt, rotate your keys.**
