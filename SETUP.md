# SETUP — installing these dotfiles on a machine

Linux only. Real config files live in this repo; [GNU stow](https://www.gnu.org/software/stow/)
symlinks them into `$HOME`. Secrets and machine-specific env stay **out** of the
repo (`~/.zsh_secrets`, `~/.zsh_local`).

There are two paths below. Pick one:

- **A. Clean machine** — no existing shell/editor config. Just run `bootstrap.sh`.
- **B. Machine that already has configs** — the common case. `stow` refuses to
  overwrite real files, so you back them up first, then stow.

---

## Prerequisites

- **Homebrew** (Linux): https://brew.sh — everything else installs through it.
- **zsh**: `command -v zsh` should print a path (e.g. `/usr/bin/zsh`).
  Note: on these machines the *login* shell may still be bash (`/etc/passwd`);
  the terminal (ghostty) forces zsh. That's fine.
- **git over HTTPS** (work firewall blocks SSH port 22): use the `gh` CLI as the
  credential helper — `gh auth login` on github.com. `origin` is HTTPS.

Clone the repo:

```bash
git clone https://github.com/MatteoPossamai/dev_tools.git ~/dotfiles
cd ~/dotfiles
```

---

## A. Clean machine

```bash
./bootstrap.sh
```

That runs `brew bundle` (installs stow + all CLI tools), installs the
JetBrainsMono Nerd Font, and `stow`s every package into `$HOME`. Then jump to
[Post-setup](#post-setup-do-these-by-hand).

If `stow` errors with *"existing target is not a symlink"*, you're actually on
path B — go there.

---

## B. Machine that already has configs

`stow` will not clobber real files. These are the paths this repo owns; any that
already exist as **real** files/dirs must be backed up and removed first:

| Package  | Targets it links |
|----------|------------------|
| zsh      | `~/.zshrc` `~/.zshenv` `~/.config/zsh/` |
| starship | `~/.config/starship.toml` |
| atuin    | `~/.config/atuin/` |
| tmux     | `~/.tmux.conf` |
| ghostty  | `~/.config/ghostty/` |
| nvim     | `~/.config/nvim/` |
| vscode   | `~/.config/Code/User/{settings,keybindings}.json` |
| claude   | `~/.claude/settings.json` `~/.claude/CLAUDE.md` |

### 1. Install the tools

```bash
brew bundle --file=~/dotfiles/Brewfile
```

`neovim >= 0.11.2` is required (the `nvim` package is LazyVim). It's in the
Brewfile; if an older one is already installed, `brew upgrade neovim`.

### 2. Back up what's there

```bash
BK=~/.dotfiles-backup-$(date +%Y%m%d-%H%M%S); mkdir -p "$BK/.config/Code/User"
cp -a ~/.zshrc ~/.zshenv "$BK/" 2>/dev/null
cp -a ~/.config/nvim ~/.config/ghostty "$BK/.config/" 2>/dev/null
cp -a ~/.config/Code/User/{settings,keybindings}.json "$BK/.config/Code/User/" 2>/dev/null
cp -a ~/.claude/settings.json "$BK/claude-settings.json" 2>/dev/null
echo "backed up to $BK"
```

### 3. Migrate machine-specific env  ← don't skip this

The old `~/.zshrc` usually holds PATH additions, conda activation, language
managers (nvm, go, modular), work aliases, etc. The new `~/.zshrc` does **not**
carry those — they belong in `~/.zsh_local` (gitignored). Open your backed-up
`~/.zshrc` and move anything machine-specific into `~/.zsh_local`.

**Leave out** what the repo `~/.zshrc` already does: `$HOME/bin`, `~/.local/bin`,
`~/.npm-global/bin`, Homebrew `shellenv`, `~/.cargo/bin`, and oh-my-zsh (antidote
replaces it). See `~/.zsh_local` on this machine for a worked example.

Create the two gitignored files (start `~/.zsh_secrets` empty unless the old
config had tokens/passwords):

```bash
: > ~/.zsh_secrets && chmod 600 ~/.zsh_secrets   # add exports here later
# ~/.zsh_local: paste the migrated machine env, then: chmod 600 ~/.zsh_local
```

### 4. Remove the conflicts and stow

```bash
rm -f  ~/.zshrc ~/.zshenv
rm -rf ~/.config/nvim ~/.config/ghostty
rm -f  ~/.config/Code/User/{settings,keybindings}.json
rm -f  ~/.claude/settings.json          # claude: do this one last (see note)
cd ~/dotfiles
stow -v -t ~ zsh starship atuin tmux ghostty nvim vscode
stow -v -t ~ claude                     # last — see note
```

> **claude package note:** it replaces `~/.claude/settings.json`, which switches
> Claude Code's permission mode (e.g. `bypassPermissions` → `auto`). If you're
> running Claude Code *while* setting up, do this package last so it doesn't
> interrupt the rest of the setup.

---

## Post-setup (do these by hand)

```bash
exec zsh                                              # reload the shell
code --install-extension catppuccin.catppuccin-vsc    # vscode theme
conda config --set changeps1 false                    # if conda present (starship owns the prompt)
git config --global user.name  "Your Name"            # git identity is NOT tracked here
git config --global user.email "you@example.com"
```

## Verify it worked

```bash
zsh -i -c 'echo ok'                       # loads clean (antidote clones plugins on first run)
zsh -i -c 'alias ls; command -v starship atuin zoxide eza bat fd rg delta lazygit'
nvim --headless "+Lazy! sync" +qa         # nvim plugins install
tmux -L t -f ~/.tmux.conf new -d 'sleep 1' && tmux -L t kill-server   # tmux config parses
readlink ~/.zshrc                         # should point into dotfiles/
```

## Day-to-day

Files are symlinks, so editing `~/dotfiles/<pkg>/...` **is** editing the live
config. After adding a *new* file/package: `cd ~/dotfiles && stow -t ~ <pkg>`.

## Reverting

Everything you replaced is in the `~/.dotfiles-backup-*` folder. To undo a
package: `cd ~/dotfiles && stow -D -t ~ <pkg>`, then copy the originals back.
