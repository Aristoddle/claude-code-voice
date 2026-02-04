#!/usr/bin/env bash

# Claude Code Voice - One-Command Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Aristoddle/claude-code-voice/main/install.sh | bash
#   OR:  ./install.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Aristoddle/claude-code-voice.git"
INSTALL_DIR="${HOME}/.local/share/claude-code-voice"
ZSH_FUNCTIONS_DIR="${HOME}/.config/zsh/functions"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
ELEVENLABS_CONFIG_DIR="${HOME}/.config/elevenlabs"

# Print functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Claude Code Voice - Installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}▸${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Platform detection
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Check dependencies
check_dependencies() {
    print_step "Checking dependencies..."

    local missing_deps=()

    # Required dependencies
    if ! command_exists git; then
        missing_deps+=("git")
    fi

    if ! command_exists node; then
        missing_deps+=("node")
    fi

    if ! command_exists npm; then
        missing_deps+=("npm")
    fi

    if ! command_exists curl; then
        missing_deps+=("curl")
    fi

    if ! command_exists jq; then
        missing_deps+=("jq")
    fi

    # Check Node.js version
    if command_exists node; then
        local node_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $node_version -lt 18 ]]; then
            print_warning "Node.js version $node_version detected. Version 18+ recommended."
        fi
    fi

    # Report missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""

        local platform=$(detect_platform)
        if [[ "$platform" == "macos" ]]; then
            echo "Install with Homebrew:"
            echo "  brew install ${missing_deps[*]}"
        elif [[ "$platform" == "linux" ]]; then
            echo "Install with your package manager:"
            echo "  Ubuntu/Debian: sudo apt install ${missing_deps[*]}"
            echo "  Fedora:        sudo dnf install ${missing_deps[*]}"
            echo "  Arch:          sudo pacman -S ${missing_deps[*]}"
        fi
        echo ""
        return 1
    fi

    print_success "All dependencies found"

    # Optional dependencies
    if ! command_exists op; then
        print_warning "1Password CLI not found (optional but recommended for API key security)"
    fi

    local platform=$(detect_platform)
    if [[ "$platform" == "macos" ]]; then
        if ! command_exists afplay; then
            print_warning "afplay not found (system audio player)"
        fi
    elif [[ "$platform" == "linux" ]]; then
        if ! command_exists mpv && ! command_exists ffplay; then
            print_warning "mpv or ffplay recommended for audio playback"
            echo "  Install: sudo apt install mpv  # or ffplay"
        fi
    fi
}

# Clone or update repository
setup_repository() {
    print_step "Setting up repository..."

    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Installation directory exists. Updating..."
        cd "$INSTALL_DIR"
        git pull --quiet
        print_success "Repository updated"
    else
        print_step "Cloning repository to $INSTALL_DIR..."
        git clone --quiet "$REPO_URL" "$INSTALL_DIR"
        print_success "Repository cloned"
    fi
}

# Build MCP server
build_mcp_server() {
    print_step "Building MCP server..."

    cd "$INSTALL_DIR/packages/mcp-server"

    if [[ ! -d "node_modules" ]]; then
        print_step "Installing dependencies..."
        npm install --silent
    fi

    print_step "Compiling TypeScript..."
    npm run build --silent

    if [[ -f "dist/index.js" ]]; then
        print_success "MCP server built successfully"
    else
        print_error "MCP server build failed"
        return 1
    fi
}

# Install shell functions
install_shell_functions() {
    print_step "Installing shell functions..."

    # Create functions directory if needed
    mkdir -p "$ZSH_FUNCTIONS_DIR"

    # Copy shell functions
    local source_file="$INSTALL_DIR/packages/shell-functions/elevenlabs-tts.zsh"
    local target_file="$ZSH_FUNCTIONS_DIR/elevenlabs-tts.zsh"

    if [[ ! -f "$source_file" ]]; then
        print_error "Shell functions source not found at $source_file"
        return 1
    fi

    cp "$source_file" "$target_file"
    chmod 644 "$target_file"

    print_success "Shell functions installed to $target_file"
}

# Install Claude skill
install_claude_skill() {
    print_step "Installing Claude Code skill..."

    mkdir -p "$CLAUDE_SKILLS_DIR/elevenlabs-tts"

    local source_file="$INSTALL_DIR/packages/skill/SKILL.md"
    local target_file="$CLAUDE_SKILLS_DIR/elevenlabs-tts/SKILL.md"

    if [[ ! -f "$source_file" ]]; then
        print_error "Skill definition not found at $source_file"
        return 1
    fi

    cp "$source_file" "$target_file"
    chmod 644 "$target_file"
    print_success "Claude skill installed to $target_file"
}

# Setup configuration
setup_config() {
    print_step "Setting up configuration..."

    mkdir -p "$ELEVENLABS_CONFIG_DIR"

    local env_file="$ELEVENLABS_CONFIG_DIR/.env"

    if [[ -f "$env_file" ]]; then
        print_warning "Configuration file already exists. Skipping."
        return 0
    fi

    # Copy template
    if [[ -f "$INSTALL_DIR/.env.example" ]]; then
        cp "$INSTALL_DIR/.env.example" "$env_file"
        chmod 600 "$env_file"  # Secure permissions
        print_success "Configuration template created at $env_file"
    else
        print_warning "No .env.example found to copy"
    fi
}

# Print next steps
print_next_steps() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo -e "${YELLOW}1. Get your ElevenLabs API key${NC}"
    echo "   Sign up at: https://elevenlabs.io/app/settings/api-keys"
    echo ""
    echo -e "${YELLOW}2. Store your API key securely${NC}"

    if command_exists op; then
        echo "   With 1Password CLI (recommended):"
        echo "     op item create \\"
        echo "       --category=password \\"
        echo "       --title=\"ElevenLabs\" \\"
        echo "       --vault=\"Private\" \\"
        echo "       API_KEY=\"your-elevenlabs-api-key\""
    else
        echo "   Edit configuration file:"
        echo "     nano ~/.config/elevenlabs/.env"
        echo "   Add your key:"
        echo "     ELEVENLABS_API_KEY=your_key_here"
    fi

    echo ""
    echo -e "${YELLOW}3. Reload your shell${NC}"
    echo "   exec zsh"
    echo ""
    echo -e "${YELLOW}4. Test the installation${NC}"
    echo "   speak \"Hello from Claude Code\""
    echo "   voice-list"
    echo ""
    echo -e "${YELLOW}5. Configure MCP server (optional)${NC}"
    echo "   Add to Claude Code MCP config:"
    echo "   ~/.config/claude/mcp.json"
    echo ""
    echo "Documentation: https://github.com/Aristoddle/claude-code-voice"
    echo ""
}

# Main installation flow
main() {
    print_header

    # Check dependencies first
    if ! check_dependencies; then
        exit 1
    fi

    # Execute installation steps
    setup_repository || {
        print_error "Repository setup failed"
        exit 1
    }

    build_mcp_server || {
        print_error "MCP server build failed"
        exit 1
    }

    # These can fail without breaking the install
    install_shell_functions || print_warning "Shell functions installation had issues"
    install_claude_skill || print_warning "Claude skill installation had issues"
    setup_config

    print_next_steps
}

# Run installation
main "$@"
