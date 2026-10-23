#!/usr/bin/env zsh
# Keeps Tailscale running so the machine stays reachable.
# Covers the three ways it goes dark: `brew upgrade --cask` quits the app
# without relaunching it, crashes, and reboots (RunAtLoad restarts it at
# login without a Login Item). Fired by dev.wigmo.tailscale-watchdog.plist.
#
# Note: deliberately does NOT handle a logged-out node — re-auth needs an
# interactive auth URL (VNC or LAN SSH), no point fighting it every 5 min.

set -u

TS_APP="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
LOG="/tmp/tailscale-watchdog.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >>"$LOG"; }

[[ -d /Applications/Tailscale.app ]] || exit 0

# Case 1: app not running (cask upgrade quit it, or crash) -> start it.
# State persists in the app, so no re-auth is needed.
if ! pgrep -xq Tailscale; then
	open -ga Tailscale
	log "Tailscale not running - relaunched"
	exit 0
fi

# Case 2: app running but connection wedged (post-upgrade daemon hiccup)
# -> restart the app. A logged-out node is skipped; restart won't fix it.
status_out="$("$TS_APP" status 2>&1)"
if [[ $? -ne 0 && "$status_out" != *"Logged out"* ]]; then
	osascript -e 'quit app "Tailscale"' 2>/dev/null || pkill -x Tailscale
	sleep 2
	open -ga Tailscale
	log "Tailscale wedged (status: ${status_out%%$'\n'*}) - restarted app"
fi
