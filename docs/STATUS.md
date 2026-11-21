# Sorrelgate — Current verified state

**Last updated:** 2026-11-21T04:36:43.885Z (UTC)
**Phase:** M0 initial implementation committed; build/test verification pending.
**Repository:** https://github.com/Kajin-0/sorrelgate
**Visibility:** PUBLIC by owner choice, not a blocker.
**Release:** NOT READY. No signed/notarized app, TC pilot, PDF OCR pipeline or LLM agent yet.

## Implementation present
- Swift package \`SorrelgateCore\`: typed create/list transaction actions, SQLite-backed durable local records and input validation.
- SwiftUI desktop app: transaction list, create sheet, selection/details, clear M1 placeholders, app preferences.
- Swift package tests: create/list, database reopening, blank address rejection, SQL injection string treated as data.
- \`project.yml\` for XcodeGen (MIT, developer-only); \`.github/workflows/macos-ci.yml\` builds and tests on \`macos-26\` and uploads an unsigned debug artifact.
- Customer runtime requires neither terminal nor Python/Node/Homebrew.
- **No code has yet been compiled or executed in this ChatGPT session.** Actual GitHub Actions evidence determines correctness.

## Milestone gates
| Milestone | State | Evidence |
|---|---|---|
| M0 Native app, actions, SQLite, CI | IN PROGRESS | Code authored; CI and physical Mac validation pending |
| M1 PDF import / OCR / preview / checklists / export | NOT STARTED | No implementation |
| M2 Office profiles / XLSX / versioning | NOT STARTED | No implementation |
| M3 Classification / linked document checks | NOT STARTED | No implementation |
| M4 Timeline / draft communications / exports | NOT STARTED | No implementation |
| M5 Guarded LLM-controlled actions | NOT STARTED | No model integrations |
| M6 Commercial Mac release | NOT STARTED | No signing, notarization or pilot |

## Immediate next steps
1. Inspect [GitHub Actions](https://github.com/Kajin-0/sorrelgate/actions) for push-triggered macOS run; record job ID, exact toolchain, test counts and outcomes, fix any errors. Do not mark M0 passed without evidence.
2. Run actual desktop application on an authorized Mac when available: create transaction, quit, reopen, verify persistence and accessibility.
3. Finish M0 with negative tests; then implement M1 as a verified end-to-end PDF/document-review vertical slice.
4. Update CHANGELOG + STATUS in each substantive change; record decisions in DECISIONS. Never commit customer records, signatures, passwords or private office templates.

**Development mode:** Regular ChatGPT + GitHub Actions is the standard loop; Codex optional. Root AGENTS.md is mandatory fresh-session handoff.
