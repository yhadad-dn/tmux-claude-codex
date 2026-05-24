#!/usr/bin/env bash
# Install the tmux-claude-codex workspace on a Linux dev VM.
#
#   - Symlinks ./work to ~/bin/work (so `git pull` updates the live script).
#   - Copies ./tmux.conf to ~/.tmux.conf (prompts if a custom one exists).
#   - Seeds ~/.work.conf from work.conf.example (skips if you already have one).
#   - Checks for tmux / claude / lazygit / codex and prints install hints
#     for any that are missing; does NOT install them.
#
# Usage:    ./install-dev-vm.sh [--force]
# --force:  overwrite ~/.tmux.conf and ~/.work.conf without prompting.

set -euo pipefail

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "This script is for the Linux dev VM. On macOS, run ./install-mac.sh instead." >&2
    exit 1
fi

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- ~/bin/work symlink -------------------------------------------------------
mkdir -p "$HOME/bin"
if [[ -e "$HOME/bin/work" && ! -L "$HOME/bin/work" ]]; then
    echo "~/bin/work exists and is not a symlink."
    if (( FORCE )); then
        rm -f "$HOME/bin/work"
    else
        read -r -p "Replace it with a symlink to $REPO_DIR/work? [y/N] " yn
        [[ "$yn" =~ ^[Yy] ]] || { echo "skipped."; exit 1; }
        rm -f "$HOME/bin/work"
    fi
fi
ln -sf "$REPO_DIR/work" "$HOME/bin/work"
echo "✓ symlinked ~/bin/work → $REPO_DIR/work"

# --- ~/.tmux.conf -------------------------------------------------------------
if [[ -e "$HOME/.tmux.conf" ]]; then
    if cmp -s "$HOME/.tmux.conf" "$REPO_DIR/tmux.conf"; then
        echo "✓ ~/.tmux.conf already up to date"
    elif (( FORCE )); then
        cp "$REPO_DIR/tmux.conf" "$HOME/.tmux.conf"
        echo "✓ overwrote ~/.tmux.conf"
    else
        echo "~/.tmux.conf exists and differs from this repo's version."
        read -r -p "Overwrite? (a backup will be made at ~/.tmux.conf.bak) [y/N] " yn
        if [[ "$yn" =~ ^[Yy] ]]; then
            cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
            cp "$REPO_DIR/tmux.conf" "$HOME/.tmux.conf"
            echo "✓ ~/.tmux.conf replaced (old saved to ~/.tmux.conf.bak)"
        else
            echo "skipped ~/.tmux.conf — note that pane border titles depend on it"
        fi
    fi
else
    cp "$REPO_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo "✓ wrote ~/.tmux.conf"
fi

# --- ~/.work.conf -------------------------------------------------------------
if [[ -e "$HOME/.work.conf" ]] && (( ! FORCE )); then
    echo "✓ ~/.work.conf already present — leaving as-is"
else
    cp "$REPO_DIR/work.conf.example" "$HOME/.work.conf"
    echo "✓ wrote ~/.work.conf (sample — edit it!)"
fi

# --- dependency check ---------------------------------------------------------
echo ""
echo "Dependency check:"
declare -A HINTS=(
    [tmux]="sudo apt-get install -y tmux"
    [ssh]="sudo apt-get install -y openssh-client"
    [lazygit]="https://github.com/jesseduffield/lazygit#installation"
    [claude]="npm install -g @anthropic-ai/claude-code"
    [codex]="npm install -g @openai/codex"
)
ANY_MISSING=0
for tool in tmux ssh lazygit claude codex; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "  ✓ %-10s %s\n" "$tool" "$(command -v "$tool")"
    else
        printf "  ✗ %-10s missing  →  %s\n" "$tool" "${HINTS[$tool]}"
        ANY_MISSING=1
    fi
done

echo ""
echo "Next steps:"
echo "  1. Edit ~/.work.conf and set WORK_REPO to your repo path."
echo "  2. On your Mac, run ./install-mac.sh to add the 'start' alias."
echo "  3. From the Mac, type 'start' to enter your workspace."
(( ANY_MISSING )) && echo ""
(( ANY_MISSING )) && echo "Some dependencies are missing; the relevant panes will show errors until they're installed."

exit 0
