---
name: git_branch_list
description: "List branches with last activity, sync state and whether they are already merged. Read-only"
---

Show the branches of the repository in a clear table. Read-only: do not change anything.

Filter or extra instructions (optional): <the text the user wrote with the skill invocation, if any>

Context (run these commands first and use their output):
- Branches: `git branch -vv`
- Current: `git branch --show-current`

Steps:
1. For each local branch show: name, last commit date and subject, ahead or behind its remote, and whether it is already merged into the main branch (`main` or `master`).
2. Mark the current branch, branches whose remote was deleted (`gone`), and branches with no remote.
3. Finish with one line suggesting which branches look safe to clean up, pointing to `$git_branch_clean`. Do not delete anything.

Reply following the global communication rules.
