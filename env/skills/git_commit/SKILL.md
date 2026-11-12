---
name: git_commit
description: "Commit the current changes with a clear message (does not push)"
---

Create a git commit for the current changes. The user asked for this commit explicitly. Do not push.

Context (run these commands first and use their output):
- Branch: `git branch --show-current`
- Status: `git status --short`
- Recent commits (style reference): `git log --oneline -10`

Steps:
1. If the branch is `main`, `master` or `develop`, stop and ask the user before continuing.
2. Read the diff (`git diff HEAD`) and understand what changed and why.
3. If the diff contains a secret (key, token, password, connection string), stop and warn the user without repeating it. Never stage `.env` files or similar.
4. Stage only the files that belong to this change. If unrelated changes are mixed in, tell the user which ones were left out.
5. Write the message in English. If the recent commits follow their own style, follow it; otherwise use Conventional Commits as described in the git rules (`<type>(<scope>)!: <summary>`). Short subject line focused on the why; add a body only if the change is not obvious. Follow the commit attribution instructions of the session, if any.
6. Show the user the staged files and the final message, then create the commit.
7. Never use `--no-verify` or amend existing commits. If a hook fails, report the failure and fix the cause.

Extra instructions from the user (optional): <the text the user wrote with the skill invocation, if any>

Reply following the global communication rules.
