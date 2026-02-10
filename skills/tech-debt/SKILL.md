---
description: "Scan the codebase for technical debt and create GitHub Issues for high-severity findings. Use periodically or during autonomous improvement cycles."
user-invocable: true
---

Scan the codebase for technical debt and refactoring opportunities, then create GitHub Issues for actionable items.

## Steps

1. Scan the codebase for the patterns listed below
2. For each finding, assess severity (High / Medium / Low) and effort (S / M / L)
3. Group findings by category
4. For High severity items, create GitHub Issues using `gh issue create`
5. Output a summary report

## Detection Patterns

### Code Smells
- [ ] Duplicated code (3+ similar blocks)
- [ ] Long functions (50+ lines)
- [ ] Large files (500+ lines)
- [ ] Deep nesting (4+ levels)
- [ ] God classes (too many responsibilities)
- [ ] Dead code (unused functions, imports, variables)
- [ ] TODO/FIXME/HACK comments left in code

### Architecture
- [ ] Circular dependencies between modules
- [ ] Layer violations (UI calling data layer directly, skipping domain)
- [ ] Platform-specific code in shared module (`commonMain`)
- [ ] Missing abstractions (concrete classes where interfaces should be)
- [ ] Inconsistent patterns across similar features

### Performance
- [ ] N+1 queries in Room DAOs
- [ ] Missing database indexes on frequently queried columns
- [ ] Unbounded lists without pagination
- [ ] Heavy computation on main thread
- [ ] Missing `remember`/`key` in Compose (unnecessary recomposition)
- [ ] Memory leaks (retain cycles in Swift, leaked references in Kotlin)

### Testing
- [ ] Public functions without unit tests
- [ ] Test files with no assertions
- [ ] Flaky tests (if CI history available)
- [ ] Missing edge case coverage (null, empty, boundary values)

### Dependencies
- [ ] Outdated dependencies (check against latest stable versions)
- [ ] Deprecated API usage
- [ ] Security vulnerabilities in dependencies (if audit tools available)

### Mobile-Specific
- [ ] Hardcoded strings (not externalized)
- [ ] Missing accessibility attributes
- [ ] Missing dark mode support
- [ ] Force unwrap (`!`) in Swift or `!!` in Kotlin

## Issue Creation

For each High severity finding, create a GitHub Issue:

```
gh issue create \
  --title "Tech Debt: {concise description}" \
  --body "{detailed description with file locations and suggested fix}" \
  --label "tech-debt"
```

## Output Format

```
## Tech Debt Report

**Scanned:** N files
**Findings:** X High, Y Medium, Z Low
**Issues created:** N

### High Severity
| # | Category | File | Description | Effort | Issue |
|---|----------|------|-------------|--------|-------|
| 1 | ... | file:line | ... | S/M/L | #XX |

### Medium Severity
| # | Category | File | Description | Effort |
|---|----------|------|-------------|--------|

### Low Severity
(summary only)
```
