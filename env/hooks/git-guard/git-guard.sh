#!/usr/bin/env bash
# git-guard: Codex PreToolUse hook for shell commands (matcher "Bash").
# - First git command of a session: adds git-rules.md as context for the model.
# - Destructive git commands: blocked until the user confirms. After confirming in chat,
#   the model reruns the command alone as `git -c mk96.confirmed <args>`; the command rule
#   in ~/.codex/rules/git-guard.rules then makes Codex ask the user to approve it.
#   (Codex hooks cannot ask the user themselves: PreToolUse only supports deny.)
# - Any other command: does nothing.
# Usage: configured in ~/.codex/hooks.json (PreToolUse, matcher "Bash"). Needs jq.
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly RULES_FILE="${SCRIPT_DIR}/git-rules.md"
readonly STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-git-guard"

# git invoked as a command (start of line or after ; & | ( or whitespace)
readonly GIT_CALL='(^|[;&|(]|[[:space:]])git[[:space:]]'
readonly DESTRUCTIVE='git[[:space:]].*(reset[[:space:]].*--hard|push[[:space:]].*(--force|-f([[:space:]]|$)|--force-with-lease|[[:space:]]\+)|clean[[:space:]].*-[a-zA-Z]*f|branch[[:space:]].*-D|checkout[[:space:]](.*[[:space:]])?(--|\.)([[:space:]]|$)|restore[[:space:]]|stash[[:space:]]+(drop|clear)|rebase[[:space:]]|commit[[:space:]].*--amend|--no-verify|config[[:space:]]+(--global[[:space:]]+)?(user\.|core\.hooksPath|commit\.gpgsign))'
# The confirmed form: one plain git command, nothing chained, redirected or expanded,
# so Codex matches it against the `prompt` rule instead of running it unseen.
readonly CONFIRMED='^[[:space:]]*git[[:space:]]+-c[[:space:]]+mk96\.confirmed[[:space:]]+[^;&|<>$`(){}*?!\\]+$'
readonly CONFIRM_REASON='git-guard: this git command can lose work or rewrite history. Ask the user to confirm it in chat, saying what would be lost. Only after they confirm, run it alone (no &&, ;, | or redirections) as: git -c mk96.confirmed <same arguments>. Codex will then ask the user to approve it.'
readonly ALONE_REASON='git-guard: a confirmed destructive git command must run alone, with plain arguments (no &&, ;, |, redirections, variables or wildcards), so Codex asks the user to approve it.'

deny() {
  jq -n --arg reason "$1" '{hookSpecificOutput: {
    hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

main() {
  local input command session_id marker
  input="$(cat)"
  command="$(jq -r '.tool_input.command // ""' <<<"$input")"
  session_id="$(jq -r '.session_id // "unknown"' <<<"$input")"

  [[ "$command" =~ $GIT_CALL ]] || exit 0

  # Deny answers carry only the decision and reason: a field Codex does not support there
  # marks the hook as failed and the command runs anyway. The rules context waits for
  # the next allowed git command.
  if [[ "$command" =~ $DESTRUCTIVE ]]; then
    [[ "$command" == *"mk96.confirmed"* ]] || deny "$CONFIRM_REASON"
    [[ "$command" != *$'\n'* && "$command" =~ $CONFIRMED ]] || deny "$ALONE_REASON"
  fi

  mkdir -p -- "$STATE_DIR"
  marker="${STATE_DIR}/${session_id}"
  [[ -f "$marker" ]] && exit 0
  touch -- "$marker"
  jq -n --arg ctx "$(cat -- "$RULES_FILE")" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
}

main "$@"
