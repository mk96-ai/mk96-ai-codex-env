# mk96-ai-codex-env

Codex environment of Markes96: global instructions, skills (including the personal rules and commands), custom agents, command rules, hooks, plugins, preferences and permission profile.

It is written and read by the [mk96-env plugin for Codex](https://github.com/mk96-ai/mk96-ai-codex-env-plugin):

- `$mk96-env:export` stores the environment of a machine in `env/` and pushes it.
- `$mk96-env:import` brings it into another machine's `~/.codex` and `~/.agents/skills`.

Do not edit `env/` by hand: change the environment on a machine and export it.

To start your own environment from this one, fork this repository and point the plugin to your fork.

## Contents

| Piece | In `env/` | What it does |
|---|---|---|
| Global instructions | `AGENTS.md` | Communication, planning, safety and verification principles for every session |
| Personal rules | `skills/rules-*` | Coding rules per language (`coding`, `java`, `python`, `javascript-typescript`, `cpp`, `shell`, `docker`); `AGENTS.md` tells Codex to load them before editing code |
| Skills | `skills/<name>` | Frameworks, architecture, protocols, platforms and UX guidance, loaded when the task matches |
| Commands | `skills/<prefix>_<name>` with `agents/openai.yaml` | Run only when invoked, e.g. `$git_commit`, `$project_scan --full` |
| git-guard | `hooks/git-guard`, `rules/git-guard.rules` | Adds the git rules on the first git command of a session; destructive git commands, and new branches or commits that break Git Flow or Conventional Commits in repos that follow them, are blocked until the user confirms, then Codex asks for approval |
| protect-files | `hooks/protect-files` | Blocks edits to dependency lock files and environment files |
| Permission profile | `settings.json` → `permissions.mk96`, `default_permissions` | Like the built-in `:workspace` profile, plus environment files (`.env`, `.env.local`...) that sandboxed commands cannot read |
| Plugins | `plugins.json` | superpowers, context7 and mk96-env, with their Git marketplaces |
| Preferences | `settings.json` | Model, reasoning effort and memories |

Hooks only run after they are reviewed and trusted in Codex (`/hooks`), once per machine and again after each change.
