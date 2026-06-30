#!/usr/bin/env bash
# Set up this dotfiles repo on a fresh (Linux) machine.
#   ./bootstrap.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGES="zsh starship atuin tmux ghostty nvim vscode git"

# 1. Homebrew must exist (https://brew.sh)
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install it first: https://brew.sh" >&2
  exit 1
fi

# 2. Install all CLI tools
brew bundle --file="$DIR/Brewfile"

# 3. Install JetBrainsMono Nerd Font (brew casks don't work on Linux)
install_font() {
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    echo "JetBrainsMono Nerd Font already installed."
    return
  fi
  echo "Installing JetBrainsMono Nerd Font..."
  local fdir="$HOME/.local/share/fonts" tmp
  tmp="$(mktemp -d)"
  mkdir -p "$fdir"
  curl -fsSL -o "$tmp/JBM.zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -oq "$tmp/JBM.zip" -d "$fdir"
  fc-cache -f "$fdir" >/dev/null
  rm -rf "$tmp"
  echo "Font installed."
}
install_font

# 4. Symlink configs into place
cd "$DIR"
stow -v -t "$HOME" $PACKAGES

cat <<'EOF'

Done. Next:
  1. Restart your shell (or: exec zsh)
  2. Create ~/.zsh_secrets  for passwords/tokens          (gitignored)
  3. Create ~/.zsh_local    for machine-specific env       (gitignored)
  4. vscode theme:  code --install-extension catppuccin.catppuccin-vsc
  5. If conda present:  conda config --set changeps1 false
EOF
