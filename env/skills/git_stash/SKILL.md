---
name: git_stash
description: "Save uncommitted work temporarily (stash) with a clear label"
---

Put the uncommitted work aside temporarily so the working folder is clean. The user asked for this explicitly.

Label for the stash (optional; if empty, build one from the branch and the main files): <the text the user wrote with the skill invocation, if any>

Context (run these commands first and use their output):
- Branch: `git branch --show-current`
- Status: `git status --short`

Steps:
1. If there is nothing to stash, say so and stop.
2. List what will be saved. Untracked files are included (`git stash push -u`); mention it if there are any. Ignored files are not included.
3. Stash with a descriptive message in English: `git stash push -u -m "<label>"`.
4. Confirm the stash name and that the working folder is clean. Remind that `$git_stash_pop` brings the work back.

Reply following the global communication rules.
