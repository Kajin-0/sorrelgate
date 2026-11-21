# Sorrelgate — Verified development status

**Verified:** 2026-11-21T05:47:04.155Z (PR #11 XLSX source CI #50; main merge still separate)
**Repository:** https://github.com/Kajin-0/sorrelgate (public by owner's choice)
**Budget:** $0 additional during the early MVP. Apple membership, signing, notarization, paid APIs and cloud hosting are DEFERRED. Codex may build locally using free Xcode on the external tester's Mac with the owner's consent.
**No owner Mac:** GitHub Actions macOS runners verify builds and automated tests; real UI, macOS permissions, real OCR performance and on-device LLM must be validated later on the tester's Mac.

## Latest verified source build: XLSX import CI PASS, PR #11 (main merge pending)
- Merged via [PR #9](https://github.com/Kajin-0/sorrelgate/pull/9) (squash commit `8c127df`): named office profiles; independent workflow checklists; append-only office template revisions with optimistic version checks; atomic transaction checklist copies and provenance; SwiftUI office management and office selection on transaction creation.
- New synthetic tests: office isolation, restart recovery, old/new template versions, manual-task protection, stale-version/duplicate office rejection.
- **Verified:** [macOS GitHub Actions #14](https://github.com/Kajin-0/sorrelgate/actions/runs/44870973186) SUCCESS on `eb106533ca49bf106c84e70772b8f44cf11d13e1`: all **16 XCTest cases invoked successfully** (11 baseline + 5 office-template tests); XcodeGen generation, native SwiftUI Xcode build and unsigned artifact upload PASS.
- **XLSX importer CI PASS:** [PR #11](https://github.com/Kajin-0/sorrelgate/pull/11) on code commit `33686e2b2bb321d92f2238bec3e89adbc18d3ee8`, [macOS Actions #50](https://github.com/Kajin-0/sorrelgate/actions/runs/44872179791) SUCCESS: **24/24 XCTest cases** (20 prior + 4 real synthetic XLSX workbook tests). XcodeGen project, native SwiftUI build, ZIP debug packaging/upload PASS on macOS 26 Apple Silicon / Xcode 26.6 / Swift 6.3.3. XLSX parse is asynchronous off UI thread; native GUI usability still pending. No cost incurred.
- CSV import **CI-PASS** in [Actions #33](https://github.com/Kajin-0/sorrelgate/actions/runs/44871510490) on `445949d54d26b4e02e30d83794649edd09ff7b8f`: 20/20 XCTest cases (16 previous + 4 CSV), XcodeGen project and native SwiftUI app BUILD SUCCEEDED, unsigned artifact uploaded. UTF-8 BOM/quoted/newline parsing, explicit title-column preview, duplicate/missing row review and staged office draft are implemented. Initial CSV CI failure was fixed by Unicode-scalar CRLF tokenization. XLSX title-column/sheet importer CI PASS in PR #11; richer columns and real Mac UX remain unverified.

## Previously verified main CI: PASS
- [GitHub Actions #7](https://github.com/Kajin-0/sorrelgate/actions/runs/44870027594) SUCCESS on source commit `5b419be1f9a7bce6a0402c069f55463930a52c13`.
- Apple Silicon macOS 26, Xcode 26.6, Swift 6.3.3, XcodeGen 2.46.0.
- `swift test --parallel`: **11 XCTest cases invoked successfully** (4 original transaction tests, 5 PDF/checklist tests, 2 starter/edit tests). Tests include SQLite persistence, synthetic PDF integrity and text extraction, duplicate/invalid PDFs, a 10-file batch, checklist transaction isolation, safe export, starter idempotence and persistence across reopen. Note that a distinct Swift Testing harness reports 0 Swift Testing cases, not zero XCTest cases.
- Native XcodeGen project generation and `xcodebuild ... CODE_SIGNING_ALLOWED=NO build`: PASS.
- Latest CI development artifact: `Sorrelgate-macOS-unsigned-debug` ID **14693785979**, **690,515 bytes**, expires 2026-11-28; downloadable from the Actions run. Not a normal one-click end-user installer.
- [Actions #6](https://github.com/Kajin-0/sorrelgate/actions/runs/44869921480) also passed the first versioned-resource backend source.

## Working code and limitations
- M0: native SwiftUI app and local SQLite transaction database; CI PASS, human UI not verified.
- M1: Finder-selected PDF import, SHA-256 original preservation, PDFKit extraction / Vision OCR fallback, duplicate handling, preview, checklist/document links, export package. Synthetic backend tests PASS; scanned OCR accuracy, full error/cancellation and macOS interaction remain unverified.
- M2: **IN PROGRESS; office profiles and snapshots CI-PASS merged in PR #9.** Bundled versioned California seller administrative catalog: **9 listing tasks and 12 accepted-offer tasks** auto-seeded into new transaction checklists. Existing user tasks are not overwritten. Rename/remove is transaction-scoped and does not delete documents. PDF selection is preserved through task refresh. UI compiles; human validation pending. **Named offices and versioned copies merged, CSV title-column import verified in PR #10; XLSX import, rich task metadata and migration UX remain unimplemented.**
- M3 recognition/validation: NOT STARTED.
- M4 timelines/drafts: NOT STARTED.
- M5 LLM operates typed backend: NOT STARTED (typed service foundation exists).
- M6 commercial release: NOT STARTED. Paid Apple distribution postponed until strong MVP and owner approval.

## Next engineering tasks
1. Finish richer office checklist task fields (required/optional, status, notes, due date), review/migration UX, and expanded CSV/XLSX column mapping; preserve existing checklist snapshots.
2. Harden M1 scanned OCR accuracy, import cancellation, corrupt/disk failures and 50-PDF throughput; keep Mac CI green and physical pilot pending.
2. Add CSV then XLSX import with column mapping preview. No need for external office systems in first MVP.
3. Harden PDF importer/OCR (raster scan benchmark, cancellation, corrupt/disk-error cases, 50-PDF batch) and maintain CI green.
4. Keep an authorized Codex-assisted local Mac build for the first supervised tester, not a paid signed app. See [free tester handoff](FREE_MAC_TESTER_HANDOFF.md).
5. Update root AGENTS.md and timestamped CHANGELOG on every substantive implementation; NEVER claim human Mac tests have been performed.
