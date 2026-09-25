#!/bin/zsh
# Nightly autocommit + push of the notes vault.
# Runs only on the sync host (Mac Mini, LaunchAgent dev.wigmo.notes-sync).
#
# Design: the git database lives OUTSIDE the iCloud-synced vault folder, so
# iCloud never syncs .git state between machines. Laptop edits arrive on the
# Mini via iCloud; this job commits whatever is on disk and pushes to GitHub.
# Single-writer: nothing else ever pushes, so no pull/fetch is needed.
set -euo pipefail

GB="$HOME/Library/notes-vault.git"                       # git database (bare)
WT="$HOME/Documents/notes"                               # work tree (iCloud-synced)
LOG="$HOME/Library/Logs/notes-sync.log"

export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new"

# guard against overlapping runs (manual kick while scheduled run in progress)
LOCK="$HOME/.notes-sync.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  age=$(($(date +%s) - $(stat -f %m "$LOCK")))
  # steal the lock if it is stale (crash mid-run) or a leftover file from an older version
  if [ ! -d "$LOCK" ] || [ $age -gt 7200 ]; then
    rm -rf "$LOCK"
    mkdir "$LOCK"
  else
    exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

g() { git --git-dir="$GB" --work-tree="$WT" "$@"; }

{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
  if [ ! -d "$GB" ]; then
    echo "error: $GB missing — one-time init not done on this machine (sync host only)"
    exit 1
  fi
  if [ ! -d "$WT" ]; then
    echo "error: work tree $WT missing"
    exit 1
  fi

  g add -A
  if g diff --cached --quiet; then
    echo "no changes"
  else
    g commit -q -m "auto: $(date '+%Y-%m-%d %H:%M') $(hostname -s)"
    if ! g push origin main; then
      echo "error: push failed (non-fast-forward = remote got new commits — check git state)"
      exit 1
    fi
  fi
  echo "ok"
} >> "$LOG" 2>&1
