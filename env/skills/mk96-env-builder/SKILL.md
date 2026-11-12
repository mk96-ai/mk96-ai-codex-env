---
name: mk96-env-builder
description: Use when creating, splitting, reviewing or updating the personal Codex environment (~/.codex/AGENTS.md, rules-* and other skills in ~/.agents/skills, hooks, command rules, permission profile), e.g. a new technology, framework, architecture, protocol or domain-specific UX needs its own guidance, or a behavior must be enforced.
---

# mk96-env builder

## Overview
Every piece of guidance has **one concern, one home and evidence behind it**. Pick the right mechanism, keep it separate from its neighbours, validate it against professional sources, let the user decide, then verify it really loads.

**REQUIRED BACKGROUND:** templates in `templates.md` (same folder).

Copy this checklist and tick it as you go:
```
- [ ] 1. Mechanism chosen
- [ ] 2. Scope checked against existing pieces (split or pointer decided)
- [ ] 3. Sources researched (official + popular, stars/license noted)
- [ ] 4. Draft written within budget
- [ ] 5. Report shown to the user and answered
- [ ] 6. Verified (frontmatter, refs, hook/rule/permission tests)
- [ ] 7. Wired up (pointers, project AGENTS.md)
```

## 1. Choose the mechanism
| Need | Mechanism | Loads |
|---|---|---|
| Applies to every session (tone, safety, secrets) | Global `~/.codex/AGENTS.md` | Always |
| Applies to a language/file type | Skill `~/.agents/skills/rules-<lang>/SKILL.md`, file globs in its description, listed in `AGENTS.md` | When the model loads it before editing those files |
| Framework, architecture, protocol, platform, domain UX | Skill `~/.agents/skills/<name>/SKILL.md` | When its description matches the task |
| A command the user runs by hand (`$name`) | Skill + `agents/openai.yaml` with `allow_implicit_invocation: false` | Only when invoked |
| Must happen or be blocked no matter what | Hook in `~/.codex/hooks.json` (script in `~/.codex/hooks/<name>/`) | On the tool event, once trusted in `/hooks` |
| A shell command must ask or be refused | Command rule `~/.codex/rules/<name>.rules` (`prompt` / `forbidden`) | Always |
| A file must never be read by commands | `deny` glob in the `mk96` permission profile of `config.toml` | Always (sandboxed commands) |
| Only one repo | That repo's `AGENTS.md` | In that repo |

- Codex has no path-scoped rules and no `ask` from hooks: `PreToolUse` can only deny, add context or rewrite. Approval prompts come from command rules.
- Safety-critical guidance never lives only in a skill: skills load by judgment, hooks, rules and permissions don't.
- `~/.codex/rules/default.rules` belongs to Codex (commands approved in its UI): never edit or sync it.

## 2. Scope and separation
Layers never mix in one file:

| Layer | Example | Home |
|---|---|---|
| Generic coding | TDD, clean code | skill `rules-coding` |
| Language + its build tool | Java + Maven | skill `rules-<lang>` |
| Framework | Spring, Quarkus, Angular | skill `<lang>-<framework>` or `<framework>` |
| Architecture | hexagonal, MVC | skill `arch-<style>` |
| Protocol / integration | REST, messaging (+ one skill per broker) | skill `api-rest`, `messaging`, `messaging-kafka` |
| Cross-framework technology | JPA/Hibernate | skill `<lang>-<tech>` (e.g. `java-jpa`) |
| Platform / UI toolkit | JavaFX, Win32, GTK | skill `<lang>-<platform>` |
| Domain UX | dashboards, social pages | skill `ux-<domain>` |

- List what exists first (`ls ~/.agents/skills ~/.codex/hooks ~/.codex/rules`) and read the neighbours.
- Overlap → one line pointing to the other piece, never a copy.
- An existing piece mixing two layers → propose the split.
- Architecture skills say when they are a **good fit** and for which stacks; they never compare themselves with others.
- A pattern from one project (class names, startup orchestration) goes to that project's `AGENTS.md`, not to a generic skill. Client/company names never appear.

## 3. Research
- Official docs of the **current** version plus at least two popular sources (prefer 10k+ stars: openai/skills, anthropics/skills, github/awesome-copilot, well-known style guides). Record approx stars and license.
- UX and design pieces: professional sources only (platform guidelines, NN/g, Baymard, WCAG...); the user's own projects are never a design reference.
- Paraphrase CC-BY-SA and style-guide text; adapt MIT/Apache/CC0 freely.
- Facts not checked against a source are marked as such in the report.
- Several pieces at once: one subagent per piece with the research brief from `templates.md`.

## 4. Draft
- Body in English; the user reads explanations in Spanish.
- `rules-*` skill: description "Use when writing, changing or reviewing <language> code (files: <globs>)...", ≤400 words. Other skills: `name` + `description` starting "Use when..." with triggers only (no workflow), ≤550 words; heavy reference in a supporting file. Front-load trigger words: Codex shortens descriptions when many skills are installed.
- Concrete imperative bullets, a "Common mistakes" table, a final `Sources:` line.
- Never repeat `rules-coding`, the language rule or sibling skills.

## 5. Review with the user
- Compare in **both directions**: missing, wrong/outdated, superfluous.
- Present in Spanish, plain words, using the report table in `templates.md`: what, why it adds value, recommendation. Nothing is applied before the user answers, except when the user explicitly delegated that piece.
- Expert areas of the user: their call wins over sources. Other areas: rely on the comparison.

## 6. Verify
- Frontmatter parses (`python3 -I` + `yaml.safe_load`), `name` equals the folder name, word count within budget.
- The skill is visible: `codex debug prompt-input hi | grep <name>` (commands with `allow_implicit_invocation: false` are not listed there, by design).
- No stale references: `grep -rn "<old-name>" ~/.codex/AGENTS.md ~/.agents/skills`.
- Hooks: pipe-test with sample JSON, then trust them in `/hooks` and trigger once in a session.
- Command rules: `codex execpolicy check --rules <file> -- <command>`; keep `match`/`not_match` examples in the rule.
- Permissions: `codex sandbox -- cat <dummy file>` in a scratch folder, then delete the dummy file.

## 7. Wire up
- Update pointers in related pieces (e.g. the framework list in `rules-java`, the `rules-*` list in `AGENTS.md`).
- Projects that use a new skill name it in their `AGENTS.md`.
- Export with `$mk96-env:export` only when the user asks.

## Common mistakes
| Mistake | Fix |
|---|---|
| Framework rules inside the language rule | Separate skill |
| Skill imposes an architecture | Architecture lives in `arch-*` skills |
| Copying a sibling's content | One-line pointer |
| Project-specific pattern in a generic skill | Project `AGENTS.md` |
| Version facts from memory | Check current docs |
| Applying changes before the user decides | Present the report table first |
| Hook returns `permissionDecision: "ask"` | Not supported: deny with a reason, plus a `prompt` command rule |
| Hook returns `continue`, `stopReason` or `suppressOutput` on `PreToolUse` | Unsupported there: Codex marks the hook as failed and runs the command anyway; deny answers carry only the decision and reason |
| Writing `sandbox_mode` in `config.toml` | It silently disables the `mk96` permission profile |
