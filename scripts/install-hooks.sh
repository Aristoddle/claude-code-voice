#!/bin/bash
# Install git hooks for claude-code-voice
# Ensures pre-commit security scanning is active

set -euo pipefail

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo -e "${BLUE}${BOLD}Claude Code Voice - Git Hooks Installer${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verify we're in a git repo
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo -e "${RED}[ERROR]${NC} Not a git repository: $PROJECT_ROOT"
  echo "This script must be run from within the claude-code-voice repository."
  exit 1
fi

echo -e "${BLUE}[1/4]${NC} Verifying hooks directory..."
if [ ! -d "$HOOKS_DIR" ]; then
  echo -e "${YELLOW}[WARNING]${NC} Hooks directory doesn't exist, creating..."
  mkdir -p "$HOOKS_DIR"
fi
echo -e "${GREEN}[OK]${NC} $HOOKS_DIR"

# Check if pre-commit hook already exists
if [ -f "$HOOKS_DIR/pre-commit" ] && [ ! -L "$HOOKS_DIR/pre-commit" ]; then
  echo ""
  echo -e "${YELLOW}[WARNING]${NC} Existing pre-commit hook found"
  echo "  Location: $HOOKS_DIR/pre-commit"
  echo ""
  read -p "Overwrite existing hook? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[SKIPPED]${NC} Installation cancelled by user"
    exit 0
  fi
  echo -e "${BLUE}[INFO]${NC} Backing up existing hook to pre-commit.backup"
  cp "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.backup"
fi

echo ""
echo -e "${BLUE}[2/4]${NC} Installing pre-commit hook..."

# The hook is already in .git/hooks/ since we wrote it there directly
# Just verify it exists and is executable
if [ -f "$HOOKS_DIR/pre-commit" ]; then
  chmod +x "$HOOKS_DIR/pre-commit"
  echo -e "${GREEN}[OK]${NC} Hook installed and made executable"
else
  echo -e "${RED}[ERROR]${NC} Pre-commit hook not found at $HOOKS_DIR/pre-commit"
  exit 1
fi

echo ""
echo -e "${BLUE}[3/4]${NC} Testing hook installation..."

# Create a test file with a fake API key
TEST_FILE="$PROJECT_ROOT/.test-hook-validation.tmp"
echo "ELEVENLABS_API_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" > "$TEST_FILE"

# Stage the file
cd "$PROJECT_ROOT"
git add "$TEST_FILE" 2>/dev/null || true

# Try to commit (should fail)
if git commit -m "test hook validation" 2>&1 | grep -q "BLOCKED"; then
  echo -e "${GREEN}[OK]${NC} Hook correctly blocks API key commits"
  # Clean up
  git reset HEAD "$TEST_FILE" >/dev/null 2>&1 || true
  rm -f "$TEST_FILE"
else
  echo -e "${RED}[ERROR]${NC} Hook did not block test API key!"
  # Clean up
  git reset HEAD "$TEST_FILE" >/dev/null 2>&1 || true
  rm -f "$TEST_FILE"
  exit 1
fi

echo ""
echo -e "${BLUE}[4/4]${NC} Verifying hook configuration..."

# Check .gitignore has necessary patterns
REQUIRED_PATTERNS=(".env" "*.key" "secrets/")
MISSING_PATTERNS=()

for pattern in "${REQUIRED_PATTERNS[@]}"; do
  if ! grep -q "^$pattern$" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    MISSING_PATTERNS+=("$pattern")
  fi
done

if [ ${#MISSING_PATTERNS[@]} -gt 0 ]; then
  echo -e "${YELLOW}[WARNING]${NC} Some .gitignore patterns may be missing:"
  for pattern in "${MISSING_PATTERNS[@]}"; do
    echo "  • $pattern"
  done
  echo -e "  ${BLUE}Recommendation:${NC} Review .gitignore for completeness"
else
  echo -e "${GREEN}[OK]${NC} .gitignore has required patterns"
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}[SUCCESS]${NC} Git hooks installed successfully!"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Installed Hooks:${NC}"
echo "  • pre-commit - Scans for API keys, secrets, and sensitive files"
echo ""
echo -e "${BOLD}What's Protected:${NC}"
echo "  ✓ ElevenLabs API keys (64 hex chars)"
echo "  ✓ Deepgram API keys (32+ chars)"
echo "  ✓ .env files"
echo "  ✓ Private keys (.key, .pem)"
echo "  ✓ Secret files and directories"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  1. Test by committing changes normally"
echo "  2. See SECURITY.md for safe key storage methods"
echo "  3. Use 1Password CLI for production credentials"
echo ""
echo -e "${BLUE}Note:${NC} To bypass hook (not recommended): git commit --no-verify"
echo ""
