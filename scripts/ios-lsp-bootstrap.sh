#!/usr/bin/env bash
set -euo pipefail

# Per-machine, per-project sourcekit-lsp onboarding for the nvim iOS setup:
#   1. xcode-build-server config — writes buildServer.json (machine-local;
#      gitignore it, never synced between machines)
#   2. first CLI build — refreshes DerivedData build logs + the index store
#
# Run once per machine after pulling a repo. Idempotent — re-run whenever
# app-target completion or go-to-definition goes stale (new target members,
# flipped build settings); any rebuild via ios-build.sh does the same.
#
# Scheme resolution mirrors ios-build.sh:
#   1. environment: IOS_SCHEME
#   2. .ios-build.env.local in project root   (machine-local, gitignore)
#   3. .ios-build.env in project root         (committed)
#   4. basename of the project/workspace
#
# SPM-only roots need no buildServer.json — sourcekit-lsp reads Package.swift directly; a swift build warms the index

usage() { sed -n '/^# Per-machine/,/^# SPM/p' "$0" | sed 's/^# \{0,1\}//'; }

die() { echo "ios-lsp-bootstrap: $*" >&2; exit 1; }

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

command -v xcode-build-server >/dev/null 2>&1 \
	|| die "xcode-build-server not installed — brew install xcode-build-server"
xcodebuild -version >/dev/null 2>&1 || die "xcodebuild unavailable — install Xcode (or fix xcode-select)"

# --- project root (same walk-up as ios-build.sh) ------------------------------

# Package.swift is checked with -f, not a glob: a pattern without wildcard
# chars is never expanded (nullglob or not), so pkgs=("$ROOT"/Package.swift)
# would always keep the literal string and false-positive the SPM branch.
shopt -s nullglob
ROOT="$PWD"
while true; do
	workspaces=("$ROOT"/*.xcworkspace)
	projects=("$ROOT"/*.xcodeproj)
	pkgs=()
	[[ -f "$ROOT/Package.swift" ]] && pkgs=("$ROOT/Package.swift")
	if (( ${#workspaces[@]} + ${#projects[@]} + ${#pkgs[@]} > 0 )); then
		break
	fi
	[[ "$ROOT" == "$HOME" || "$ROOT" == "/" ]] && die "no .xcodeproj/.xcworkspace/Package.swift from $PWD upward"
	ROOT="$(dirname "$ROOT")"
done
shopt -u nullglob

if [[ -n "${pkgs[0]:-}" && -z "${projects[0]:-}" && -z "${workspaces[0]:-}" ]]; then
	echo "ios-lsp-bootstrap: SPM package ($ROOT) — no buildServer.json needed, building to warm the index" >&2
	exec swift build
fi

if [[ -n "${workspaces[0]:-}" ]]; then
	PRJ_ARGS=(-workspace "${workspaces[0]##*/}")
	default_scheme="${workspaces[0]##*/}"
	default_scheme="${default_scheme%.xcworkspace}"
elif (( ${#projects[@]} == 1 )); then
	PRJ_ARGS=(-project "${projects[0]##*/}")
	default_scheme="${projects[0]##*/}"
	default_scheme="${default_scheme%.xcodeproj}"
else
	die "multiple .xcodeproj in $ROOT and no .xcworkspace — cd into the one you want, or add a workspace"
fi

# --- scheme -------------------------------------------------------------------

[[ -f "$ROOT/.ios-build.env" ]] && source "$ROOT/.ios-build.env"
[[ -f "$ROOT/.ios-build.env.local" ]] && source "$ROOT/.ios-build.env.local"
scheme="${IOS_SCHEME:-$default_scheme}"

# --- configure ----------------------------------------------------------------

cd "$ROOT"
echo "ios-lsp-bootstrap: xcode-build-server config ${PRJ_ARGS[*]} -scheme $scheme" >&2
xcode-build-server config "${PRJ_ARGS[@]}" -scheme "$scheme"

[[ -f buildServer.json ]] || die "xcode-build-server wrote no buildServer.json in $ROOT"
if ! grep -q '"build_root"[[:space:]]*:[[:space:]]*"[^"]' buildServer.json; then
	die "buildServer.json has no build_root — known failure mode, fix with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi
build_root="$(sed -n 's/.*"build_root"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' buildServer.json)"
echo "ios-lsp-bootstrap: build_root=$build_root" >&2

if [[ -d .git ]] && ! git -C "$ROOT" check-ignore -q buildServer.json; then
	echo "ios-lsp-bootstrap: warning — buildServer.json is not gitignored; add it (see chores/.gitignore)" >&2
fi

# --- first build (delegates to ios-build.sh; refreshes logs + index) ----------

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "ios-lsp-bootstrap: first build to populate DerivedData logs + index" >&2
exec "$here/ios-build.sh" build
