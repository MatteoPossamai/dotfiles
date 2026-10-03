#!/usr/bin/env bash
# Add the portable shell tools without replacing Omarchy's existing configs.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH:/home/linuxbrew/.linuxbrew/bin"

if ! command -v brew >/dev/null; then
  echo 'Homebrew is required for missing tools: https://brew.sh' >&2
  exit 1
fi

# Reuse any command already available, including distro-provided tools.
missing=()
while read -r formula executable; do
  command -v "$executable" >/dev/null || missing+=("$formula")
done <<'EOF'
zsh zsh
stow stow
starship starship
zoxide zoxide
fzf fzf
bat bat
eza eza
fd fd
ripgrep rg
git-delta delta
lazygit lazygit
neovim nvim
jq jq
EOF
brew list --versions antidote >/dev/null 2>&1 || missing+=(antidote)
if ((${#missing[@]})); then
  brew install "${missing[@]}"
fi

# Stow never adopts or overwrites existing files. Skip a whole package on conflict.
for package in zsh starship tmux nvim vscode claude codex; do
  if stow --simulate --no-folding -d "$DIR" -t "$HOME" "$package"; then
    stow --no-folding -d "$DIR" -t "$HOME" "$package"
  else
    echo "Preserving existing config: skipped $package."
    if [[ "$package" == zsh ]]; then
      echo 'Resolve the zsh config conflict before switching Ghostty.' >&2
      exit 1
    fi
  fi
done

# Keep the live Omarchy Ghostty config (including its dynamic theme include).
config="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
shell_command="command = $(command -v zsh)"
mkdir -p "$(dirname "$config")"
if [[ ! -f "$config" ]] || ! grep -Fxq "$shell_command" "$config"; then
  if [[ -e "$config" || -L "$config" ]]; then
    if [[ -L "$config" ]]; then
      echo "Refusing to modify symlinked Ghostty config: $config" >&2
      exit 1
    fi
    backup="$(mktemp "${config}.before-zsh.XXXXXX")"
    cp -p "$config" "$backup"
    echo "Ghostty backup: $backup"
  fi
  printf '\n# Shell selected by dotfiles; keep Omarchy appearance and integration.\n%s\n' "$shell_command" >> "$config"
fi
echo 'Done. Reload Ghostty config (Ctrl+Shift+,), then open a new window for zsh.'
echo 'Existing bash/login shell and installed packages are preserved.'
