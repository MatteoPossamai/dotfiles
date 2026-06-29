#!/usr/bin/env bash
# Set up this dotfiles repo on a fresh (Linux) machine.
#   ./bootstrap.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Homebrew must exist (https://brew.sh)
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install it first: https://brew.sh" >&2
  exit 1
fi

# 2. Install all CLI tools
brew bundle --file="$DIR/Brewfile"

# 3. Symlink configs into place
cd "$DIR"
stow -v -t "$HOME" zsh starship atuin

cat <<'EOF'

Done. Next:
  1. Restart your shell (or: exec zsh)
  2. Create ~/.zsh_secrets  for passwords/tokens   (gitignored)
  3. Create ~/.zsh_local    for machine-specific env (conda, paths)  (gitignored)
EOF
