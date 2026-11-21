# Sorrelgate — Technical architecture

**Design specification only; not implemented.** See [Product specification](PRODUCT_SPECIFICATION.md) §4–§9 for the full data model and required behaviors.

## System topology

```text
Native SwiftUI UI             Apple Foundation Models (if available)
       |                                  |
       |                              ProviderAdapter
       |                                  |
       +---------------+------------------+
                       |
           Typed ActionDispatcher
           (authorization + approvals)
                       |
             SorrelgateCore services
       +------------+-------------+----------------+
       |            |             |                |
 Documents/OCR   Workflows     Validation       Drafts/Export
       |            |             |                |
       +------------+-------------+----------------+
                       |
       SQLite + immutable original PDFs + action receipts
```

**One behavior, one implementation:** UI and AI call the same typed domain operations. Never embed business rules only in SwiftUI button handlers or LLM prompts.

## Modules and responsibilities

| Package/service | Purpose |
|---|---|
| `Domain` | IDs, invariants, statuses, user-visible errors |
| `Persistence` | SQLite, migrations, atomic saves, backup/restore |
| `Documents` | user-granted PDFs, SHA-256, PDFKit extraction, Vision OCR, source page preview |
| `Recognition` | label and field proposals, uncertainty/unknown state |
| `Workflows` | separate office profiles, checklist versions, task state, XLSX/CSV |
| `Validation` | possible missing/duplicate/conflicting information with page evidence |
| `Drafts` | reviewed timelines, email drafts, escrow worksheets, no external sending |
| `Exports` | safe copies, filenames, user-approved destinations, manifest |
| `Actions` | typed commands, transaction scope, approvals, receipts, undo |
| `Agents` | provider adapter, bounded tool orchestration, truthful summaries |
| `Security` | least privilege, prompt injection isolation, diagnostics redaction |

## Data model

Use separate `Office`, `Agent`, `Transaction`, `Contact`, `Template`, `TemplateTask`, `Task`, `Document`, `DocumentPage`, `ExtractedField`, `TaskEvidence`, `Issue`, `TimelineEvent`, `Draft`, `ActionReceipt`, `Approval`, `AgentRun`, `Export`. See spec §4.4 for fields. UUID primary keys; never use filenames as identity.

## PDF processing lifecycle

1. User grants selected file/folder access using native picker.
2. Validate PDF/paths/size; copy to app-controlled storage and compute SHA-256; preserve source bytes.
3. Extract text page-wise using PDFKit; run Vision OCR only when needed.
4. Retain method/version, document hash and page references; build searchable local index.
5. Propose classifications and fields; do not mark as verified.
6. Match tasks to document candidates; flag exceptions with evidence for human review.
7. Export approved **copies**; manifest records original name, hash and export name.

Run background work with Swift concurrency, cancellation, checkpoints and retry; cached results are keyed by content hash and extraction engine version. Preserve correct state across relaunch. Mac feature-detect AI availability; when unavailable every manual workflow remains usable.

## Scope discipline

No user terminal, Python runtime, Homebrew, service account, server, paid inference or agent-driven arbitrary desktop actions in the customer's core workflow. Codex may use full macOS terminal/Xcode automation in development.
