#!/usr/bin/env bash
# Install the tmux-claude-codex `start` alias on macOS.
#
#   - Appends an idempotent block to ~/.zshrc (or ~/.bash_profile fallback).
#   - The alias SSHes to $TMC_DEV_HOST and runs ~/bin/work on the dev VM.
#   - Default $TMC_DEV_HOST is "yhadad-dev" — override by exporting it
#     in your own shell config above the appended block.
#
# Usage: ./install-mac.sh

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script is for macOS. On a Linux dev VM, run ./install-dev-vm.sh instead." >&2
    exit 1
fi

# Pick the right rc file based on the user's shell
case "${SHELL##*/}" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash) RC="$HOME/.bash_profile" ;;
    *)    RC="$HOME/.zshrc" ;;  # zsh is the macOS default since Catalina
esac

MARKER="# === tmux-claude-codex ==="

if [[ -f "$RC" ]] && grep -qF "$MARKER" "$RC"; then
    echo "✓ already installed (marker present in $RC)"
    echo ""
    echo "To re-install, remove the block under '$MARKER' from $RC and re-run."
    exit 0
fi

cat >> "$RC" <<'EOF'

# === tmux-claude-codex ===
# `start` → SSH to dev VM and attach to the 4-pane tmux workspace.
# Override the host by exporting TMC_DEV_HOST before this line, or in ~/.zshenv.
: "${TMC_DEV_HOST:=yhadad-dev}"
alias start="ssh \"\$TMC_DEV_HOST\" -t '~/bin/work'"
EOF

echo "✓ appended 'start' alias to $RC"
echo ""
echo "Next steps:"
echo "  1. Set TMC_DEV_HOST if your dev VM SSH alias isn't 'yhadad-dev':"
echo "     export TMC_DEV_HOST='your-host'   # add to ~/.zshenv to persist"
echo "  2. Make sure '~/.ssh/config' has a Host block for that name."
echo "  3. Run: source $RC   (or open a new terminal tab)"
echo "  4. Type: start"
