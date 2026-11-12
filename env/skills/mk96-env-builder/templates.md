# Templates for mk96-env-builder

Contents: Language rule skill · Skill · Command skill · Hook · Command rule · Permission deny · Research brief for a subagent · Report to the user

## Language rule skill (`~/.agents/skills/rules-<lang>/SKILL.md`)
```markdown
---
name: rules-<lang>
description: "Use when writing, changing or reviewing <Language> code (files: **/*.<ext>, **/<build-file>). Personal rules for <Language> code and its build files; load before editing such files."
---

# <Language>

Applies on top of `rules-coding`. Frameworks and architecture come from skills.

## Naming
## Language
## Errors
## Tests
## Build

Sources: <source (license)>, <source (license)>.
```
Add it to the `rules-<language>` list in `~/.codex/AGENTS.md`.

## Skill (`~/.agents/skills/<name>/SKILL.md`)
```markdown
---
name: <name>
description: Use when <situations, technologies, symptoms that should trigger it>.
---

# <Title>

## Overview
<Core idea in 1-2 sentences.> **Good fit for:** <cases and stacks> (architecture skills only).
<One line pointing to related skills instead of repeating them.>

## <Topic sections with imperative bullets>

## Common mistakes
| Mistake | Fix |
|---|---|

Sources: <source (license)>, <source (license)>.
```

## Command skill (`~/.agents/skills/<prefix>_<name>/`)
`SKILL.md` as above with `description: "<what it does>"`, plus `agents/openai.yaml`:
```yaml
policy:
  allow_implicit_invocation: false
```
Context the command needs: "Context (run these commands first and use their output):" followed by `- Label: \`<command>\`` lines. User input: "<the text the user wrote with the skill invocation, if any>".

## Hook (`~/.codex/hooks/<name>/<name>.sh`)
```bash
#!/usr/bin/env bash
# <name>: Codex PreToolUse hook for <Bash|apply_patch>. <What it does in one line>.
# Usage: configured in ~/.codex/hooks.json (PreToolUse, matcher "<Bash|apply_patch>"). Needs jq.
set -euo pipefail

main() {
  local input command
  input="$(cat)"
  command="$(jq -r '.tool_input.command // ""' <<<"$input")"
  [[ "$command" =~ <pattern> ]] || exit 0
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: "<why, and what to do instead>"}}'
}

main "$@"
```
`hooks.json` entry (merge with `jq`, never replace existing hooks):
```json
{"matcher": "<Bash|apply_patch>", "hooks": [{"type": "command", "command": "\"$HOME/.codex/hooks/<name>/<name>.sh\"", "timeout": 10}]}
```
For `apply_patch`, `tool_input.command` is the patch: file paths are on `*** Add File:`, `*** Update File:`, `*** Delete File:` and `*** Move to:` lines.
Pipe-test: `jq -nc --arg c '<cmd>' '{session_id:"t",tool_name:"Bash",tool_input:{command:$c}}' | <script>`. Then trust it in `/hooks`.

## Command rule (`~/.codex/rules/<name>.rules`)
```python
prefix_rule(
    pattern = ["<program>", "<subcommand>"],
    decision = "prompt",  # or "forbidden"
    justification = "<why>",
    match = ["<program> <subcommand> <example args>"],
    not_match = ["<program> <other>"],
)
```
Test: `codex execpolicy check --rules ~/.codex/rules/<name>.rules -- <command>`.

## Permission deny (`~/.codex/config.toml`)
```toml
[permissions.mk96.filesystem.":workspace_roots"]
"**/<file>" = "deny"
```
Deny means no read and no write for sandboxed commands, inside every workspace root.

## Research brief for a subagent
```
Task: <create|review|split> <path(s)>. Touch only these files.
Context: read <neighbour files> and do not repeat them; mirror the style of <reference skill>.
Validate every line against popular, well-starred sources (web): <official docs, current version>, <2-4 repos>. Give approx stars + license.
Review both directions: fix wrong/outdated, remove noise/duplicates, add only high-value items.
Format: <frontmatter>, English body, max <N> words, "Sources:" line. Validate frontmatter with python3 -I + yaml.
Report in SPANISH plain words (under 400 words): what changed and why, word count, sources, rejected items.
```

## Report to the user (Spanish)
```markdown
## <pieza>

**Lo que está mal**
| # | Qué pone ahora | Problema | Cambio |

**Lo que sobra** — <lista corta>

**Lo que falta**
| # | Qué es, en palabras normales | Por qué aporta | Recomendación |

**Descartados** — <lista corta con el porqué>

¿Lo aplico así?
```
