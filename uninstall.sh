#!/usr/bin/env bash

# Claude Code Voice - Uninstaller
# Usage: ./uninstall.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="${HOME}/.local/share/claude-code-voice"
ZSH_FUNCTIONS_FILE="${HOME}/.config/zsh/functions/elevenlabs-tts.zsh"
CLAUDE_SKILL_DIR="${HOME}/.claude/skills/elevenlabs-tts"
ELEVENLABS_CONFIG_DIR="${HOME}/.config/elevenlabs"

# Print functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Claude Code Voice - Uninstaller${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}▸${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Confirm uninstall
confirm_uninstall() {
    echo "This will remove:"
    echo "  - Repository:      $INSTALL_DIR"
    echo "  - Shell functions: $ZSH_FUNCTIONS_FILE"
    echo "  - Claude skill:    $CLAUDE_SKILL_DIR"
    echo ""
    echo "Your configuration will be preserved:"
    echo "  - API keys:        $ELEVENLABS_CONFIG_DIR/.env"
    echo ""

    read -p "Continue with uninstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi
}

# Remove installation directory
remove_install_dir() {
    print_step "Removing installation directory..."

    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        print_success "Removed $INSTALL_DIR"
    else
        print_warning "Installation directory not found"
    fi
}

# Remove shell functions
remove_shell_functions() {
    print_step "Removing shell functions..."

    if [[ -f "$ZSH_FUNCTIONS_FILE" ]]; then
        rm -f "$ZSH_FUNCTIONS_FILE"
        print_success "Removed $ZSH_FUNCTIONS_FILE"
    else
        print_warning "Shell functions file not found"
    fi
}

# Remove Claude skill
remove_claude_skill() {
    print_step "Removing Claude skill..."

    if [[ -d "$CLAUDE_SKILL_DIR" ]]; then
        rm -rf "$CLAUDE_SKILL_DIR"
        print_success "Removed $CLAUDE_SKILL_DIR"
    else
        print_warning "Claude skill directory not found"
    fi
}

# Optional: Remove configuration
remove_config() {
    echo ""
    read -p "Also remove configuration (API keys)? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Removing configuration..."

        if [[ -d "$ELEVENLABS_CONFIG_DIR" ]]; then
            rm -rf "$ELEVENLABS_CONFIG_DIR"
            print_success "Removed $ELEVENLABS_CONFIG_DIR"
        else
            print_warning "Configuration directory not found"
        fi
    else
        print_warning "Configuration preserved at $ELEVENLABS_CONFIG_DIR"
    fi
}

# Print completion message
print_completion() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Uninstall Complete!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Reload your shell to remove functions from memory:"
    echo "  exec zsh"
    echo ""
}

# Main uninstall flow
main() {
    print_header
    confirm_uninstall

    remove_install_dir
    remove_shell_functions
    remove_claude_skill
    remove_config

    print_completion
}

# Run uninstall
main "$@"
