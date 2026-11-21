# Sorrelgate — Acceptance tests and metrics

**All numbers are engineering objectives, not achieved results.** Record the real Mac model, macOS/Xcode/Swift versions, commands, exit status, fixtures and measurements in `docs/STATUS.md`. Never report success from a mock.

## M0/M1 vertical-slice hard gate

1. Build/run the native SwiftUI application on authorized Apple-silicon Mac.
2. Create a transaction, quit/relaunch and confirm persistence.
3. Import 10 representative synthetic PDFs, mixing scans, digital text, duplicate, damaged and rotated pages; preserve original SHA-256 bytes.
4. Run page-level text extraction + OCR fallback with progress/cancel/retry and no data corruption.
5. Preview an original PDF's actual source page and connect to an editable checklist.
6. Export renamed **copies** and manifest to a chosen folder without overwriting existing documents.
7. Test failure paths (invalid PDF, permission denial, duplicate, corruption, cancellation, disk full) and offline core operation.

## Release-level target metrics

| Metric | Proposed gate |
|---|---|
| Original integrity | 100% SHA-256 match |
| Mixed batch | 50 PDFs / 300 pages processed with retryable partial failures |
| UI | responsive during OCR; typical local actions below 200 ms |
| Document classification | macro-F1 ≥0.95, with abstention rate disclosed |
| Accepted high-confidence field extraction | precision ≥0.98, with coverage disclosed |
| Evidence traceability | 100% findings navigate to source document/page |
| Unauthorized verification | zero agent-created verified signature/deadline states |
| Approval enforcement | 100% approval-required negative controls blocked |
| Agent task execution | ≥0.90 across 30 scored safe multi-step scenarios |
| TC productivity | median ≥15 minutes net saved per transaction in controlled pilot |
| Install | signed/notarized/stapled DMG on clean Mac; no terminal or developer setup |
| Offline | all core manual document workflows pass without network |

Any P0/P1 original corruption, privacy leakage, unapproved consequential act, or unauthorized source change blocks release independently of these averages.
