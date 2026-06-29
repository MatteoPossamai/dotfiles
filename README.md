# dotfiles

My portable terminal/dev environment. Linux (work + personal).
Managed with [GNU stow](https://www.gnu.org/software/stow/): the real config
files live here, stow symlinks them into place.

## Layout

```
dotfiles/
  Brewfile          # all CLI tools (brew bundle installs them)
  bootstrap.sh      # fresh-machine setup: installs tools + stows everything
  zsh/              # .zshrc, .zshenv, plugins.txt
  starship/         # prompt config
  atuin/            # history config
```

Secrets and machine-specific env are **not** in this repo:

| File | What | In git? |
|------|------|---------|
| `~/.zsh_secrets` | passwords, API tokens | no (gitignored) |
| `~/.zsh_local`   | conda init, work paths, env vars | no (gitignored) |

## Set up on a new machine

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
# then create ~/.zsh_secrets and ~/.zsh_local
exec zsh
```

## Day-to-day: add / change a config

Files here are symlinked, so just edit them in `~/dotfiles/...` (or edit the
live file — it's the same file) and commit.

To deploy a package after adding one: `stow -t ~ <name>` from `~/dotfiles`.

---

# Tool cheatsheet

The point of Phase 1. A few of these you just *feel* (they work passively);
a few have commands worth learning. Focus on the **bold** ones.

## Just works — nothing to learn

- **zsh-autosuggestions** — grey "ghost" text predicts your command from
  history as you type. Press **→ (right arrow)** to accept it.
- **zsh-syntax-highlighting** — commands turn green when valid, red when not.
- **starship** — the prompt. Shows folder, git branch + status, python/conda
  env, and how long slow commands took. Nothing to do.

## atuin — better history  ⭐ learn this one

- **`Ctrl-R`** → opens a searchable, full-screen list of every command you've
  run. Type to filter, ↑/↓ to pick, **Enter** to put it on your line
  (it won't auto-run — you press Enter again).
- `Esc` to cancel.

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

Will be wired into git in a later phase. Makes `git diff` / `git show`
side-by-side and colorful.

## lazygit — git, visually  (`lg`)

- Run **`lg`** in a repo → a full terminal UI: stage with `space`, commit
  with `c`, push with `P`, see branches/log/diffs. `q` to quit, `?` for help.
  Optional — ignore it if you prefer the git CLI.
