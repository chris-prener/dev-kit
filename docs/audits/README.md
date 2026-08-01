# Audit Ledgers

Records of full-repo audit *passes*. Findings survive as GitHub issues labeled `audit-finding`; passes do not survive anywhere else — these docs are that record. Each ledger states what a pass found, how its findings are fingerprinted, and what it demonstrably examined, so a later pass can separate known defects from new ones mechanically.

Three instruments, easily confused — see [the three-instrument model](2026-07-29-full-repo-audit.md#the-three-instrument-model) before treating any pass's number as comparable to another's.

| Doc | Pass namespace(s) | Findings | Status | Related |
|---|---|---|---|---|
| [2026-08-01-pass-1b-scope-brief.md](2026-08-01-pass-1b-scope-brief.md) | `adversarial-review-2026-08-01` | — | scope brief; pass pending | #25, O1 KR1.1 |
| [2026-07-29-full-repo-audit.md](2026-07-29-full-repo-audit.md) | `manual-repo-review-2026-07-29`, `session-review-2026-08-01` | 14 | complete; coverage partial (19/58 skills) | #16 (Epic B), O1 KR1.4 |
