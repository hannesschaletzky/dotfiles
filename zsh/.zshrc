# https://github.com/hannesschaletzky/dotfiles
# ~/.zshrc ist ein Symlink hierher. Rechnerspezifisches und Kundenprojekte stehen in ~/.zshrc.local.

# Ordner dieses Repos, über den Symlink aufgelöst
DOTFILES="${${(%):-%x}:A:h:h}"

export PATH="$HOME/bin:/usr/local/bin:$HOME/.yarn/bin:$PATH"

# --- oh-my-zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto
plugins=(git gitfast last-working-dir common-aliases alias-finder history-substring-search)
source "$ZSH/oh-my-zsh.sh"

# --- Node über nodenv ---
export PATH="$HOME/.nodenv/bin:$PATH"
command -v nodenv >/dev/null && eval "$(nodenv init - zsh)"

# Postman CLI und andere Tools in ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

source "$DOTFILES/zsh/aliases.zsh"
source "$DOTFILES/zsh/functions.zsh"

# Rechnerspezifisches und Kundenprojekte, nicht im Repo
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
