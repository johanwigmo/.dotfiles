#!/usr/bin/env bash
set -euo pipefail

echo "Updating dotfiles"
cd "$HOME/.dotfiles"
git pull

echo "Re-stowing configurations"

if ! command -v stow &>/dev/null; then
	echo "Error: stow is not installed"
	echo "This script assumes bootstrap.sh has been run"
	echo "To install manually: brew install stow"
	exit 1
fi

for pkg in zsh starship herdr git nvim zed ghostty opencode; do
	stow -R "$pkg"
done

echo "Refreshing LaunchAgents..."
"$HOME/.dotfiles/scripts/install-launchagents.sh" || echo "Warning: LaunchAgent refresh had issues (see above)"

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

echo "Update complete!"

echo ""
echo "Note: If dotfiles.env changed, update it with: "
echo "    cp ~/.dotfiles/config/dotfiles.env ~/.config/dotfiles.env"
