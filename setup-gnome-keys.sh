#!/usr/bin/env bash
# GNOME custom keyboard shortcuts (run once per machine):
#   Alt+T  -> new ghostty window
#   Alt+B  -> google chrome
# NOTE: overwrites the custom-keybindings LIST. If the machine already has
# custom shortcuts, merge manually instead of running this.
set -euo pipefail

BASE="org.gnome.settings-daemon.plugins.media-keys"
KEYPATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

bind() { # index  name  command  binding
  local p="$KEYPATH/custom$1/"
  gsettings set "$BASE.custom-keybinding:$p" name    "$2"
  gsettings set "$BASE.custom-keybinding:$p" command "$3"
  gsettings set "$BASE.custom-keybinding:$p" binding "$4"
}

bind 0 "New terminal" "ghostty"       "<Alt>t"
bind 1 "Browser"      "google-chrome" "<Alt>b"

gsettings set "$BASE" custom-keybindings "['$KEYPATH/custom0/', '$KEYPATH/custom1/']"
echo "Done: Alt+T -> ghostty, Alt+B -> chrome"
