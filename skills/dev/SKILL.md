---
description: "Autonomous end-to-end issue resolution: investigate → plan → implement → test → review → PR. Use with issue number as argument."
user-invocable: true
argument-hint: "{issue-number}"
---

Autonomously resolve GitHub Issue #$ARGUMENTS from investigation to PR creation.

## Phase 1: Investigation

1. Run `gh issue view $ARGUMENTS --json title,body,labels,assignees,comments` to read the issue
2. Understand requirements, acceptance criteria, and any discussion
3. Explore related code with Grep and Glob to find affected areas
4. If design is unclear, use Codex MCP (`mcp__codex__codex`) to confirm approach

## Phase 2: Planning

1. Draft an implementation plan:
   - Files to modify/create
   - Key changes in each file
   - Testing strategy
   - Risk assessment
2. Present the plan to the user for approval
3. If `--auto-approve` was passed in arguments, skip user confirmation

## Phase 3: Implementation

1. Create a feature branch: `git checkout -b feature/issue-$ARGUMENTS-{short-description}`
2. Implement changes according to the approved plan
3. Follow project CLAUDE.md conventions
4. Keep commits atomic and well-described

## Phase 4: Testing

1. Write or update tests for changed code (delegate to test-writer agent if available)
2. Run the project's build command to verify compilation
3. Run the project's test command to verify all tests pass
4. If tests fail, fix and retry (max 3 attempts before asking user)

## Phase 5: Self-Review

1. Read `REVIEW.md` at the project root for review criteria
2. Run `/ai-dev:review` to execute multi-agent review (Bug/Security + Architecture/UI agents)
3. Run security-reviewer agent if available
4. If Critical or Warning findings exist, go back to Phase 3 and fix
5. Extract reusable insights into `docs/claude/review_points.md`

## Phase 6: PR Creation

1. Stage and commit all changes with a concise message
2. Push the branch to remote
3. Create PR using the project's template:
   - Title: `#$ARGUMENTS {concise description}`
   - Body: fill Description section, link `Closes #$ARGUMENTS`
   - Leave other template sections as-is
4. Report completion with PR URL

## Error Handling

- If the issue doesn't exist, report and stop
- If the branch already exists, ask user whether to continue on it or create a new one
- If build/test fails after 3 attempts, report findings and ask user for guidance
- If review finds Critical issues that can't be auto-fixed, report and ask user
