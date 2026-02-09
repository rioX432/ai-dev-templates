Review the current branch's changes against the base branch.

## Steps

1. Identify the base branch and current branch
2. Read all changed files (not just diff — full file context)
3. Run the review checklist below, skipping sections not applicable to this project
4. Use Gemini MCP (`mcp__gemini-cli__ask-gemini`) for cross-review on non-trivial changes
5. Output findings grouped by severity: Critical / Warning / Suggestion / Nit

## Review Checklist

### Phase 1: Architecture & Design (Google Engineering Practices)
- [ ] Change improves overall code health (not necessarily "perfect")
- [ ] Follows project architecture defined in CLAUDE.md
- [ ] SRP: each class/function has a single responsibility
- [ ] No unnecessary complexity — simplest solution that works
- [ ] Technical decisions based on data/standards, not personal preference

### Phase 2: Mobile — Android (Compose) [skip if not applicable]
- [ ] No unnecessary recomposition (missing `remember`, `key`, `derivedStateOf`)
- [ ] No backwards write in composition
- [ ] LazyColumn/LazyRow has `key` parameter
- [ ] State read deferred where possible (lambda modifiers)
- [ ] `@Stable`/`@Immutable` on data classes passed to composables
- [ ] No IO/network on main thread
- [ ] `LaunchedEffect`/`DisposableEffect` keys are correct
- [ ] No `GlobalScope`, no `!!`

### Phase 3: Mobile — iOS (SwiftUI) [skip if not applicable]
- [ ] `[weak self]` in closures that capture self
- [ ] No global ViewModel singletons
- [ ] `@StateObject` scoped to owning view
- [ ] `.task` cancellation handled (`.onDisappear` cleanup)
- [ ] No force unwrap (`!`)
- [ ] `deinit` logging on ViewModels for leak detection
- [ ] Combine subscriptions cancelled on disappear

### Phase 4: KMP Shared Code [skip if not applicable]
- [ ] All `expect` declarations have `actual` for every target
- [ ] Business logic uses interfaces, not `expect class`
- [ ] Shared code changes have unit tests in `commonTest`
- [ ] No platform-specific imports in `commonMain`

### Phase 5: Data & Performance
- [ ] No memory leaks (long-lived references to short-lived objects)
- [ ] No heavy work on main/UI thread
- [ ] No unnecessary network calls or redundant API requests
- [ ] Caching used where appropriate

### Phase 6: Security (OWASP)
- [ ] No hardcoded secrets, passwords, API keys
- [ ] No sensitive data in logs
- [ ] User input sanitized
- [ ] Local storage encrypted where needed

### Phase 7: Quality
- [ ] Error handling covers all failure cases
- [ ] UI strings externalized (no hardcoded text)
- [ ] Naming is clear and consistent
- [ ] Tests added/updated for changed code
- [ ] Dark mode verified (if applicable)
- [ ] Accessibility: Dynamic Type / VoiceOver / TalkBack / contrast

## Output Format

```
## Review Summary

**Branch:** feature/xxx → main
**Files changed:** N
**Risk level:** Low / Medium / High

### Critical (must fix)
- [file:line] description

### Warning (should fix)
- [file:line] description

### Suggestion (nice to have)
- [file:line] description

### Nit (optional)
- [file:line] description

### Cross-Review (Gemini)
- summary of Gemini's findings
```
