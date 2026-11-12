---
name: git_branch_switch
description: "Switch to another branch safely (warns about uncommitted work)"
---

Switch to another branch. The user asked for this explicitly.

Branch to switch to (if empty, list the local branches and ask which one): <the text the user wrote with the skill invocation, if any>

Context (run these commands first and use their output):
- Current branch: `git branch --show-current`
- Status: `git status --short`

Steps:
1. If there are uncommitted changes, tell the user which files and ask what to do (carry them over, commit them, or stash them). Never discard changes.
2. If the branch exists only on the remote, fetch and create a local tracking branch (`git switch <name>`).
3. If the branch does not exist anywhere, say so and suggest similar names. Do not create it.
4. Switch, then confirm in one line: previous branch, new branch, and whether it is behind its remote.

Reply following the global communication rules.
