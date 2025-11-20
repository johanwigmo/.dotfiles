[[ $- != *i* ]] && return 

setopt autocd
setopt correct 
setopt interactivecomments
setopt nobeep

# Install zinit if not present
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then 
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Load plugins 
zinit light marlonrichert/zsh-autocomplete
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions

# Initialize starship prompt
eval "$(starship init zsh)"

# Aliases 
alias glog="git log --oneline --decorate --graph --all"
alias v="nvim"
alias cat="bat"
alias ls="eza --icons"
alias ll="eza -lh --icons"
alias la="eza -lha --icons"
alias tree="eza --tree"

# Zoxide (better cd)
eval "$(zoxide init zsh)"
alias cd="z"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVIM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/nvm.config.d/bash_completion" ] && \. "$NVM_DIR/nvm.config.d/bash_completion"

# Android 
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

# Java
export JAVA_HOME="$(
	/usr/libexec/java_home 2>/dev/null || true
)"

# FZF
eval "$(fzf --zsh)"

autoload -Uz compinit
compinit

