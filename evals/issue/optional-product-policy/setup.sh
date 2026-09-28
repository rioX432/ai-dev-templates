#!/usr/bin/env bash
# A company repository with engineering guidance only: no product policy, Core Values, or Won't Do.
set -euo pipefail

mkdir -p src/reports test

cat > AGENTS.md <<'MD'
# billing-reports

Internal service that renders monthly billing reports for the finance team.

## Commands

```text
test: pnpm test        # success: "Tests: N passed, 0 failed"
lint: pnpm lint        # success: exit 0, no output
```

## Architecture

- `src/reports/` renders report pages; `src/reports/table.ts` builds the invoice table.
MD

cat > src/reports/table.ts <<'TS'
export interface InvoiceRow { id: string; customer: string; amountCents: number }

export function renderTable(rows: InvoiceRow[]): string {
  return rows.map((r) => `${r.id}\t${r.customer}\t${(r.amountCents / 100).toFixed(2)}`).join("\n");
}
TS

git init -q
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "initial project"
