---
name: project_review_docs
description: "Review comments and documentation of the whole project for outdated or missing parts. Read-only"
---

Review comments and documentation of the whole project. Read-only: do not modify anything.

Focus, folder or extra instructions (optional): <the text the user wrote with the skill invocation, if any>

Steps:
1. Read the README, docs folder, config or properties files and examples, then compare them with what the code really does (commands, paths, settings, setup steps).
2. Sample the code for comment quality against the user's rules: written in English, explain why and not what, not excessive, public functions and classes with docstrings, `TODO(reason)` or `FIXME(reason)` with a reason.
3. Report: outdated or wrong documentation (most important first), missing documentation a new developer would need, and comment excess or noise. Maximum 10 findings; offer the rest on request.
4. If the project is large, say which areas were covered.

Reply following the global communication rules.
