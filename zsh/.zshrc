# ~/.zshrc — interactive shell config (managed in ~/dotfiles, deployed via stow)
# Machine-specific stuff lives in ~/.zsh_local ; secrets in ~/.zsh_secrets (both gitignored)

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

# Homebrew (Linux). Sets PATH/MANPATH for brew-installed tools.
if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export PATH="$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------------------
# Completion (must run before fzf-tab loads)
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"

# ---------------------------------------------------------------------------
# Plugins (antidote) — autosuggestions, fzf-tab, syntax-highlighting
# ---------------------------------------------------------------------------
_antidote_src="$(brew --prefix antidote 2>/dev/null)/share/antidote/antidote.zsh"
if [ -f "$_antidote_src" ]; then
  source "$_antidote_src"
  antidote load "${HOME}/.config/zsh/plugins.txt"
fi
unset _antidote_src

# ---------------------------------------------------------------------------
# Tool initialisation
# ---------------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"      # prompt
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"        # z (smart cd)
command -v fzf      >/dev/null && source <(fzf --zsh) 2>/dev/null  # fzf: Ctrl-T, Alt-C
command -v atuin    >/dev/null && eval "$(atuin init zsh)"         # atuin LAST so it owns Ctrl-R

# ---------------------------------------------------------------------------
# Aliases — modern CLI replacements (interactive only; scripts unaffected)
# ---------------------------------------------------------------------------
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l  --icons --git --group-directories-first'
  alias la='eza -la --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
fi
command -v bat   >/dev/null && alias cat='bat --paging=never'
command -v lazygit >/dev/null && alias lg='lazygit'

# ---------------------------------------------------------------------------
# History (atuin owns search; keep a sane file-based history too)
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# ---------------------------------------------------------------------------
# Machine-local config + secrets (NOT in git)
# ---------------------------------------------------------------------------
[ -f "$HOME/.zsh_local"   ] && source "$HOME/.zsh_local"
[ -f "$HOME/.zsh_secrets" ] && source "$HOME/.zsh_secrets"

unset LOCPATH
