# Sorrelgate — Current verified state

**Updated after compiler failure:** 2026-11-21T05:02:40.473Z (UTC)
**Project:** https://github.com/Kajin-0/sorrelgate
**Phase:** M1 CI run #4 failed at Swift parsing (extra `}` in DocumentWorkspace); source fix committed and new CI pending.
**Owner hardware:** NO Mac; use GitHub Actions macOS 26 arm64, defer physical usability to first external tester.
**Release:** NOT READY; no signed/notarized installer or verified AI operation.

## Evidence from GitHub Actions and compiler remediation
- [Run #1](https://github.com/Kajin-0/sorrelgate/actions/runs/44866969670): **PASS**, native app compiled, four XCTest cases invoked (though historical output displayed a separate Swift Testing 0-case summary).
- [Run #2](https://github.com/Kajin-0/sorrelgate/actions/runs/44867165600): **PASS**, documentation-only update.
- [Run #3](https://github.com/Kajin-0/sorrelgate/actions/runs/44868312124): **FAIL** in `testCreateAndListTransactions`; `XCTAssertEqual(records.first, created)` fails because SQLite REAL Date precision differs by a tiny amount. The correct test now checks UUID/address/workflow exactly and Date within 0.001 seconds. **New CI must re-verify.**

- [Run #4](https://github.com/Kajin-0/sorrelgate/actions/runs/44868984731): **FAIL** in `swift test` Swift parsing: an extra closing brace in `DocumentSQLiteStore.insertDocument` caused cascading missing-member errors; extra brace removed in next commit, awaiting CI. Compiler failure is not a feature pass.

## Submitted in M1 (not verified until CI completes)
- `DocumentWorkspace` Swift actor, local SQLite metadata tables for documents, pages, checklist tasks, SHA-256 content-addressed originals, digital-text extraction via PDFKit and Vision OCR fallback.
- Sequential batch import with cancellation/progress, duplicate recognition and source integrity; checklist creation/completion and same-transaction document association.
- Native import picker, PDF preview, checklist management, Finder-selected export directory and reviewed copies + SHA-256 JSON manifest/Checklist.txt.
- Synthetic test suite includes actual generated PDF files, original-byte preservation, duplicate handling, invalid PDF rejection, checklist persistence/scope, 10-PDF batch and export.
- No real customer documents or signing credentials committed.

## Milestone gates
| Milestone | State | Evidence |
|---|---|---|
| M0 native SwiftUI/SQLite/CI | IN PROGRESS | one early successful CI build, later failure diagnosed; full regression retest pending; no physical Mac validation |
| M1 PDF import/checklist/export | IN PROGRESS | source submitted; new CI must verify; full GUI hands-on deferred |
| M2 office workflows/XLSX | NOT STARTED | no code |
| M3 classification/validation | NOT STARTED | no code |
| M4 timelines/email drafts | NOT STARTED | no code |
| M5 guarded LLM actions | NOT STARTED | no code |
| M6 commercial installer | NOT STARTED | no Apple signing or external beta |

## Next executable step
1. Inspect macOS Actions run on latest commit: fix Swift compiler/test failures and update verified metrics. No feature is declared passed from a design alone.
2. After green CI, harden import/cancellation/recovery and automatic starter checklists, track remaining M1 defects.
3. Continue until a functional first beta can be provided to an external Mac user using signed/notarized distribution; no owner-side Mac is available.
4. Update CHANGELOG and this STATUS per substantive commit. No sensitive client data in public Git.

**Architecture:** The graphical interface and future LLM tools must use the same typed core operations. Never grant an LLM arbitrary filesystem access or unattended consequential real estate actions.
