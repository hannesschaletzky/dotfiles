# dotfiles

My macOS setup: zsh with oh-my-zsh, Git, SSH, VS Code and everything installed via Homebrew.

```
zsh/       .zshrc, .zprofile, aliases.zsh, functions.zsh
git/       .gitconfig, .gitignore_global
ssh/       config (GitHub only, includes ~/.ssh/config.local)
vscode/    settings.json, keybindings.json, snippets/
Brewfile   Homebrew formulae, casks and VS Code extensions
```

## Setup on a new Mac

```sh
# 1. Homebrew and oh-my-zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2. Link everything into $HOME (existing files are moved to ~/.dotfiles-backup/)
git clone git@github.com:hannesschaletzky/dotfiles.git ~/repos/01_private/dotfiles
~/repos/01_private/dotfiles/install.sh

# 3. Packages and VS Code extensions
brew bundle --file=~/repos/01_private/dotfiles/Brewfile
```

## Private parts stay local

The files are symlinked, so edits to `~/.zshrc` and friends land directly in this repo. Anything machine- or
client-specific goes into files that are **not** part of the repo and are loaded automatically if present:

| File | For |
| --- | --- |
| `~/.zshrc.local` | tokens, client scripts, AWS profiles |
| `~/.ssh/config.local` | own servers and client hosts |
| `~/.gitconfig.local` | e.g. a different email for client repos |

A pre-commit hook (`.githooks/`, enabled by `install.sh`) blocks commits that look like credentials or AWS account
IDs.

## Keeping the Brewfile current

```sh
brew bundle dump --file=Brewfile --force
```
