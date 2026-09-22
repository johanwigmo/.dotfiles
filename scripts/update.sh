#!/usr/bin/env bash
set -euo pipefail

echo "Updating dotfiles"
cd "$HOME/.dotfiles"
git pull

echo "Re-stowing configurations"
stow -R zsh
stow -R starship
stow -R herdr
stow -R tmux
stow -R git
stow -R nvim
stow -R zed
stow -R ghostty
stow -R borders
stow -R opencode

echo "Updating Homebrew and packages from Brewfile..."
brew update
if ! brew bundle --file="$HOME/.dotfiles/Brewfile"; then
	echo "Warning: some Brewfile items failed to update"
	echo "mas apps may need an App Store sign-in - re-run this script later"
fi
if ! brew upgrade --cask; then
	echo "Warning: some casks failed to upgrade (errors above)"
	echo "Common cause: the app is running - quit it and re-run this script"
fi
brew cleanup

echo "Updating TPM plugins..."
~/.tmux/plugins/tpm/bin/update_plugins all

echo "Update complete!"

echo ""
echo "Note: If dotfiles.env changed, update it with: "
echo "    cp ~/.dotfiles/config/dotfiles.env ~/.config/dotfiles.env"
