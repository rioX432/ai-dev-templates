---
description: "Create a pull request for the current branch. Use when ready to submit changes or during fix-issue Phase 6."
user-invocable: true
---

Create a pull request for the current branch.

## Steps

1. Run `git status` and `git diff` to understand all changes
2. Check if the current branch has a remote tracking branch; push if needed
3. Run `git log` and `git diff <base-branch>...HEAD` to understand ALL commits (not just the latest)
4. Look up the related GitHub Issue from branch name or commit messages
5. Draft PR title and body using the project's PR template at `.github/pull_request_template.md`
6. Create the PR with `gh pr create`

## Rules

- Title format: `#{Issue Number} {concise description}` (e.g., `#42 Add notification quiz for iOS`)
- If no GitHub Issue exists, omit the number
- Title must be under 70 characters
- Description section: fill in with bullet points summarizing changes
- Other template sections: leave as-is (commented out)
- No AI stamps, no Co-Authored-By
- Always set base branch explicitly
- Link related issues with `Closes #XX` in the body if applicable
