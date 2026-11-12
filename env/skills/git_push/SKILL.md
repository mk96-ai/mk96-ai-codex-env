---
name: git_push
description: "Push the current branch after showing what will be sent"
---

Push the current branch. The user asked for this push explicitly.

Context (run these commands first and use their output):
- Branch: `git branch --show-current`
- Status: `git status --short --branch`
- Remotes: `git remote -v`

Steps:
1. If the branch is `main` or `master`, stop and ask the user before continuing.
2. List the commits that will be sent (`git log @{u}..HEAD --oneline`, or all commits of the branch if there is no upstream yet) and the destination remote and branch.
3. If there are uncommitted changes, mention it in one line (they will not be pushed).
4. Push. If the branch has no upstream, use `git push -u origin <branch>`.
5. Never force push (`--force`, `--force-with-lease`). If the push is rejected, explain why and ask what to do.

Extra instructions from the user (optional): <the text the user wrote with the skill invocation, if any>

Reply following the global communication rules.
