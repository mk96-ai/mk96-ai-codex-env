#!/usr/bin/env bash
# git-guard: Codex PreToolUse hook for shell commands (matcher "Bash").
# - First git command of a session: adds git-rules.md as context for the model.
# - Destructive git commands, and new branches or commits whose name breaks the
#   convention in git-rules.md (Git Flow branches, Conventional Commits) in repos that
#   already follow it or have no style yet: blocked until the user confirms. After
#   confirming in chat, the model reruns the command alone as `git -c mk96.confirmed <args>`;
#   the command rule in ~/.codex/rules/git-guard.rules then makes Codex ask the user to
#   approve it. (Codex hooks cannot ask the user themselves: PreToolUse only supports deny.)
# - Any other command: does nothing.
# Usage: configured in ~/.codex/hooks.json (PreToolUse, matcher "Bash"). Needs jq.
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly RULES_FILE="${SCRIPT_DIR}/git-rules.md"
readonly STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-git-guard"

# git invoked as a command (start of line or after ; & | ( or whitespace)
readonly GIT_CALL='(^|[;&|(]|[[:space:]])git[[:space:]]'
readonly DESTRUCTIVE='git[[:space:]].*(reset[[:space:]].*--hard|push[[:space:]].*(--force|-f([[:space:]]|$)|--force-with-lease|[[:space:]]\+)|clean[[:space:]].*-[a-zA-Z]*f|branch[[:space:]].*-D|checkout[[:space:]](.*[[:space:]])?(--|\.)([[:space:]]|$)|restore[[:space:]]|stash[[:space:]]+(drop|clear)|rebase[[:space:]]|commit[[:space:]].*--amend|--no-verify|config[[:space:]]+(--global[[:space:]]+)?(user\.|core\.hooksPath|commit\.gpgsign))'

# --- Confirmed form ---
readonly CONFIRMED_PREFIX='^[[:space:]]*git[[:space:]]+-c[[:space:]]+mk96\.confirmed[[:space:]]'
# One git command, nothing chained, redirected or substituted, so Codex matches it
# against the `prompt` rule instead of running it unseen.
readonly ALONE='^[^;&|<>`]+$'
# Destructive commands also refuse variables and wildcards (their target must be plain).
readonly PLAIN_ARGS='^[^$*?{}\\]+$'
readonly CONFIRM_TAIL='Ask the user to confirm it in chat, saying what would be lost or which name rule it breaks. Only after they confirm, run it alone (no &&, ;, | or redirections) as: git -c mk96.confirmed <same arguments>. Codex will then ask the user to approve it.'
readonly ALONE_REASON='git-guard: a confirmed git command must run alone (no &&, ;, |, redirections or $(...); destructive ones also without variables or wildcards), so Codex asks the user to approve it.'

# --- Naming convention (keep in sync with git-rules.md) ---
readonly TASK_ID='([A-Z][A-Z0-9]+-[0-9]+|[0-9]+)'
readonly KEBAB='[a-z0-9]+(-[a-z0-9]+)*'
readonly VERSION='[0-9]+\.[0-9]+\.[0-9]+'
readonly BRANCH_OK="^(main|master|develop|(feature|bugfix|hotfix)/(${TASK_ID}-${KEBAB}|${TASK_ID}|${KEBAB})|release/${VERSION}|hotfix/${VERSION})$"
readonly GITFLOW_PREFIX='^(feature|bugfix|release|hotfix|support)/'
readonly COMMIT_OK='^(feat|fix|build|chore|ci|docs|perf|refactor|revert|style|test)(\([a-z0-9._/-]+\))?!?: [^[:space:]](.*[^.])?$'
readonly COMMIT_MAX_LEN=100
readonly MIN_COMMITS_FOR_STYLE=5

# Branch creation: git [-C dir] switch|checkout ... -c|-b|-C|-B <name>, or git [-C dir] branch <name>
readonly NEW_BRANCH_SWITCH='git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(switch|checkout)[[:space:]]+([^;&|]*[[:space:]])?-[cbCB][[:space:]]+([^[:space:];&|]+)'
readonly NEW_BRANCH_BRANCH='git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?branch[[:space:]]+([^-[:space:];&|][^[:space:];&|]*)'
readonly GIT_COMMIT='git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit([[:space:]]|$)'
readonly COMMIT_MSG_FLAG='(^|[[:space:]])(-[a-zA-Z]*m|--message)([[:space:]]+|=)(.*)'

strip_quotes() {
  local s="$1"
  s="${s#[\"\']}"
  s="${s%[\"\']}"
  printf '%s' "$s"
}

# Directory the git command runs in: `git -C <dir>`, a leading `cd <dir> &&`, or the session cwd.
resolve_repo_dir() {
  local command="$1" cwd="$2" dir=""
  if [[ "$command" =~ git[[:space:]]+-C[[:space:]]+([^[:space:];&|]+) ]]; then
    dir="$(strip_quotes "${BASH_REMATCH[1]}")"
  elif [[ "$command" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:];&|]+) ]]; then
    dir="$(strip_quotes "${BASH_REMATCH[1]}")"
  fi
  [[ -n "$dir" ]] || dir="$cwd"
  [[ "$dir" == "~"* ]] && dir="${HOME}${dir:1}"
  [[ "$dir" == /* ]] || dir="${cwd}/${dir}"
  printf '%s' "$dir"
}

# Subject line of `git commit -m ...` (plain quotes or the "$(cat <<'EOF' ...)" heredoc form).
# Prints nothing when the message cannot be read.
extract_commit_subject() {
  local command="$1" rest unquoted subject
  [[ "$command" =~ $COMMIT_MSG_FLAG ]] || return 0
  rest="${BASH_REMATCH[4]}"
  unquoted="${rest#\"}"
  if [[ "$unquoted" == '$(cat <<'* ]]; then
    [[ "$rest" == *$'\n'* ]] || return 0
    rest="${rest#*$'\n'}"
    subject="${rest%%$'\n'*}"
  elif [[ "${rest:0:1}" == '"' ]]; then
    rest="${rest:1}"
    subject="${rest%%\"*}"
  elif [[ "${rest:0:1}" == "'" ]]; then
    rest="${rest:1}"
    subject="${rest%%\'*}"
  else
    subject="${rest%%[[:space:]]*}"
  fi
  subject="${subject%%$'\n'*}"
  subject="${subject#"${subject%%[![:space:]]*}"}"
  subject="${subject%"${subject##*[![:space:]]}"}"
  printf '%s' "$subject"
}

# True when the repo uses Git Flow prefixes or has no topic branches yet.
repo_uses_gitflow_branches() {
  local dir="$1" name total=0 matching=0
  while IFS= read -r name; do
    case "$name" in "" | HEAD | main | master | develop) continue ;; esac
    total=$((total + 1))
    [[ "$name" =~ $GITFLOW_PREFIX ]] && matching=$((matching + 1))
  done < <({ git -C "$dir" for-each-ref --format='%(refname:lstrip=2)' refs/heads
             git -C "$dir" for-each-ref --format='%(refname:lstrip=3)' refs/remotes; } 2>/dev/null | sort -u)
  ((total == 0 || matching * 2 >= total))
}

# True when the repo is new or at least half of its last 20 commits are Conventional Commits.
repo_uses_conventional_commits() {
  local dir="$1" subject total=0 matching=0
  while IFS= read -r subject; do
    total=$((total + 1))
    [[ "$subject" =~ $COMMIT_OK ]] && matching=$((matching + 1))
  done < <(git -C "$dir" log -20 --no-merges --format=%s 2>/dev/null || true)
  ((total < MIN_COMMITS_FOR_STYLE || matching * 2 >= total))
}

# Prints one warning per line for names that break the convention.
naming_warnings() {
  local command="$1" cwd="$2" dir branch="" subject
  dir="$(resolve_repo_dir "$command" "$cwd")"
  git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || return 0

  if [[ "$command" =~ $NEW_BRANCH_SWITCH ]]; then
    branch="$(strip_quotes "${BASH_REMATCH[4]}")"
  elif [[ "$command" =~ $NEW_BRANCH_BRANCH ]]; then
    branch="$(strip_quotes "${BASH_REMATCH[2]}")"
  fi
  if [[ -n "$branch" && ! "$branch" =~ $BRANCH_OK ]] && repo_uses_gitflow_branches "$dir"; then
    echo "Branch '${branch}' breaks the Git Flow naming: feature|bugfix|hotfix/<id>|<kebab-desc>|<id>-<kebab-desc>, release/X.Y.Z or hotfix/X.Y.Z."
  fi

  if [[ "$command" =~ $GIT_COMMIT ]]; then
    subject="$(extract_commit_subject "$command")"
    if [[ -n "$subject" ]] && { [[ ! "$subject" =~ $COMMIT_OK ]] || ((${#subject} > COMMIT_MAX_LEN)); } \
      && repo_uses_conventional_commits "$dir"; then
      echo "Commit subject '${subject}' breaks Conventional Commits: <type>(<scope>)!: <summary>, types feat|fix|build|chore|ci|docs|perf|refactor|revert|style|test, no final period, max ${COMMIT_MAX_LEN} chars."
    fi
  fi
}

deny() {
  jq -n --arg reason "$1" '{hookSpecificOutput: {
    hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

# A confirmed command runs only in the form the `prompt` rule can see.
check_confirmed() {
  local command="$1"
  [[ "$command" != *$'\n'* && "$command" =~ $ALONE && "$command" != *'$('* && "$command" != *'${'* ]] \
    || deny "$ALONE_REASON"
  if [[ "$command" =~ $DESTRUCTIVE ]]; then
    [[ "$command" =~ $PLAIN_ARGS ]] || deny "$ALONE_REASON"
  fi
}

main() {
  local input command session_id cwd marker
  input="$(cat)"
  command="$(jq -r '.tool_input.command // ""' <<<"$input")"
  session_id="$(jq -r '.session_id // "unknown"' <<<"$input")"
  cwd="$(jq -r '.cwd // ""' <<<"$input")"
  [[ -n "$cwd" ]] || cwd="$PWD"

  [[ "$command" =~ $GIT_CALL ]] || exit 0

  if [[ "$command" =~ $CONFIRMED_PREFIX ]]; then
    check_confirmed "$command"
  else
    local reasons=() warning
    if [[ "$command" =~ $DESTRUCTIVE ]]; then
      reasons+=("this git command can lose work or rewrite history.")
    fi
    while IFS= read -r warning; do
      [[ -n "$warning" ]] && reasons+=("$warning")
    done < <(naming_warnings "$command" "$cwd")
    # Deny answers carry only the decision and reason: a field Codex does not support
    # there marks the hook as failed and the command runs anyway. The rules context
    # waits for the next allowed git command.
    ((${#reasons[@]} == 0)) || deny "git-guard: ${reasons[*]} ${CONFIRM_TAIL}"
  fi

  mkdir -p -- "$STATE_DIR"
  marker="${STATE_DIR}/${session_id}"
  [[ -f "$marker" ]] && exit 0
  touch -- "$marker"
  jq -n --arg ctx "$(cat -- "$RULES_FILE")" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
}

main "$@"
