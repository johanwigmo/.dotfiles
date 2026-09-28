#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: toggl-weekly.sh [YYYY-MM-DD | YYYY-Www]

  no arg      current ISO week (Monday-Sunday)
  YYYY-MM-DD  the Mon-Sun week containing that date
  YYYY-Www    ISO week, e.g. 2026-W39
  --debug     dump raw API responses to stderr

env:
  TOGGL_API_TOKEN      required — token from track.toggl.com/profile
  TOGGL_WORKSPACE_ID   optional  (auto-resolved from /me when unset)
EOF
  exit 1
}

err() { echo "toggl-weekly: $*" >&2; exit 1; }

DBG=0
ARG=""
for a in "$@"; do
  case "$a" in
    --debug) DBG=1 ;;
    --help|-h) usage ;;
    *) if [ -n "$ARG" ]; then usage; else ARG="$a"; fi ;;
  esac
done

to_days() {
  local e
  e=$(date -j -f "%F %H:%M" "$1 00:00" +%s 2>/dev/null) || return 1
  echo $(( (e + 43200) / 86400 ))
}

# date -> RFC3339 local-midnight timestamp, e.g. 2026-09-21T00:00:00+02:00
iso_local() {
  local off
  off=$(date -j -f "%F %H:%M" "$1 00:00" +%z 2>/dev/null) || err "unparseable date: $1"
  echo "${1}T00:00:00${off:0:3}:${off:3}"
}

DAYS=""
case "$ARG" in
  "")
    DAYS=$(to_days "$(date +%F)") || err "unparseable today: $(date +%F)"
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
    DAYS=$(to_days "$ARG") || err "unparseable date: $ARG"
    ;;
  [0-9][0-9][0-9][0-9]-W[0-9][0-9])
    year=${ARG:0:4}
    week=${ARG:6:2}
    [ "$week" -ge 1 ] && [ "$week" -le 53 ] 2>/dev/null || usage
    jan4=$(to_days "$year-01-04") || usage
    jan4dow=$(( (jan4 + 3) % 7 + 1 ))
    DAYS=$(( jan4 + (week - 1) * 7 + (1 - jan4dow) ))
    ;;
  *) usage ;;
esac

dow=$(( (DAYS + 3) % 7 + 1 ))
mon_days=$(( DAYS - (dow - 1) ))
sun_days=$(( mon_days + 6 ))
MONDAY=$(date -r $(( mon_days * 86400 )) +%F)
SUNDATE=$(date -r $(( sun_days * 86400 )) +%F)
NEXT_MON=$(date -r $(( (sun_days + 1) * 86400 )) +%F)
weekno=$(date -r $(( (mon_days + 3) * 86400 )) +%V 2>/dev/null || true)
if [ -n "${weekno:-}" ]; then
  LABEL="W$weekno: $MONDAY → $SUNDATE"
else
  LABEL="$MONDAY → $SUNDATE"
fi

TOGGL_API_TOKEN=${TOGGL_API_TOKEN:-}
[ -n "$TOGGL_API_TOKEN" ] || err "no token: export TOGGL_API_TOKEN (add it to ~/.config/dotfiles.env)"

BASE="https://api.track.toggl.com"

api() {
  local method=$1 path=$2 body=${3:-} out code resp
  if [ -n "$body" ]; then
    out=$(curl -sS -w $'\n%{http_code}' -u "$TOGGL_API_TOKEN:api_token" \
      -H "Content-Type: application/json" -X "$method" "$BASE$path" -d "$body") || err "curl failed for $path"
  else
    out=$(curl -sS -w $'\n%{http_code}' -u "$TOGGL_API_TOKEN:api_token" "$BASE$path") || err "curl failed for $path"
  fi
  code=${out##*$'\n'}
  resp=${out%$code}
  resp=${resp%$'\n'}
  if [ "$code" != "200" ]; then
    local msg
    msg=$(printf '%s' "$resp" | jq -r '.message // empty' 2>/dev/null || true)
    [ -n "$msg" ] || msg="$resp"
    err "API $code on $method $path: $msg" 2
  fi
  printf '%s' "$resp"
}

if [ -n "${TOGGL_WORKSPACE_ID:-}" ]; then
  WS=$TOGGL_WORKSPACE_ID
else
  WS=$(api GET /api/v9/me | jq -r '.default_workspace_id // empty')
fi
[ -n "${WS:-}" ] || err "could not resolve workspace id — check TOGGL_API_TOKEN"

START_ISO=$(iso_local "$MONDAY")
END_ISO=$(iso_local "$NEXT_MON")
QSTART=${START_ISO/+/%2B}
QEND=${END_ISO/+/%2B}
ENTRIES=$(api GET "/api/v9/me/time_entries?start_date=$QSTART&end_date=$QEND")
PROJECTS=$(api GET "/api/v9/workspaces/$WS/projects")

if [ "$DBG" = 1 ]; then
  echo "--- time entries (count: $(printf '%s' "$ENTRIES" | jq 'length' 2>/dev/null || echo ?)) ---" >&2
  printf '%s' "$ENTRIES" | jq . >&2
  echo "--- projects (count: $(printf '%s' "$PROJECTS" | jq 'length' 2>/dev/null || echo ?)) ---" >&2
  printf '%s' "$PROJECTS" | jq 'if type == "array" then .[0:3] else . end' >&2
fi

aggregate() {
  jq -s -r '
    def hhmm:
      if . == 0 then "0h" else
      (./3600|floor) as $h | (((. % 3600)/60)|floor) as $m |
      (if $h > 0 then "\($h)h" else "" end) +
      (if $m > 0 then (if $h > 0 then " " else "" end) + "\($m)m" else "" end)
      end;
    def esc: (gsub("\\|"; "\\|") | gsub("\\n"; " "));
    .[0] as $me |
    (.[1] | map({key: (.id|tostring), value: {name: .name, client_name: .client_name}}) | from_entries) as $proj |
    [ $me[]
      | { pid: (.project_id // -1), t: ((.description // "") | esc),
          s: (if (.duration // 0) > 0 then .duration else (now + (.duration // 0)) end) }
      | select(.s > 0) ]
    | if length == 0 then empty else . end
    | group_by(.pid)
    | map({
        pid: .[0].pid,
        s: (map(.s) | add),
        entries: (group_by(.t) | map({ t: .[0].t, s: (map(.s) | add) }))
      })
    | sort_by(-.s)
    | (map(.s) | add // 0) as $total
    | map(
        (if (.pid // -1) == -1 then "(no project)"
         else ($proj[.pid|tostring] // {name: "(unknown project)", client_name: null}) as $p |
           ((if ($p.client_name // null) != null
             then ($p.client_name | gsub("\\|"; "\\|")) + " · "
             else "" end)
           + (($p.name // "(unknown project)") | gsub("\\|"; "\\|")))
         end) as $label
        | ["| \($label) | \(.s | hhmm) |"] +
          (.entries | sort_by(-.s)
           | map("| ↳ \(if .t == "" then "(no description)" else .t end) | \(.s | hhmm) |"))
      )
    | flatten as $lines
    | ($lines[], { total: ($total | hhmm) })
    | if type == "string" then . else "TOTAL: \(.total)" end
  ' <(printf '%s' "$ENTRIES") <(printf '%s' "$PROJECTS")
}

if [ "$DBG" = 1 ]; then
  echo "--- aggregate output ---" >&2
  aggregate >&2
  exit 0
fi

OUT=$(aggregate) || err "could not parse time entries response (run with --debug to inspect)"

TOTAL=$(printf '%s' "$OUT" | grep '^TOTAL:' | cut -d' ' -f2- || true)
if [ "$TOTAL" = "TOTAL: 0h" ] || [ -z "$TOTAL" ]; then
  echo "Time $LABEL — no tracked time this week."
  exit 0
fi

echo "Time $LABEL — total ${TOTAL#TOTAL: }"
echo ""
echo "| Project / Notes | Hours |"
echo "|---|---|"
printf '%s\n' "$OUT" | grep '^|'
