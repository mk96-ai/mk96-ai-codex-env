---
name: git_pr_review
description: "Review a pull request (number or URL; defaults to the current branch's PR). Read-only"
---

Review a pull request. Read-only: do not post comments, approve, merge or change anything unless the user asks afterwards.

PR to review (number or URL; empty means the PR of the current branch): <the text the user wrote with the skill invocation, if any>

Steps:
1. Fetch the PR description, commits, changed files, full diff and CI status (`gh pr view`, `gh pr diff`, `gh pr checks`).
2. Understand the intent from the description, then check that the diff does what it says and nothing else.
3. Review against the user's global rules:
   - Readable code, separation of responsibilities, small functions, clear names, no magic values.
   - Errors never swallowed silently; logging used properly and without secrets or personal data.
   - Tests protect real behavior (not trivial or redundant); production code has tests.
   - Comments and docs in English, useful, not excessive, and not outdated by the change.
   - Secrets, unvalidated external input, SQL built by concatenation, new dependencies, migrations.
4. Report, ordered by severity: blocking issues, recommended changes, minor notes. For each: file and line, what is wrong, why it matters, and a suggested fix in plain words.
5. Close with a verdict (ready to merge / needs changes) and what the user should decide.

Reply following the global communication rules.
