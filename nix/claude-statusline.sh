#!/usr/bin/env bash
# Renders from stdin, local files, and a usage cache. The usage API is never
# called on the render path.
set -u

# 2 renders identity and metrics on separate rows. 1 joins them into one row.
ROWS=${STATUSLINE_ROWS:-2}

USAGE_MAX_AGE=180
USAGE_LOCK_AGE=30

SCRIPT_PATH=${BASH_SOURCE[0]}

if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  account_state=$CLAUDE_CONFIG_DIR/.claude.json
  account_maps=("$CLAUDE_CONFIG_DIR/account-names" "$HOME/.claude/account-names")
  credentials=$CLAUDE_CONFIG_DIR/.credentials.json
  profile_key=$CLAUDE_CONFIG_DIR
else
  account_state=$HOME/.claude.json
  account_maps=("$HOME/.claude/account-names")
  credentials=$HOME/.claude/.credentials.json
  profile_key=$HOME/.claude
fi

# Each profile authenticates as a different account, so each gets its own cache.
usage_dir=${XDG_CACHE_HOME:-$HOME/.cache}/statusline
usage_key=$(printf '%s' "$profile_key" | sha256sum | cut -c1-12)
usage_cache=$usage_dir/usage-$usage_key.json
usage_lock=$usage_dir/usage-$usage_key.lock

now=$(date +%s)

file_age() {
  local mtime
  mtime=$(stat -c %Y "$1" 2>/dev/null) || return 1
  printf '%s' "$(( now - mtime ))"
}

if [ "${1:-}" = "--refresh-usage" ]; then
  [ -r "$credentials" ] || exit 0
  mkdir -p "$usage_dir" || exit 0

  age=$(file_age "$usage_lock") && [ "$age" -lt "$USAGE_LOCK_AGE" ] && exit 0
  : > "$usage_lock"

  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$credentials" 2>/dev/null)
  [ -n "$token" ] || exit 0

  body=$(curl -sS --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    https://api.anthropic.com/api/oauth/usage 2>/dev/null) || exit 0

  printf '%s' "$body" | jq -c --argjson t "$now" '
    {
      fetched_at: $t,
      session: (.five_hour.utilization // null),
      weekly: (.seven_day.utilization // null),
      fable: ([ .limits[]?
                | select(.kind == "weekly_scoped")
                | select((.scope.model.display_name // "") | ascii_downcase == "fable")
                | .percent ] | first)
    }' > "$usage_cache.tmp" 2>/dev/null \
    && mv -f "$usage_cache.tmp" "$usage_cache"
  exit 0
fi

GREY=$'\033[38;5;240m'
DIM=$'\033[38;5;245m'
USER=$'\033[38;5;250m'
YELLOW=$'\033[38;5;3m'
GOLD=$'\033[38;5;178m'
RED=$'\033[38;5;196m'
BLUE=$'\033[38;5;39m'
RESET=$'\033[0m'

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf 'UNKNOWN\n'
  exit 0
fi

mapfile -t F < <(printf '%s' "$input" | jq -r '
  [ (.model.display_name // "UNKNOWN"),
    (.effort.level // ""),
    (.workspace.current_dir // .cwd // ""),
    (.workspace.git_worktree // .worktree.name // ""),
    (.context_window.used_percentage // -1),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.seven_day.used_percentage // -1),
    (if .prompt_cache.warm == null then "" else (.prompt_cache.warm | tostring) end),
    (.prompt_cache.hit_ratio // -1),
    (.cost.total_cost_usd // -1),
    (.cost.total_lines_added // -1),
    (.cost.total_lines_removed // -1)
  ] | .[] | tostring')

model=${F[0]:-UNKNOWN}
effort=${F[1]:-}
dir=${F[2]:-}
worktree=${F[3]:-}
ctx_pct=${F[4]:--1}
five_pct=${F[5]:--1}
week_pct=${F[6]:--1}
cache_warm=${F[7]:-}
cache_ratio=${F[8]:--1}
cost=${F[9]:--1}
lines_added=${F[10]:--1}
lines_removed=${F[11]:--1}

[ -n "$model" ] || model=UNKNOWN
[ -n "$dir" ] || dir=$PWD

# The statusline input carries no account. Read it from Claude Code's own
# state file, then map the address to a name. The address is never printed.
account=UNKNOWN
if [ -r "$account_state" ]; then
  email=$(jq -r '.oauthAccount.emailAddress // empty' "$account_state" 2>/dev/null)
  if [ -n "$email" ]; then
    for account_names in "${account_maps[@]}"; do
      [ -r "$account_names" ] || continue
      mapped=$(awk -F= -v e="$email" '
        /^[[:space:]]*#/ { next }
        $1 == e { sub(/^[^=]*=/, ""); print; exit }
      ' "$account_names")
      if [ -n "$mapped" ]; then
        account=$mapped
        break
      fi
    done
  fi
fi

# Render whatever the cache holds, then refresh out of band when it is stale.
fable_pct=-1
if [ -r "$usage_cache" ]; then
  fable_pct=$(jq -r '.fable // -1' "$usage_cache" 2>/dev/null) || fable_pct=-1
fi

if [ -r "$credentials" ]; then
  cache_age=$(file_age "$usage_cache") || cache_age=$(( USAGE_MAX_AGE + 1 ))
  if [ "$cache_age" -ge "$USAGE_MAX_AGE" ]; then
    if command -v setsid >/dev/null 2>&1; then
      setsid bash "$SCRIPT_PATH" --refresh-usage >/dev/null 2>&1 &
    else
      bash "$SCRIPT_PATH" --refresh-usage >/dev/null 2>&1 &
    fi
    disown 2>/dev/null || true
  fi
fi

display_dir=$dir
case "$display_dir" in
  "$HOME") display_dir='~' ;;
  "$HOME"/*) display_dir="~${display_dir#"$HOME"}" ;;
esac

git_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 0.3s git --no-optional-locks -C "$dir" "$@" 2>/dev/null
  else
    git --no-optional-locks -C "$dir" "$@" 2>/dev/null
  fi
}

branch_seg=""
dirty_seg=""

if command -v git >/dev/null 2>&1; then
  inside=$(git_cmd rev-parse --is-inside-work-tree)
  if [ "$inside" = "true" ]; then
    branch=$(git_cmd symbolic-ref --quiet --short HEAD)
    [ -n "$branch" ] || branch=$(git_cmd rev-parse --short HEAD)
    if [ -n "$branch" ]; then
      color=$RED
      [ "$branch" = "main" ] && color=$YELLOW
      branch_seg=" ${color}[${branch}]${RESET}"

      if ! git_cmd diff --no-ext-diff --ignore-submodules --quiet HEAD --; then
        dirty_seg=" ${GOLD}▲${RESET}"
      elif [ -n "$(git_cmd ls-files --others --exclude-standard | head -n 1)" ]; then
        dirty_seg=" ${GOLD}▲${RESET}"
      fi
    fi
  fi
fi

worktree_seg=""
[ -n "$worktree" ] && worktree_seg=" ${BLUE}⑂${worktree}${RESET}"

model_seg=$model
case ${model,,} in
  *fable*) ;;
  *) model_seg="${GOLD}${model}${RESET}" ;;
esac

# The field is absent on models without effort levels.
effort_seg=""
[ -n "$effort" ] && effort_seg=" $effort"

is_num() { case $1 in ''|*[!0-9.-]*) return 1 ;; *) return 0 ;; esac; }

round() { awk -v v="$1" 'BEGIN { printf "%d", v + 0.5 }'; }

threshold() {
  awk -v v="$1" 'BEGIN { if (v >= 90) print "196"; else if (v >= 70) print "178"; else print "240" }'
}

bar() {
  awk -v v="$1" -v w="$2" 'BEGIN {
    n = int((v / 100) * w + 0.5)
    if (n < 0) n = 0
    if (n > w) n = w
    for (i = 0; i < w; i++) printf "%s", (i < n ? "█" : "░")
  }'
}

gauge() {
  local label=$1 pct=$2
  is_num "$pct" || return 0
  awk -v v="$pct" 'BEGIN { exit !(v >= 0) }' || return 0
  printf '%s%s%s %s%s%s %s%s%%%s' \
    "$DIM" "$label" "$RESET" \
    $'\033[38;5;'"$(threshold "$pct")"'m' "$(bar "$pct" 8)" "$RESET" \
    "$DIM" "$(round "$pct")" "$RESET"
}

metrics=()
seg=$(gauge ctx "$ctx_pct"); [ -n "$seg" ] && metrics+=("$seg")
seg=$(gauge 5h "$five_pct"); [ -n "$seg" ] && metrics+=("$seg")
seg=$(gauge wk "$week_pct"); [ -n "$seg" ] && metrics+=("$seg")
seg=$(gauge fable "$fable_pct"); [ -n "$seg" ] && metrics+=("$seg")

if [ "$cache_warm" = "false" ]; then
  metrics+=("${DIM}cache${RESET} ${RED}cold${RESET}")
elif [ "$cache_warm" = "true" ]; then
  if is_num "$cache_ratio" && awk -v v="$cache_ratio" 'BEGIN { exit !(v >= 0) }'; then
    metrics+=("${DIM}cache${RESET} ${GREY}$(round "$(awk -v v="$cache_ratio" 'BEGIN { print v * 100 }')")%${RESET}")
  else
    metrics+=("${DIM}cache${RESET} ${GREY}warm${RESET}")
  fi
fi

if is_num "$cost" && awk -v v="$cost" 'BEGIN { exit !(v >= 0) }'; then
  metrics+=("${DIM}$(awk -v v="$cost" 'BEGIN { printf "$%.2f", v }')${RESET}")
fi

if is_num "$lines_added" && [ "$lines_added" -ge 0 ] 2>/dev/null; then
  metrics+=("${GREY}+${lines_added}/-${lines_removed}${RESET}")
fi

identity=$(printf '%s%s %s%s%s %s%s%s%s%s%s' \
  "$model_seg" "$effort_seg" "$USER" "$account" "$RESET" \
  "$GREY" "$display_dir" "$RESET" "$branch_seg" "$dirty_seg" "$worktree_seg")

metrics_row=""
if [ ${#metrics[@]} -gt 0 ]; then
  sep=" ${GREY}·${RESET} "
  metrics_row=${metrics[0]}
  for ((i = 1; i < ${#metrics[@]}; i++)); do
    metrics_row+="${sep}${metrics[i]}"
  done
fi

if [ -z "$metrics_row" ]; then
  printf '%s\n' "$identity"
elif [ "$ROWS" = "1" ]; then
  printf '%s %s%s%s %s\n' "$identity" "$GREY" "·" "$RESET" "$metrics_row"
else
  printf '%s\n%s\n' "$identity" "$metrics_row"
fi
