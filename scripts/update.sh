#!/usr/bin/env bash
set -euo pipefail

echo "Updating dotfiles"
cd "$HOME/.dotfiles"
git pull

echo "Re-stowing configurations"
stow -R zsh
stow -R starship
stow -R tmux
stow -R git
stow -R nvim
stow -R zed
stow -R ghostty
stow -R aerospace

echo "Updating Homebrew..."
brew update && brew upgrade && brew cleanup

echo "Updating TPM plugins..."
~/.tmux/plugins/tpm/bin/update_plugins all

echo "Update complete!"
