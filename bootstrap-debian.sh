#!/usr/bin/env bash
# Terminal-only Debian setup. Run as the account whose dotfiles should be installed.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set_shell=false
case "${1:-}" in
  --set-shell) set_shell=true ;;
  '') ;;
  *) echo "Usage: $0 [--set-shell]" >&2; exit 2 ;;
esac
. /etc/os-release
if [[ "$ID" != debian || "${VERSION_ID%%.*}" -lt 13 ]]; then
  echo 'Requires Debian 13 or newer.' >&2
  exit 1
fi
case "$(uname -m)" in
  x86_64) arch=x86_64; ts_arch=x64; star_arch=x86_64
    nvim_sha=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
    star_sha=10c8eb4cb3b761d9bf59ea828444c2dab36c900b7d69a69e08814b286969df89
    lazygit_sha=0a23f429a95f0d09db298b3c291536d818de066aa5a85c255806f0490ff6656b
    ts_sha=7ed56d152c52437397b9fcaa43cf341f49933cecc1ca291843f0d347c6e2cb3a ;;
  aarch64) arch=arm64; ts_arch=arm64; star_arch=aarch64
    nvim_sha=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815
    star_sha=341f5cbf24699fa0b27ec88965ad25f862ea09e15d35a543fd6ffdff1d2aa00d
    lazygit_sha=ac0b48237f3d0283813e7154ec063237e519532feb0470c0881a1793ee78fd42
    ts_sha=34fcc5c4fa7bdd2058a2a45a03b6eb9a49b03a93b6d52ec750f99b1516d98d33 ;;
  *) echo 'Supported architectures: x86_64, aarch64.' >&2; exit 1 ;;
esac
mkdir -p "$HOME/.cache"
exec 9>"$HOME/.cache/dotfiles-bootstrap.lock"
flock -n 9 || { echo 'Another dotfiles setup is already running.' >&2; exit 1; }
privilege=()
if ((EUID != 0)); then privilege=(sudo); fi
"${privilege[@]}" apt-get update
"${privilege[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl git openssh-client less stow zsh tmux unzip xz-utils build-essential clang cmake \
  pkg-config ripgrep fd-find bat fzf zoxide eza git-delta jq nodejs npm python3-venv locales
if jq -e '.extras | index("lazyvim.plugins.extras.lang.rust") != null' \
  "$DIR/nvim/.config/nvim/lazyvim.json" >/dev/null; then
  "${privilege[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cargo rustfmt rust-clippy rust-src
fi

export PATH="$HOME/.local/bin:$PATH"
# Bound compiler parallelism on small machines, including parser builds.
export CMAKE_BUILD_PARALLEL_LEVEL=1 MAKEFLAGS=-j1 CARGO_BUILD_JOBS=1
export LANG=C.UTF-8
mkdir -p "$HOME/.local/bin" "$HOME/.local/opt" "$HOME/.local/share" "$HOME/.config"
tmp="$(mktemp -d)"
setup_swap=''
cleanup() {
  if [[ -n "$setup_swap" ]]; then
    if "${privilege[@]}" swapon --show=NAME --noheadings | grep -Fxq "$setup_swap"; then
      "${privilege[@]}" swapoff "$setup_swap" || return
    fi
    "${privilege[@]}" rm -- "$setup_swap"
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT
# Official Tailscale apt repository. Account sign-in remains an explicit step.
curl -fsSL "https://pkgs.tailscale.com/stable/debian/$VERSION_CODENAME.noarmor.gpg" -o "$tmp/tailscale.gpg"
curl -fsSL "https://pkgs.tailscale.com/stable/debian/$VERSION_CODENAME.tailscale-keyring.list" -o "$tmp/tailscale.list"
"${privilege[@]}" install -m 644 "$tmp/tailscale.gpg" /usr/share/keyrings/tailscale-archive-keyring.gpg
"${privilege[@]}" install -m 644 "$tmp/tailscale.list" /etc/apt/sources.list.d/tailscale.list
"${privilege[@]}" apt-get update
"${privilege[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tailscale
"${privilege[@]}" systemctl enable --now tailscaled
# Protect SSH on small VMs while compiling parsers. Remove this swap on exit.
if awk '/MemTotal:/ {m=$2} /SwapTotal:/ {s=$2} END {exit !(m<1572864 && s<524288)}' /proc/meminfo; then
  echo 'Using 1 GiB temporary swap during setup on this small machine.'
  setup_swap="$("${privilege[@]}" mktemp /var/tmp/dotfiles-swap.XXXXXX)"
  "${privilege[@]}" chmod 600 "$setup_swap"
  "${privilege[@]}" dd if=/dev/zero of="$setup_swap" bs=1M count=1024 status=none
  "${privilege[@]}" mkswap "$setup_swap"
  "${privilege[@]}" swapon "$setup_swap"
fi
download() {
  curl --fail --location --retry 3 --silent --show-error "$1" -o "$tmp/archive"
  printf '%s  %s\n' "$2" "$tmp/archive" | sha256sum --check --status
}

# Pinned upstream binaries with SHA256 checksums. No Homebrew or source builds.
nvim_dir="$HOME/.local/opt/nvim-0.12.6"
if [[ ! -x "$nvim_dir/bin/nvim" ]]; then
  download "https://github.com/neovim/neovim/releases/download/v0.12.6/nvim-linux-$arch.tar.gz" "$nvim_sha"
  mkdir -p "$tmp/nvim"
  tar -xzf "$tmp/archive" -C "$tmp/nvim" --strip-components=1
  mv "$tmp/nvim" "$nvim_dir"
fi
ln -sfn "$nvim_dir/bin/nvim" "$HOME/.local/bin/nvim"
if [[ ! -x "$HOME/.local/opt/starship-1.27.0/starship" ]]; then
  download "https://github.com/starship/starship/releases/download/v1.27.0/starship-$star_arch-unknown-linux-musl.tar.gz" "$star_sha"
  mkdir -p "$HOME/.local/opt/starship-1.27.0"
  tar -xzf "$tmp/archive" -C "$HOME/.local/opt/starship-1.27.0" starship
fi
ln -sfn "$HOME/.local/opt/starship-1.27.0/starship" "$HOME/.local/bin/starship"
if [[ ! -x "$HOME/.local/opt/lazygit-0.66.3/lazygit" ]]; then
  download "https://github.com/jesseduffield/lazygit/releases/download/v0.66.3/lazygit_0.66.3_linux_$arch.tar.gz" "$lazygit_sha"
  mkdir -p "$HOME/.local/opt/lazygit-0.66.3"
  tar -xzf "$tmp/archive" -C "$HOME/.local/opt/lazygit-0.66.3" lazygit
fi
ln -sfn "$HOME/.local/opt/lazygit-0.66.3/lazygit" "$HOME/.local/bin/lazygit"
if [[ ! -x "$HOME/.local/opt/tree-sitter-0.27.2" ]]; then
  download "https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.2/tree-sitter-linux-$ts_arch.gz" "$ts_sha"
  gzip -dc "$tmp/archive" > "$tmp/tree-sitter"
  install -m 755 "$tmp/tree-sitter" "$HOME/.local/opt/tree-sitter-0.27.2"
fi
ln -sfn "$HOME/.local/opt/tree-sitter-0.27.2" "$HOME/.local/bin/tree-sitter"
ln -sfn /usr/bin/batcat "$HOME/.local/bin/bat"
ln -sfn /usr/bin/fdfind "$HOME/.local/bin/fd"
if [[ ! -d "$HOME/.local/share/antidote" ]]; then
  git clone --depth 1 --branch v2.3.0 https://github.com/mattmc3/antidote.git "$HOME/.local/share/antidote"
fi

# Refuse conflicts before linking any package. Never adopt or overwrite configs.
packages=(zsh starship tmux nvim)
stow --simulate --no-folding -d "$DIR" -t "$HOME" "${packages[@]}"
stow --no-folding -d "$DIR" -t "$HOME" "${packages[@]}"
for local_file in .zsh_local .zsh_secrets; do
  if [[ ! -e "$HOME/$local_file" ]]; then
    (umask 077; touch "$HOME/$local_file")
  fi
done

zsh -i -c 'for tool in nvim starship zoxide eza bat fd rg delta lazygit fzf tree-sitter tmux; do command -v "$tool" || exit 1; done; (( ${+functions[antidote]} ))'
# Restore committed plugin versions rather than upgrading the lockfile.
lazy_dir="$HOME/.local/share/nvim/lazy/lazy.nvim"
lazy_commit="$(jq -er '.["lazy.nvim"].commit' "$DIR/nvim/.config/nvim/lazy-lock.json")"
if [[ ! -d "$lazy_dir/.git" ]]; then
  git init -q "$tmp/lazy.nvim"
  git -C "$tmp/lazy.nvim" remote add origin https://github.com/folke/lazy.nvim.git
  git -C "$tmp/lazy.nvim" fetch --depth 1 origin "$lazy_commit"
  git -C "$tmp/lazy.nvim" checkout -q --detach "$lazy_commit"
  mkdir -p "$(dirname "$lazy_dir")"
  mv -T "$tmp/lazy.nvim" "$lazy_dir"
elif [[ "$(git -C "$lazy_dir" rev-parse HEAD)" != "$lazy_commit" ]]; then
  git -C "$lazy_dir" fetch --depth 1 origin "$lazy_commit"
  git -C "$lazy_dir" checkout --detach "$lazy_commit"
fi
XDG_CACHE_HOME="$tmp/cache" timeout 30m nvim --headless -u "$DIR/scripts/debian-nvim-init.lua" \
  "+luafile $DIR/scripts/debian-nvim-restore.lua"
XDG_CACHE_HOME="$tmp/cache" timeout 45m nvim --headless -u "$DIR/scripts/debian-nvim-init.lua" \
  "+luafile $DIR/scripts/debian-nvim-setup.lua"
# A separate tmux socket avoids changing any existing sessions.
socket="dotfiles-check-$$"
tmux -L "$socket" -f "$HOME/.tmux.conf" new-session -d
tmux -L "$socket" kill-server
if $set_shell; then
  "${privilege[@]}" chsh -s /usr/bin/zsh "$(id -un)"
fi
echo 'Done: terminal dotfiles, shell tools, Neovim plugins and language tools installed.'
echo 'Open a new SSH session, or run: exec zsh'
echo 'To connect Tailscale to your account, run: sudo tailscale up (root: tailscale up)'
