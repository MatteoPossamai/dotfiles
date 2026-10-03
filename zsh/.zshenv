# ~/.zshenv — sourced for EVERY shell (incl. non-interactive). Keep it minimal.

# Omarchy's shared environment is shell-compatible; its bash rc is not.
if [ -r /usr/share/omarchy/default/bash/env-bootstrap ]; then
  . /usr/share/omarchy/default/bash/env-bootstrap
fi

# Rust/cargo (only if installed)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
