# Sorrelgate — Implementation and QA Checklist

Use as a release gate ledger; check boxes only when implementation **and actual tests** pass. Owner has **no local Mac**: mark CI gates and future human-Mac acceptance gates separately, and do not block implementation on hands-on hardware access (see `docs/REMOTE_TEST_STRATEGY.md`).

## M0 — Foundation
- [ ] Public visibility explicitly accepted by owner; verify no sensitive materials are committed before each push
- [x] Native macOS SwiftUI executable builds on supported Mac — verified macos-26 arm64 GitHub Actions run #1; user-visible launch still to test
- [x] `SorrelgateCore` module with domain services and typed action interface — initial typed create/list actions tested in CI
- [ ] SQLite migrations, transactions, restart persistence
- [ ] macOS CI build/test, dependency lock and license audit — **CI build/tests verified**; dependency/license audit not yet complete
- [ ] Native application navigation: Transactions, Workspace, Settings

## Remote CI and external Mac beta preparation
- [x] First macOS Actions runner build/test passed; no local Mac required
- [ ] Expand automated macOS app-launch and fresh-restart smoke tests where feasible
- [ ] First free assisted pilot: use Codex + free Xcode local build on tester's Mac. No paid Apple membership now.
- [ ] Later commercial self-serve release: signed/notarized installer only after user approves spending.
- [ ] Obtain hands-on verification from external Mac tester; do not claim this based on CI

## M1 — Vertical slice
- [ ] Create / edit / reopen transaction
- [ ] Batch PDF import (individual selection, progress/cancel); first implementation submitted, CI pending; folder selection not done
- [x] Immutable original copies, SHA-256, duplicate handling — synthetic file-integrity and dedupe verified in CI run #5; large-file edges pending
- [ ] PDFKit text extraction, per-page Vision OCR fallback — PDFKit text verified in CI run #5; Vision scanned-page correctness not yet independently benchmarked
- [ ] Original PDF page viewer — implementation submitted, human verification pending
- [ ] Editable task checklist, document link, status persistence — backend persistence/link scope tests PASS; GUI usability unverified
- [ ] Export basic package and manifest to selected folder — backend SHA256-verified copy and manifest PASS; Finder/GUI unverified
- [ ] Crash/restart, corrupt PDF, zero-byte PDF, duplicate PDF and hash tests

## M2 — TC workflow
- [x] Listing Preparation starter checklist — 9 bundled administrative tasks, idempotent seed, CI #7
- [x] Accepted Offer starter checklist — 12 bundled administrative tasks, restart persistence, CI #7
- [ ] Different office profiles; configurable task order, states and requirements — named offices and task ordering CI PASS (PR #9, Actions #14); richer states/requirements still future
- [ ] XLSX/CSV checklist import with preview and correction — CSV title-column mapping/invalid-row preview CI PASS in PR #10 Actions #33; XLSX real workbook tests and SwiftUI CI PASS (PR #11, Actions #50, 24 tests); title-only mapping verified, richer mappings and real Mac UX still future
- [ ] Template version snapshots and safe updates — append-only revisions and transaction source/row copies CI PASS (PR #9, Actions #14), UI migration still future
- [ ] Prompt-free manual operation from start to export

## M3 — Intelligence
- [ ] Document labels and unknown state
- [ ] Core field proposals with source PDF page and confirmation state
- [ ] Cross-document mismatch candidates
- [ ] Missing document checks based on selected office template
- [ ] Duplicate and unreadable-page issues
- [ ] Signature-review page surfacing without claim of verified signatures
- [ ] Measured evaluation on held-out authorized test set

## M4 — Deliverables
- [ ] Confirmed-date timeline and safe date handling
- [ ] Editable introduction and follow-up email drafts
- [ ] Human-approved escrow-demand worksheet draft
- [ ] Searchable organized export copies, index, timeline, issue report
- [ ] No silent overwrite, no automatic external sending

## M5 — AI agent
- [ ] Apple model provider feature detection; manual fallback
- [ ] Typed tool registry backed by GUI action services
- [ ] Scoped permissions/approval and rejection behavior
- [ ] Persisted action receipts + truthful completion summary
- [ ] Model sees only relevant retrieved document excerpts
- [ ] Prompt-injection tests with adversarial PDF text
- [ ] 30 scored end-to-end agent scenarios; 100% required approval gates

## M6 — Paid release
- [ ] Privacy review, threat model and security testing
- [ ] SBOM and license/NOTICE audit for all packages and bundled components
- [ ] Backup/export/restore and migration test
- [ ] User onboarding, sample data, accessible UX, helpful error messages
- [ ] Developer ID signed hardened app, Apple notarization and stapled DMG
- [ ] Clean-Mac install and offline operation
- [ ] One-time license and support policy, customer receipts, uninstall guidance
- [ ] TC pilot confirms net time savings and workflow fidelity
- [ ] No P0/P1 data-loss, privacy, false-approval or source-corruption bugs