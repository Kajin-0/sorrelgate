# Sorrelgate — Append-only timestamped change log

Every substantive change gets an ISO-8601 timestamp with timezone, scope, tested results (or **not run**), limitations, and GitHub commit/PR. Keep newest entries first and update `docs/STATUS.md` in the same change.

## 2026-11-20T23:19:47-05:00 — Public repository approved and agent handoff corrected
- **Reason:** Owner explicitly stated public GitHub visibility is acceptable; priority is useful software and steady sales.
- **Changes:** Removed private-repository stop gate from AGENTS.md, README, current status, Codex instructions, licensing notes, and implementation checklist; added ADR-007 superseding ADR-005; corrected malformed STATUS header; deprecated GitHub issue #8.
- **Verified:** GitHub main contained 20 documented files including AGENTS, product specification, change log, current status, and workflows; milestone issues #1–#7 exist.
- **Tests:** Documentation consistency and repository presence review; **native Mac build, OCR and AI execution NOT RUN**.
- **Security constraint:** Public repository does not permit public client contracts, credentials, licensed blank forms, private office material or signing keys.
- **Next:** Codex begins M0 on authorized Mac; no visibility requirement.

## 2026-11-21T04:11:41.409Z — Verified GitHub bootstrap and opened milestone issues
- **Scope:** Opened GitHub issues #1–#7 (M0–M6) and #8 (make repository private before adding proprietary source); updated README and current status with links.
- **Verification:** Confirmed 20 repository files, exact required handoff paths, 21 starter tasks in JSON, and GitHub main branch writes. Reviewed AGENTS.md and STATUS.md remotely.
- **Not run:** Native Mac build, OCR processing, agent execution and customer pilot. These remain NOT STARTED.
- **Outstanding blocker:** Repository is still public; owner must switch it to private before source development.
- **Commit:** See latest documentation commit on main.

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
