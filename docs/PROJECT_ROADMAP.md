# Sorrelgate — Staged implementation roadmap

**Status:** planned, not built. Detailed tasks are in [Implementation Checklist](IMPLEMENTATION_CHECKLIST.md).

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
