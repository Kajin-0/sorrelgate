# Sorrelgate — Current verified state

**Last checked:** 2026-11-20T23:19:47-05:00 (America/New_York)
**Phase:** Planning and repository bootstrap; before M0.
**Repository:** https://github.com/Kajin-0/sorrelgate
**Visibility:** PUBLIC — deliberately accepted by owner. Not a blocker for engineering or commercial development.
**Release:** NOT STARTED. No app implementation, Xcode build, installer, OCR accuracy evaluation, or LLM action verified.

## Verified baseline
- Connected GitHub owner: Kajin-0; repository access includes write/admin permissions.
- Root `AGENTS.md`, detailed scope, architecture, Codex instructions, milestone gates, two workflow templates, test plan, security policy, decision register and change log are in GitHub.
- 20 documentation/configuration files were established on `main`; issues #1–#7 define M0–M6. Visibility-only issue #8 has been superseded and should be closed.
- The starter California seller-side workflow is editable and administrative, **not** an authoritative legal checklist.
- Owner priority: **ship useful, low-friction Mac software and earn steady one-time-license sales**. Public source visibility is accepted. Never put actual customer/private data or credentials in Git.

## Milestone gates

| Milestone | State | Verified evidence |
|---|---|---|
| M0 Native Mac foundation / persistence | NOT STARTED | No Xcode run |
| M1 PDF import / OCR / preview / checklists / export | NOT STARTED | No implementation |
| M2 Office profiles / XLSX / versioning | NOT STARTED | No implementation |
| M3 Classification / linked document checks | NOT STARTED | No evaluation |
| M4 Timeline / draft communications / exports | NOT STARTED | No implementation |
| M5 Guarded LLM-controlled actions | NOT STARTED | No agent scenarios run |
| M6 Commercial Mac release | NOT STARTED | No notarized build or pilot |

## Next executable actions
1. On an authorized Apple-silicon Mac with Xcode, verify and record actual macOS/Xcode/Swift versions and Apple Foundation Models availability.
2. Start [M0](https://github.com/Kajin-0/sorrelgate/issues/1), then the M1 vertical slice: create transaction → import PDFs → OCR/preview → link editable checklist → export safely → quit/reopen and verify data persistence.
3. Use synthetic documents for tests and obtain any real samples only with appropriate authorization and redaction. Never commit client records.
4. Keep source-code licensing, user-facing payment/license terms, support and commercial packaging explicit; do not assume public GitHub means the product is freely licensed.

## Handoff + maintenance
At each session start: read root `AGENTS.md`, this file, newest `docs/CHANGELOG.md`, then the linked specification and open issues. Re-check real git history and implementation results rather than trusting old descriptions.

Each substantive change must update this file and append a timezone-qualified timestamp to `docs/CHANGELOG.md`; record architectural or product decisions in `docs/DECISIONS.md`. Include exact test commands/results or say **NOT RUN**.
