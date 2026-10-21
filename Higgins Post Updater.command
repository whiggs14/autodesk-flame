#!/bin/bash
# Higgins Post native plugins for Flame - double-click to install, update or remove them (macOS).
# Fetches the current updater from GitHub and runs it; it looks at the published releases and compares them with what is installed.
cd "$HOME" || exit 1
T="$(mktemp -d)"
curl -fsSL "https://raw.githubusercontent.com/whiggs14/autodesk-flame/main/hp-update.sh" -o "$T/hp-update.sh" \
  || { echo "Could not download the updater (internet?)."; read -r -p "Press Return to close."; exit 1; }
bash "$T/hp-update.sh" "$@"
rm -rf "$T"
echo; read -r -p "Press Return to close."
