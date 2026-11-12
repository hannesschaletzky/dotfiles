#!/usr/bin/env bash
# Verlinkt die Dateien dieses Repos ins Home-Verzeichnis.
# Vorhandene Dateien werden nach ~/.dotfiles-backup/<Zeitpunkt>/ verschoben, nicht gelöscht.
# Mehrfach ausführbar: bereits richtig gesetzte Links bleiben unverändert.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
VSCODE="$HOME/Library/Application Support/Code/User"

link() {
  local src="$DOTFILES/$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "ok      $dst"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/"
    echo "backup  $dst -> $BACKUP/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "link    $dst"
}

link zsh/.zshrc             "$HOME/.zshrc"
link zsh/.zprofile          "$HOME/.zprofile"
link git/.gitconfig         "$HOME/.gitconfig"
link git/.gitignore_global  "$HOME/.gitignore_global"
link ssh/config             "$HOME/.ssh/config"
link vscode/settings.json    "$VSCODE/settings.json"
link vscode/keybindings.json "$VSCODE/keybindings.json"
link vscode/snippets         "$VSCODE/snippets"

# Lokale Dateien für Rechnerspezifisches anlegen, falls sie fehlen (bleiben außerhalb des Repos)
for f in "$HOME/.zshrc.local" "$HOME/.ssh/config.local" "$HOME/.gitconfig.local"; do
  [[ -e "$f" ]] || { touch "$f"; chmod 600 "$f"; echo "neu     $f"; }
done

# Schutz-Hook gegen versehentlich committete Zugangsdaten
git -C "$DOTFILES" config core.hooksPath .githooks

echo
echo "Fertig. Pakete und VS-Code-Extensions installieren: brew bundle --file=\"$DOTFILES/Brewfile\""
