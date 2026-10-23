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
# --- Cask upgrades -----------------------------------------------------------
# Homebrew cannot tell which casks need admin, so they are listed here.
# Some casks need sudo to upgrade, and brew quits a running app BEFORE
# asking for the password (2026-10: an unnoticed prompt aborted the
# Tailscale upgrade and left the app offline). The password is asked up
# front so it can't hide: grant sudo and everything upgrades; skip it and
# SUDO_CASKS wait for the next run WITH sudo while the rest still upgrades.
#
# Maintenance: if a cask ever prompts mid-pass, add it to SUDO_CASKS.
SUDO_CASKS=(tailscale-app)

# Tailscale keeps this machine reachable (VNC/SSH). Homebrew's cask
# upgrade quits running apps and doesn't relaunch them, so remember the
# pre-upgrade state and restore it afterwards (agents/tailscale-watchdog.sh
# is the safety net if this is missed).
TS_WAS_RUNNING=0
if pgrep -xq Tailscale; then
	TS_WAS_RUNNING=1
fi

cask_failure_note() {
	echo "Warning: some casks failed to upgrade (errors above)"
	echo "Common cause: the app is running - quit it and re-run this script"
}

if sudo -v; then
	if ! brew upgrade --cask --greedy; then
		cask_failure_note
	fi
else
	echo "No sudo - skipping admin-needing casks: ${SUDO_CASKS[*]}"
	# Cask tokens can't contain whitespace, so splitting $remaining is safe.
	installed="$(brew list --cask || true)"
	remaining="$(printf '%s\n' "$installed" | grep -vxF -f <(printf '%s\n' "${SUDO_CASKS[@]}") || true)"
	if [[ -z "$installed" ]]; then
		echo "No casks installed - nothing to upgrade"
	elif [[ -n "$remaining" ]]; then
		if ! brew upgrade --cask --greedy $remaining; then
			cask_failure_note
		fi
	else
		echo "All installed casks need sudo - nothing upgraded this run"
	fi
fi
brew cleanup

if [[ "$TS_WAS_RUNNING" == "1" && ! "$(pgrep -x Tailscale)" ]]; then
	echo "Relaunching Tailscale (quit by cask upgrade)..."
	open -ga Tailscale
fi

echo "Update complete!"

echo ""
echo "Note: If dotfiles.env changed, update it with: "
echo "    cp ~/.dotfiles/config/dotfiles.env ~/.config/dotfiles.env"
