# AGENT.md — context for AI assistants working on this repo

This is **Matteo's dotfiles** — a portable terminal/dev environment. Read this
before changing anything. `CLAUDE.md` is a symlink to this file.

## What this is

Personal dotfiles for **Linux only** (work + personal machines). Managed with
**GNU stow** (real files live here, symlinked into `$HOME`). Tools installed via
**Homebrew** (`Brewfile`). Built in phases; all five are done.

## Hard rules (do not violate)

- **Secrets never enter the repo.** They live in `~/.zsh_secrets` (gitignored).
  Machine/work-specific env lives in `~/.zsh_local` (gitignored). The repo only
  holds the `source` lines. If you find a secret in a tracked file, stop.
- **Don't commit after every small tweak.** Iterate uncommitted; make ONE clean,
  squashed commit per phase/change. Ask before committing if unsure.
- **Linux only.** No macOS/Windows branches. Keep configs simple, no OS templating.
- **Lean over clever.** Owner prefers minimal, readable config over feature bloat.
  When in doubt, do less. Explain plainly (owner self-describes as preferring
  slow, clear, one-step-at-a-time pacing).

## Conventions

- **Theme everywhere:** Catppuccin Mocha. **Font everywhere:** JetBrainsMono Nerd Font.
  Keep any new tool consistent with these.
- **Editor parity (nvim ↔ vscode):** best-effort, cheap only (leader=Space, theme,
  font, core motions). NO custom glue/plugins to force parity.
- One stow package per tool. Files mirror their real `$HOME` path inside the package
  (e.g. `zsh/.config/zsh/...` → `~/.config/zsh/...`).

## Repo structure

```
zsh/      .zshrc .zshenv .config/zsh/plugins.txt   (antidote plugins)
starship/ .config/starship.toml                    (prompt)
atuin/    .config/atuin/config.toml                (history)
tmux/     .tmux.conf                               (plugin-free, server-safe)
ghostty/  .config/ghostty/config                   (terminal)
nvim/     .config/nvim/...                         (LazyVim; lazy-lock.json pins versions)
vscode/   .config/Code/User/{settings,keybindings}.json
Brewfile  bootstrap.sh  README.md (user cheatsheet)  AGENT.md (this)
```

## How to change a config

Files are symlinked, so editing `~/dotfiles/<pkg>/...` IS editing the live file.
After adding a NEW file/package: `cd ~/dotfiles && stow -t ~ <pkg>`.
Test before claiming success (e.g. `zsh -i -c ...`, `tmux -L test -f <conf> ...`,
`nvim --headless ... +qa`). Then squash-commit the phase.

## Stack (what's installed) — see Brewfile

zsh (antidote replaces oh-my-zsh; plugins: zsh-autosuggestions, fzf-tab,
zsh-syntax-highlighting), starship, atuin (Ctrl-R), zoxide (z), fzf, bat, eza,
fd, ripgrep, git-delta, lazygit, stow.

## Machine gotchas (IMPORTANT)

- **Login shell is bash** (`/etc/passwd`) even though `$SHELL=/bin/zsh`. So
  ghostty forces zsh via `command = /usr/bin/zsh`. Don't assume zsh is login shell.
- **Work firewall blocks SSH port 22** to github.com. Pushing uses **HTTPS via the
  `gh` credential helper** (gh logged in as MatteoPossamai on github.com; also
  logged into gitboe.bbl-internal.com for work). Remote `origin` is HTTPS, branch
  **main**. SSH-over-443 (`ssh.github.com`) is the alt route if ever needed.
- nvim was NOT a separate git repo; it's tracked here now. `lazy-lock.json` is
  committed for reproducible plugin versions.
- conda's own prompt is disabled (`conda config --set changeps1 false`, in
  `~/.condarc`, not the repo) so starship owns the prompt.

## New-machine setup

```
git clone https://github.com/MatteoPossamai/dev_tools.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh          # brew bundle + stow
# then, by hand:
#   create ~/.zsh_secrets and ~/.zsh_local
#   code --install-extension catppuccin.catppuccin-vsc
#   conda config --set changeps1 false   (if conda present)
```

## Outstanding / ideas for future iterations

- **Owner action (security):** rotate secrets that were once plaintext in the old
  `~/.zshrc` and shell history (DB pw, Confluence/Influx tokens, Nexus key).
- Possible future polish (only if owner asks): tmux session save/restore (tpm +
  resurrect/continuum), shell abbreviations, git aliases (owner didn't want omz's),
  fzf-tab previews, a unified Catppuccin theme generator.
- Keep README.md (the human cheatsheet) updated when adding a tool.
