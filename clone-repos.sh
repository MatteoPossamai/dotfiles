#!/usr/bin/env bash
# Clone every repo listed in repos.json into ~/repos (skips ones already there).
#   ./clone-repos.sh            # uses ~/repos
#   ./clone-repos.sh ~/other    # custom target dir
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HOME/repos}"

command -v jq >/dev/null 2>&1 || { echo "jq not found (brew install jq)" >&2; exit 1; }
mkdir -p "$TARGET"

jq -r '.repos[]' "$DIR/repos.json" | while read -r url; do
  name="$(basename "$url" .git)"
  if [ -d "$TARGET/$name/.git" ]; then
    echo "skip  $name (already cloned)"
  else
    echo "clone $name"
    git clone --quiet "$url" "$TARGET/$name"
  fi
done

echo "Done. Repos live in $TARGET"
