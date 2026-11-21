# Sorrelgate — Staged implementation roadmap

**Status:** M0 native build and tests passed in GitHub CI; other milestones unimplemented. Owner lacks a local Mac, so interactive validation is deferred to external beta. See [remote testing](REMOTE_TEST_STRATEGY.md). Detailed tasks are in [Implementation Checklist](IMPLEMENTATION_CHECKLIST.md).

| Milestone | Deliverable | Required exit evidence |
|---|---|---|
| M0 | SwiftUI shell, typed core actions, SQLite, Mac CI | Xcode build/tests, persistence/reopen |
| M1 | PDF importer, PDFKit + Vision OCR, previews, checklist link, export | real 10-PDF vertical slice and integrity tests |
| M2 | seller listing + accepted offer workflows, office presets, XLSX/CSV | real TC can configure two offices without code |
| M3 | document recognition, sourced field proposals and issue review | held-out precision/coverage and evidence traceability |
| M4 | user-confirmed timelines, draft emails, escrow worksheet, packages | correct drafts/export, no external send |
| M5 | agent tool calling with permissions, approvals and truthful receipts | prompt accomplishes real state changes; adversarial tests |
| M6 | security, backup, license audit, usable signed/notarized Mac DMG | clean install and supervised TC pilot |

Prioritize a complete customer workflow over scattered partial features. Keep frontend plain-language and simple, but allow sophisticated backend internals. Defer direct integrations with Glide/DocuSign/SkySlope, brokerage systems, outbound emails, and autonomous legal decisions.


## Testing policy while no Mac is locally available
- M0/M1 implementation may advance after verified CI gates on hosted macOS; do not block development on unavailable physical user testing.
- Preserve a distinct **external-beta acceptance gate**: run app on the intended Mac, perform the full TC workflow, confirm persistence, OCR, Finder permissions, onboarding, accessibility, and UI comprehension.
- The first external pilot build should install normally without terminal/Developer Tools; preferred route is a notarized Developer ID build or supported Apple distribution. An unsigned CI artifact is developer-only.
- No commercial readiness claim until all manual and automated quality gates pass.
