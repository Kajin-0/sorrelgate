# Sorrelgate — Current state

**Updated:** 2026-11-21T05:14:07.576Z (UTC)
**Repository:** https://github.com/Kajin-0/sorrelgate
**Budget:** $0 additional spending during the early MVP. No Apple Developer membership, paid API or signing expenses. Codex can build locally using free Xcode on the authorized future Mac tester's machine.
**Owner Mac:** None; GitHub Actions macOS 26 arm64 handles automated builds and testing.

## Last verified results
[GitHub Actions run #5](https://github.com/Kajin-0/sorrelgate/actions/runs/44869071688) SUCCESS: 9 XCTest cases passed and native app compiled, including PDF import/hash, digital text extraction, checklist storage, and safe export.

## Submitted, pending new CI
- Bundled versioned 21-task seller-side starter JSON in SorrelgateCore resources.
- Atomic, idempotent checklist initialization in DocumentWorkspace; existing manual tasks preserved.
- Transaction-scoped task rename/remove operations, leaving original PDFs untouched.
- Two additional XCTest tests for seeding, no overwrite, restart persistence and cross-transaction protection.
- SwiftUI now automatically seeds checklists for new transactions and offers a Load Starter Tasks action for older empty workspaces; editable task sheet renames/removes tasks and selected PDF persists across checklist refresh.
- Free tester handoff instructions added for Codex-assisted local Xcode build, without Apple membership.
**This new feature is NOT YET VERIFIED until fresh Actions completes.**

## Milestones
- M0 native SwiftUI, SQLite, CI: verified in hosted CI; human Mac testing pending.
- M1 PDF import, OCR, preview, checklist/export: core CI pass; scan accuracy, larger batches, cancel, and human UX need tests.
- M2 office configuration: started with bundled templates; GUI auto-load, office profiles, XLSX/CSV mapping still to do.
- M3 recognition, M4 drafts, M5 LLM tools, M6 distribution: not implemented.
- $0 external supervised pilot: future Codex-assisted local source build, NO paid Apple signing required; polished self-service install deferred.

## Next executable work
1. Inspect the next GitHub Actions run; resolve any compiler or test failures.
2. Connect the starter workflow to native UI, preserve current PDF selection during checklist actions.
3. Implement office-specific templates and spreadsheet import without rewriting the M1 core.
4. Continue regression testing with synthetic documents; do not imply the app is sellable or real Mac UX is verified.
