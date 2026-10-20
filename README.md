# dotfiles

My portable terminal/dev environment. Linux (work + personal).
Managed with [GNU stow](https://www.gnu.org/software/stow/): the real config
files live here, stow symlinks them into place.

## Layout

```
dotfiles/
  Brewfile          # all CLI tools (brew bundle installs them)
  bootstrap.sh      # fresh-machine setup: installs tools + stows everything
  repos.json        # list of my git repos
  clone-repos.sh    # clones every repo in repos.json into ~/repos
  zsh/              # .zshrc, .zshenv, plugins.txt
  starship/         # prompt config
  codex/            # global Codex instructions (~/.codex/AGENTS.md)
  scripts/          # standalone command-line tools
```

Secrets and machine-specific env are **not** in this repo:

| File | What | In git? |
|------|------|---------|
| `~/.zsh_secrets` | passwords, API tokens | no (gitignored) |
| `~/.zsh_local`   | conda init, work paths, env vars | no (gitignored) |

## Set up on a new machine

On a **clean** machine:

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
./clone-repos.sh          # clone my repos into ~/repos
# then create ~/.zsh_secrets and ~/.zsh_local
exec zsh
```

If the machine **already has** shell/editor configs (the usual case), stow will
refuse to overwrite them — follow the backup-and-migrate steps in
**[SETUP.md](SETUP.md)**. It also covers migrating your old `~/.zshrc` env into
`~/.zsh_local`, the `neovim >= 0.11.2` requirement, and how to revert.

## Day-to-day: add / change a config

Files here are symlinked, so just edit them in `~/dotfiles/...` (or edit the
live file — it's the same file) and commit.

To deploy a package after adding one: `stow -t ~ <name>` from `~/dotfiles`.

Codex loads `~/.codex/AGENTS.md` at the start of each session. Edit
`codex/.codex/AGENTS.md` here to change your global preferences; deploy with
`stow --no-folding -t "$HOME" codex`. The root `AGENTS.md` links to `AGENT.md`
for instructions specific to this repository.

---

# Tool cheatsheet

The point of Phase 1. A few of these you just *feel* (they work passively);
a few have commands worth learning. Focus on the **bold** ones.

## Long jobs: poppi_pop

```bash
ln -s "$HOME/repos/dotfiles/scripts/poppi_pop" "$HOME/.local/bin/poppi_pop"
sudo -v                         # optional: permit highest normal CPU priority
poppi_pop --cpu 3 -- ./long-job --its-options
poppi_pop --cpu 3 --pid 12345     # watch an existing process
poppi_pop --cpu 3 --pid 12345 --log /path/to/job.log
```

Pins the command to CPU 3 (numbering starts at 0), requests nice `-20`, and
sends its exit code, duration and last 10 stdout lines to Telegram. Output
stays visible in the terminal; the wrapper returns the command's exit code.
Priority falls back with a warning if permission is denied. Commands run as
your user. Notification failure prints a warning and preserves the job's exit
code. Oversized output is shortened to fit Telegram's message limit.

PID mode applies priority and CPU affinity to the process's existing threads,
then waits for that process to end. Existing child processes are separate;
attach to the PID doing the work. Elapsed time starts at attachment and the
process's exit code is reported as unknown. It reads the last 10 lines only
when stdout is a readable regular file, or from an explicit `--log FILE`.
Terminal and pipe output cannot be recovered. Ctrl+C stops watching and leaves
the existing process running; priority and affinity changes remain in place.
PID mode returns 0 when monitoring finishes, rather than the target's exit code.

Requires Bash, curl, jq and Linux util-linux/coreutils. Keep the bot token in
`~/.config/poppi_pop/bot-token` and destination ID in
`~/.config/poppi_pop/chat-id` (or under `$XDG_CONFIG_HOME`). Use directory mode
`700` and file mode `600`. These files live outside the repository.
Send `/start` to the bot once. When `chat-id` is absent, the first run discovers
the bot's sole private chat; multiple chats require an explicit destination ID.
PID mode also requires `pidwait` from procps-ng.

Use `bash -c 'first-command | second-command'` for shell pipelines. The wrapper
runs in the foreground; use tmux to keep a job running after closing a terminal.

## Just works — nothing to learn

- **zsh-autosuggestions** — grey "ghost" text predicts your command from
  history as you type. Press **→ (right arrow)** to accept it.
- **zsh-syntax-highlighting** — commands turn green when valid, red when not.
- **starship** — the prompt. Shows folder, git branch + status, python/conda
  env, and how long slow commands took. Nothing to do.

## Shell history

- **↑ / ↓** browse recent commands.
- **Ctrl-R** searches normal zsh history inline.

## zoxide — jump to folders  ⭐ learn this one

Learns the folders you visit. Then:

- **`z qic`** → jumps to your most-used folder matching "qic", from anywhere.
- `z foo bar` → matches a path containing both.
- `zi` → interactive picker if you're not sure.
- Normal `cd` still works exactly as before.

## fzf-tab — fuzzy tab-completion

- Press **`Tab`** → instead of a plain list, you get a fuzzy menu.
  Type to filter, arrows to move, Enter to pick.

## eza — better `ls`

Aliased, so just use your normal commands:

- `ls` → colored, icons, folders first
- `ll` → long view with **git status** per file
- `la` → long view incl. hidden files
- `lt` → tree view, 2 levels deep

## bat — better `cat`

- `cat file.py` → syntax-highlighted, with line numbers. (Aliased.)
- `bat -A file` → show whitespace/invisible chars.

## fd — friendlier `find`

- `fd report` → find files/dirs matching "report" (fast, ignores .git).
- `fd -e py` → all `.py` files.
- `fd -H secret` → include hidden files.

## ripgrep (`rg`) — fast search inside files

- `rg TODO` → find "TODO" in all files under here.
- `rg -i error logs/` → case-insensitive search in a folder.

## delta — readable git diffs

Wired into git (it's the pager). `git diff` / `git show` / `git log -p` are now
colorful with line numbers. In a diff: `n` / `N` jump between changed sections.

## lazygit — git, visually  (`lg`)

- Run **`lg`** in a repo → a full terminal UI: stage with `space`, commit
  with `c`, push with `P`, see branches/log/diffs. `q` to quit, `?` for help.
  Optional — ignore it if you prefer the git CLI.

---

# tmux cheatsheet

Prefix is **`Ctrl-b`** (press it, release, then the key below).

## panes & windows
- `prefix "` split down · `prefix %` split right  (also `|` / `-`) — keep current folder
- `prefix h/j/k/l` move between panes (vim) · `prefix H/J/K/L` resize
- `prefix c` new window · `prefix n`/`p` next/prev window · `prefix 1..9` jump
- `prefix z` zoom pane fullscreen (toggle) · `prefix x` close pane
- Mouse: click panes, scroll, drag borders to resize

## scrollback (keyboard)
- `prefix [` enter scroll mode, then: `k`/`j` line, `Ctrl-u`/`Ctrl-d` half-page,
  `g`/`G` top/bottom, `/` search, `q` quit
- Copy: `v` start selection, `y` yank → system clipboard (works over SSH via OSC52)

## misc
- `prefix r` reload config · `prefix d` detach · `prefix ?` list all keys

Config is plugin-free, so it works the same on bare SSH servers.

---

# nvim

[LazyVim](https://lazyvim.org) distribution. Config lives here; `lazy-lock.json`
pins exact plugin versions (commit it so machines match).

- Leader = **Space** (same as the vscode vim setup).
- Theme: Catppuccin Mocha (matches terminal + tmux).
- Enabled language extras: python, docker, json, markdown, dotfiles + fzf finder
  + Claude Code. Manage these with `:LazyExtras`.
- Custom: autoformat off, python LSP = pyright + postgres_lsp (SQL), `gd` = go to
  definition, bufferline grouped by directory.
- First launch on a new machine: open `nvim`, plugins auto-install at locked versions.

---

# vscode

User `settings.json` + `keybindings.json` are tracked (stowed into
`~/.config/Code/User/`). Theme + font match the rest of the setup.

- Theme: **Catppuccin Mocha** (needs the `catppuccin.catppuccin-vsc` extension —
  `code --install-extension catppuccin.catppuccin-vsc`).
- Font: JetBrainsMono Nerd Font (editor + terminal), ligatures on.
- Vim keybindings via the `vscodevim` extension, leader = Space — mirror the core
  nvim motions (`S-h`/`S-l` buffers, `leader h/j/k/l` panes, etc).
- Note: a couple of settings hold **work-machine paths** (ansible/python
  interpreters). Harmless elsewhere; adjust per machine if needed.

## Omarchy machines

`./bootstrap.sh` detects Omarchy and uses `bootstrap-omarchy.sh` automatically.
It reuses installed commands and installs only missing tools with Homebrew.
In zsh, system commands take priority over duplicate Homebrew commands.
Existing Homebrew packages are left installed.

Existing config files are preserved: each Stow package with a conflict is
skipped, and zsh conflicts stop setup before changing Ghostty. Ghostty keeps
its Omarchy config and dynamic theme; setup backs it up as
`~/.config/ghostty/config.before-zsh.*` and appends the installed zsh path.
The login shell stays unchanged. Reload Ghostty with `Ctrl+Shift+,` and open
a new window. Omarchy's bash-specific aliases remain available in `bash`;
they are not sourced into zsh.

To undo the shell switch, restore the printed Ghostty backup and reload its
config. To unlink the zsh files, run `stow -D -t "$HOME" zsh` from this repo.
Do not use `stow --adopt` to resolve conflicts: review existing configs first.
