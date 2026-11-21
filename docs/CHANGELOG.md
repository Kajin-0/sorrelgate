# Sorrelgate — Append-only timestamped change log

Every substantive change gets an ISO-8601 timestamp with timezone, scope, tested results (or **not run**), limitations, and GitHub commit/PR. Keep newest entries first and update `docs/STATUS.md` in the same change.

## 2026-11-20T23:08:11-05:00 — Initialize Sorrelgate specification and agent handoff
- **Scope:** Rename the product Sorrelgate and establish the selected GitHub repository as its context and documentation source.
- **Work:** Root README / AGENTS, comprehensive product specification, Codex instructions, milestone checklist, two California seller-side office-editable workflows, current-status tracker, architectural decisions, security, tests and release policy.
- **Verified:** GitHub repo was public and empty with authenticated push/admin access; JSON workflow parsed; source docs available.
- **Not tested:** No Mac app, Xcode build, OCR benchmark, PDF processing, LLM action, signed installer or pilot.
- **Risk:** Repo must be changed to private before adding proprietary code.
- **Reference:** Initial GitHub documentation commits.

### Template
```text
## YYYY-MM-DDTHH:MM:SS±HH:MM — summary
- Scope / reason:
- Changed code / documents:
- Tests (machine, command, exit status, measured outcome; or NOT RUN):
- Limitations / blockers:
- Commit / PR:
- Next executable step:
```
