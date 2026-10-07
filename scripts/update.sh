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
	if ! stow -R "$pkg"; then
		echo ""
		echo "Fix: a tool likely overwrote a stowed symlink with a regular file"
		echo "(e.g. codegraph init replaces stowed opencode config files)."
		echo "Keep the new content:"
		echo "    cd ~/.dotfiles && stow --adopt $pkg && git diff $pkg/"
		echo "    # then commit the diff (or git checkout -- $pkg/ to discard it)"
		echo "Discard the new content instead:"
		echo "    rm <target file from the stow error above> && stow -R $pkg"
		echo "Then re-run ./scripts/update.sh"
		exit 1
	fi
done

echo "Refreshing LaunchAgents..."
"$HOME/.dotfiles/scripts/install-launchagents.sh" || echo "Warning: LaunchAgent refresh had issues (see above)"

echo "Updating Homebrew and packages from Brewfile..."
brew update

# opencode: brew cannot switch an installed formula between taps, so a copy
# from another tap (e.g. homebrew/core) makes every brew bundle run fail on it
if brew list --formula opencode &>/dev/null && ! brew list --formula --full-name | grep -qx "anomalyco/tap/opencode"; then
	echo "opencode installed from another tap - switching to anomalyco/tap"
	brew tap anomalyco/tap
	brew uninstall opencode && brew install anomalyco/tap/opencode \
		|| echo "Warning: opencode tap switch failed - run manually: brew uninstall opencode && brew install anomalyco/tap/opencode"
fi

if ! brew bundle --file="$HOME/.dotfiles/Brewfile"; then
	echo "Warning: some Brewfile items failed - retrying once"
	if ! brew bundle --file="$HOME/.dotfiles/Brewfile"; then
		echo "Warning: some Brewfile items still failed after re-run"
		echo "mas apps may need an App Store sign-in - re-run this script later"
	fi
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
