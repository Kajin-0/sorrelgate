# Sorrelgate — Implementation and QA Checklist

Use as a release gate ledger; check boxes only when implementation **and actual tests** pass.

## M0 — Foundation
- [ ] Public visibility explicitly accepted by owner; verify no sensitive materials are committed before each push
- [ ] Native macOS SwiftUI executable builds on supported Mac
- [ ] `SorrelgateCore` module with domain services and typed action interface — initial source added; unit tests pending CI
- [ ] SQLite migrations, transactions, restart persistence
- [ ] macOS CI build/test, dependency lock and license audit — workflow added; first run pending
- [ ] Native application navigation: Transactions, Workspace, Settings

## M1 — Vertical slice
- [ ] Create / edit / reopen transaction
- [ ] Batch PDF import (individual/folder, progress/cancel)
- [ ] Immutable original copies, SHA-256, duplicate handling
- [ ] PDFKit text extraction, per-page Vision OCR fallback
- [ ] Original PDF page viewer
- [ ] Editable task checklist, document link, status persistence
- [ ] Export basic package and manifest to selected folder
- [ ] Crash/restart, corrupt PDF, zero-byte PDF, duplicate PDF and hash tests

## M2 — TC workflow
- [ ] Listing Preparation starter checklist
- [ ] Accepted Offer starter checklist
- [ ] Different office profiles; configurable task order, states and requirements
- [ ] XLSX/CSV checklist import with preview and correction
- [ ] Template version snapshots and safe updates
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