#!/usr/bin/env bash
# Install or remove LaunchAgents defined in ~/.dotfiles/LaunchAgents.
# Called by bootstrap.sh and update.sh.
#
# Per-machine gating: an agent is only installed when the machine's
# ~/.config/dotfiles.env exports the matching flag (see gates below).
# Non-matching machines get the agent removed, so state self-heals.
set -euo pipefail

[ -f "$HOME/.config/dotfiles.env" ] && source "$HOME/.config/dotfiles.env"

install_agent() {
	local name="$1" label="${1%.plist}"
	local source="$HOME/.dotfiles/LaunchAgents/$name"
	local target="$HOME/Library/LaunchAgents/$name"

	if [[ ! -f "$source" ]]; then
		echo "Warning: $source missing, skipping $name"
		return
	fi

	mkdir -p "$HOME/Library/LaunchAgents"
	ln -sf "$source" "$target"

	launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
	if launchctl bootstrap "gui/$(id -u)" "$target" 2>/dev/null; then
		echo "Installed $name"
	else
		echo "Warning: could not bootstrap $name (it will load at next login)"
	fi
}

remove_agent() {
	local name="$1" label="${1%.plist}"
	local target="$HOME/Library/LaunchAgents/$name"

	launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
	if [ -L "$target" ] || [ -e "$target" ]; then
		rm -f "$target"
		echo "Removed $name (not enabled on this machine)"
	fi
}

# --- gates -------------------------------------------------------------------

if [[ "${NOTES_SYNC_HOST:-0}" == "1" ]]; then
	install_agent "dev.wigmo.notes-sync.plist"
else
	remove_agent "dev.wigmo.notes-sync.plist"
fi
