#!/usr/bin/env bash
set -euo pipefail

# iOS CLI build/test/run loop — headless xcodebuild companion for nvim/agent work.
# Simulator-only: no codesigning, SSH-safe. Device deploys stay in Xcode.
#
# Usage:
#   ios-build.sh [build]                   build for the simulator (default action)
#   ios-build.sh test [xcodebuild ...]     test; -only-testing:/-skip-testing: pass through
#   ios-build.sh run [xcodebuild ...]      build + simctl install + launch on a simulator
#   ios-build.sh watch [build|test|run] …  same trio for the watch target
#                                          (WATCH_SCHEME required in practice — the
#                                          default-basename scheme is the iOS one)
#   ios-build.sh -h
#
# Any extra args are forwarded to xcodebuild/swift (e.g. -configuration Release).
# A leading -flag instead of an action (e.g. `ios-build.sh -configuration Release`)
# is a build with those flags.
#
# Config, resolved per project root (walks up from cwd for a project/workspace/
# Package.swift). Per key, first match wins:
#   1. environment: IOS_SCHEME, IOS_DESTINATION, WATCH_SCHEME, WATCH_DESTINATION
#      (outright — an exported value beats the same key in both files below)
#   2. .ios-build.env.local in project root   (machine-local, gitignore)
#   3. .ios-build.env in project root         (committed)
#
#   IOS_SCHEME=chores
#   IOS_DESTINATION='platform=iOS Simulator,name=iPhone 18 Pro'
#   WATCH_SCHEME='Tjing Watch App'
#   WATCH_DESTINATION='platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'
#
# Defaults: scheme = basename of the project/workspace, same for watch; dest =
# generic simulator (iOS/watchOS) for build, single booted iPhone/Watch for
# test/run. SPM-only roots (Package.swift, no .xcodeproj) map build/test to swift.

usage() { sed -n '/^# iOS CLI/,/^# SPM/p' "$0" | sed 's/^# \{0,1\}//'; }

die() { echo "ios-build: $*" >&2; exit 1; }

# --- args ---------------------------------------------------------------------

selector=ios # watch switches scheme/destination vars, sim family, generic dest
action="${1:-build}"
if [[ "$action" == "-h" || "$action" == "--help" ]]; then
	usage
	exit 0
fi

passthru=()
case "$action" in
watch)
	selector=watch
	shift
	if [[ $# -ge 1 && "$1" != -* ]]; then
		action="$1"
		shift
	else
		action=build # `watch -flag …` = watch build with flags
	fi
	passthru=("$@")
	;;
build | test | run)
	shift
	passthru=("$@")
	;;
-*)
	passthru=("$@") # e.g. plain `ios-build.sh -configuration Release`
	action=build
	;;
*)
	{
		echo "ios-build: unknown action '$action' (expected build/test/run, an optional leading 'watch', or xcodebuild flags)"
		usage
	} >&2
	exit 1
	;;
esac

# --- project root ------------------------------------------------------------

# Package.swift is checked with -f, not a glob: a pattern without wildcard
# chars is never expanded (nullglob or not), so pkgs=("$ROOT"/Package.swift)
# would always keep the literal string and false-positive the SPM branch.
shopt -s nullglob
ROOT="$PWD"
while true; do
	workspaces=("$ROOT"/*.xcworkspace)
	projects=("$ROOT"/*.xcodeproj)
	pkgs=()
	[[ -f "$ROOT/Package.swift" ]] && pkgs=("$ROOT"/Package.swift)
	if (( ${#workspaces[@]} + ${#projects[@]} + ${#pkgs[@]} > 0 )); then
		break
	fi
	[[ "$ROOT" == "$HOME" || "$ROOT" == "/" ]] && die "no .xcodeproj/.xcworkspace/Package.swift from $PWD upward"
	ROOT="$(dirname "$ROOT")"
done
shopt -u nullglob
cd "$ROOT"

if [[ -n "${pkgs[0]:-}" ]] && [[ -z "${projects[0]:-}" && -z "${workspaces[0]:-}" ]]; then
	if [[ "$selector" == watch ]]; then
		die "SPM package ($ROOT): watch selector needs an Xcode project — use swift build/test"
	fi
	case "$action" in
	run) die "SPM package ($ROOT): no app to install — use swift run" ;;
	test) exec swift test ${passthru+"${passthru[@]}"} ;;
	*) exec swift build ${passthru+"${passthru[@]}"} ;;
	esac
fi

if [[ -n "${workspaces[0]:-}" ]]; then
	BASE="${workspaces[0]##*/}"
	PRJ_ARGS=(-workspace "$BASE")
	default_scheme="${BASE%.xcworkspace}"
elif (( ${#projects[@]} == 1 )); then
	PRJ_ARGS=(-project "${projects[0]##*/}")
	default_scheme="${projects[0]##*/}"
	default_scheme="${default_scheme%.xcodeproj}"
else
	die "multiple .xcodeproj in $ROOT and no .xcworkspace — point IOS_SCHEME/args at one"
fi

# --- config -------------------------------------------------------------------

# True env > .local > .env precedence: sourcing below clobbers the process env,
# so snapshot it first. Sourcing already merges .local over .env (later source
# wins per key); these four lines only restore an exported value outright.
env_scheme="${IOS_SCHEME:-}"
env_dest="${IOS_DESTINATION:-}"
env_watch_scheme="${WATCH_SCHEME:-}"
env_watch_dest="${WATCH_DESTINATION:-}"
[[ -f "$ROOT/.ios-build.env" ]] && source "$ROOT/.ios-build.env"
[[ -f "$ROOT/.ios-build.env.local" ]] && source "$ROOT/.ios-build.env.local"
ios_scheme="${env_scheme:-${IOS_SCHEME:-}}"
ios_dest="${env_dest:-${IOS_DESTINATION:-}}"
watch_scheme="${env_watch_scheme:-${WATCH_SCHEME:-}}"
watch_dest="${env_watch_dest:-${WATCH_DESTINATION:-}}"

if [[ "$selector" == watch ]]; then
	scheme="${watch_scheme:-$default_scheme}"
	dest="$watch_dest"
	generic_dest="generic/platform=watchOS Simulator"
else
	scheme="${ios_scheme:-$default_scheme}"
	dest="$ios_dest"
	generic_dest="generic/platform=iOS Simulator"
fi

first_booted() { # $1 = device-name substring (iPhone | Watch)
	xcrun simctl list devices booted 2>/dev/null \
		| sed -n "s/.*$1.*(\([0-9A-F-]\{36\}\)).*(Booted).*/\1/p" | head -1
}

if [[ -z "$dest" && ("$action" == test || "$action" == run) ]]; then
	if [[ "$selector" == watch ]]; then
		udid="$(first_booted Watch)"
		[[ -z "$udid" ]] && die "no WATCH_DESTINATION set and no booted Watch — set it in $ROOT/.ios-build.env(.local) (e.g. 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)') or boot one"
		dest="platform=watchOS Simulator,id=$udid"
	else
		udid="$(first_booted iPhone)"
		[[ -z "$udid" ]] && die "no IOS_DESTINATION set and no booted iPhone — set it in $ROOT/.ios-build.env(.local) (e.g. 'platform=iOS Simulator,name=iPhone 18 Pro') or boot one"
		dest="platform=iOS Simulator,id=$udid"
	fi
fi

# No -sdk flag: the destination decides the platform. An explicit -sdk
# forces every target (incl. embedded watchOS targets, cf. ToGo) into the
# same platform domain, where watchkit2 product types don't resolve.
xargs=("${PRJ_ARGS[@]}" -scheme "$scheme")

resolve_udid() {
	if [[ "$dest" == *id=* ]]; then
		udid="${dest##*id=}"
	else
		local sim_name="${dest##*name=}"; sim_name="${sim_name%%,OS=*}"
		udid="$(xcrun simctl list devices | grep -F " $sim_name (" | head -1 | awk -F'[()]' '{print $2}' || true)"
		[[ -n "$udid" ]] || die "no simulator named '$sim_name' — check xcrun simctl list devices"
	fi
}

# Boot with a visible message; xcodebuild's own cold boot is slow AND silent
# (xcbeautify eats the "Preparing for testing" lines), which reads as a hang.
boot_if_needed() {
	if ! xcrun simctl list devices | grep -F "($udid)" | grep -q "(Booted)"; then
		echo "ios-build: booting simulator $udid" >&2
		xcrun simctl boot "$udid"
	fi
}

xcodepipe() {
	if command -v xcbeautify >/dev/null 2>&1; then
		xcodebuild "$@" 2>&1 | xcbeautify
	else
		xcodebuild "$@"
	fi
}

# Parallel test runs clone the destination and SHUT IT DOWN at teardown —
# slow spin-up and it kills your pre-booted sim. Defaults to off; re-enable
# with IOS_PARALLEL=1 (a -parallel-testing… passthrough always wins).
if [[ "$action" == test && -z "${IOS_PARALLEL:-}" ]] &&
	! grep -q -- "-parallel-testing" <(printf '%s\n' ${passthru+"${passthru[@]}"}); then
	passthru+=(-parallel-testing-enabled NO)
fi

label="$action"
if [[ "$selector" == watch ]]; then
	label="watch:$action"
fi
echo "ios-build: $label scheme=$scheme prj=${PRJ_ARGS[*]} dest=${dest:-$generic_dest}" >&2

case "$action" in
build)
	xcodepipe "${xargs[@]}" -destination "${dest:-$generic_dest}" build ${passthru+"${passthru[@]}"} \
		&& echo "ios-build: ✔ built $scheme"
	;;

test)
	xcodepipe "${xargs[@]}" -destination "$dest" test ${passthru+"${passthru[@]}"} \
		&& echo "ios-build: ✔ tests passed"
	;;

run)
	# resolve the .app product + bundle id from build settings
	settings="$(xcodebuild "${xargs[@]}" -configuration Debug -destination "${dest:-$generic_dest}" -showBuildSettings 2>/dev/null \
		| awk -F' = ' '
			{ k=$1; gsub(/[[:space:]]+/, "", k); v=$2
			  if (k == "BUILT_PRODUCTS_DIR") dir = v
			  else if (k == "FULL_PRODUCT_NAME") name = v
			  else if (k == "PRODUCT_BUNDLE_IDENTIFIER" && name ~ /\.app$/) { id = v; exit }
			}
			END { print dir "|" name "|" id }')"
	IFS='|' read -r app_dir app_name app_id <<<"$settings"
	[[ -n "${app_name:-}" && "$app_name" == *.app ]] || die "scheme $scheme builds no .app product"
	[[ -n "${app_id:-}" ]] || die "no PRODUCT_BUNDLE_IDENTIFIER found"

	# pin the target simulator to a UDID (unambiguous with several booted sims)
	resolve_udid
	boot_if_needed

	xcodepipe "${xargs[@]}" -destination "$dest" build ${passthru+"${passthru[@]}"} \
		&& echo "ios-build: ✔ built $scheme"

	app="$app_dir/$app_name"
	[[ -d "$app" ]] || die "built app missing: $app"
	xcrun simctl install "$udid" "$app"
	xcrun simctl launch "$udid" "$app_id" && echo "ios-build: ✔ launched $app_id on $udid"
	;;
esac
