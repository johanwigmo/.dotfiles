#!/usr/bin/env bash
set -euo pipefail

# Scaffold opencode setup into a dev project: AGENTS.md stub + opencode.json.
# Idempotent — existing files are never overwritten, and the iOS build block is
# appended once for iOS-shaped projects whose AGENTS.md predates it.
#
# Usage: dev-project-init.sh <name> [parent-dir]
# Example: dev-project-init.sh my-app            → ~/Developer/my-app
#          dev-project-init.sh my-app ~/Work     → ~/Work/my-app

NAME="${1:-}"
PARENT="${2:-$HOME/Developer}"
TEMPLATE="$HOME/.dotfiles/opencode/project-template"
IOS_BLOCK="$HOME/.dotfiles/opencode/ios-agents-block.md"
TARGET="$PARENT/$NAME"

usage() {
	echo "Usage: dev-project-init.sh <name> [parent-dir]"
	echo "Example: dev-project-init.sh my-app           # ~/Developer/my-app"
	echo "         dev-project-init.sh my-app ~/Work    # ~/Work/my-app"
}

if [[ -z "$NAME" || "$NAME" == -* ]]; then
	usage
	exit 1
fi

if [[ ! -d "$TEMPLATE" ]]; then
	echo "Error: template not found at $TEMPLATE"
	exit 1
fi

if [[ ! -d "$TARGET" ]]; then
	mkdir -p "$TARGET"
	echo "Created $TARGET"
fi

shopt -s dotglob

# Copy template files, never overwrite
for file in "$TEMPLATE"/*; do
	base="$(basename "$file")"
	if [[ -e "$TARGET/$base" ]]; then
		echo "Exists, keeping: $base"
	else
		cp "$file" "$TARGET/$base"
		echo "Added: $base"
	fi
done
shopt -u dotglob

# iOS app projects: append the ios-build.sh block once (existing AGENTS.md
# predating the template, or a repo cloned before it was scaffolded)
if compgen -G "$TARGET"/*.xcodeproj >/dev/null || compgen -G "$TARGET"/*.xcworkspace >/dev/null; then
	if [[ -f "$IOS_BLOCK" && -f "$TARGET/AGENTS.md" ]] && ! grep -q "ios-build.sh" "$TARGET/AGENTS.md"; then
		printf '\n' >>"$TARGET/AGENTS.md"
		cat "$IOS_BLOCK" >>"$TARGET/AGENTS.md"
		echo "Appended iOS build block to AGENTS.md"
	fi
fi

# Init git if there is no repo already (including in a parent dir)
if ! git -C "$TARGET" rev-parse --git-dir &>/dev/null; then
	git -C "$TARGET" init -b main &>/dev/null
	echo "Initialized git repo"
fi

echo ""
echo "Scaffolded $TARGET"
echo "Next: edit AGENTS.md — add build/test commands and project conventions."
