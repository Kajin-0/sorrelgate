# Sorrelgate for Mac — Product Requirements and Technical Specification

**Version:** 1.0 (design baseline)  
**Date:** 2026-11-20  
**Status:** Design only — no application code or Mac build yet; product decisions are proposals until validated with a working California transaction coordinator.  
**Primary platform:** macOS 26+, Apple silicon (M1 or newer).  
**Deployment:** Direct, signed, notarized Mac download, distributed as a DMG.  
**Commercial model:** One-time per-user license; proposed $149 launch / $249 retail.  
**Distribution license:** Proprietary application using Apple system frameworks and audited commercially permissive dependencies; no GPL/AGPL in the shipped dependency graph.

## 0. Executive contract

Build a nontechnical, Mac-native application that helps California seller-side real estate transaction coordinators manage listing paperwork and accepted offers. A user can either click through a minimal interface **or ask an LLM to perform internal app actions**. The app imports and processes PDFs, tracks office-specific checklists, prepares transaction timelines and communication drafts, highlights likely missing or inconsistent materials, and exports an organized, evidence-backed package. The user retains responsibility for legally consequential decisions.

**The first complete user journey:** Create an Accepted Offer transaction > import 10–50 PDFs > extract text/OCR > classify and match to the office's checklist > identify exceptions with PDF page references > propose draft timeline and introductory email > human verifies required fields > export package > close/relaunch app with all progress intact. The same backend actions must be usable through the GUI and through the LLM.

**Release is not complete unless:** an authorized, nontechnical Mac user can install the app, accomplish this journey without a terminal or developer accounts, recover gracefully from common errors, and understand exactly what the app did and did not verify.

## 1. Scope boundaries

### 1.1 In-scope for first paid v1

**Personas**: Independent California seller-side TC (primary); agent/office reviewer accessing exported files (secondary, no account); one TC managing multiple agents/offices from one Mac.

**Two workflows**: (A) Prepare a House for Sale / Listing Preparation, and (B) Accepted Offer / Seller Side. Both are editable templates, not hard-coded legal determinations. Multiple offices can have different template versions.

**Functional capabilities**:
- Local transaction workspace: create, edit, archive, reopen, search; stages, agent, office, property, notes, contacts, due dates, status.
- Import PDFs (single, batches, folders), retain immutable original bytes, prevent accidental overwrites, hash/deduplicate, handle digital and scanned PDFs, OCR as needed, index searchable text, preview source pages.
- User-configured document type labels and basic classification; explainable candidate matches to required checklist entries, not unsupported claims that legal forms are complete.
- Editable checklist with task status, required document labels, optional/conditional tasks, owner, notes, due date, linked evidence, and history. Excel XLSX and CSV checklist import with preview/mapping; no unsupported automatic mapping without review.
- Extract and propose core values (property address, seller/buyer names, price, acceptance date, closing date, escrow company, agent names) with source page, text span/region when available, and unconfirmed/verified status.
- Flag possible document absence, duplicate copies, mismatched populated fields, missing pages, unreadable scans, unconfirmed dates, and likely signature-review pages. Never claim a signature is valid or legally sufficient.
- Timeline composed of **user-confirmed** dates; duplicate/out-of-order alerts; PDF/CSV exports; optional Calendar export via .ics only after user confirmation. No default legal deadline calculation from unverified templates.
- Editable message templates: introduction, request for missing documents, follow-up, status summary, escrow-demand draft worksheet (must be approved by agent/office). Copy to clipboard, save as text or draft file; app never sends external messages in v1.
- Package export: renamed **copies**, original-name manifest, transaction summary, checklist report, timeline, exception report, document index with source references. Never modify original PDFs.
- AI assistant: natural-language requests invoke the **same core backend actions** as GUI; plans, executes low-risk actions, and presents review items; available only when a supported model provider is accessible. Deterministic manual workflow always available.
- Settings: offices, checklist versions, naming conventions, folder/export destinations, user preferences, model availability, privacy settings, backups, license view.
- Reliability: background progress, cancel/resume where safe, checkpointing, offline manual operation, error messages, diagnostic export with sensitive content omitted.

### 1.2 Explicitly out of scope for v1

No replacement of Glide, DocuSign, Disclosures.io/Homewise, SkySlope, zipForm, MLS, brokerage compliance systems, or escrow platforms. No direct API integrations; no automatic email sending; no signatures or edits to signed forms; no legal advice; no legal determination of contingency removal, disclosure sufficiency, or acceptable referral payments; no contracts generated from licensed C.A.R. blank forms; no buyer-side workflow, leasing, commercial sales, or state-by-state rules engine; no multi-user cloud sync, CRM, payment processing inside app, web dashboard, mobile app, or agent-driven arbitrary desktop/terminal/shell commands.

### 1.3 Release strategy

- **v0 vertical slice:** create/reopen transaction, import PDFs, editable checklist, categorize, display source page, export basic report; AI uses a small set of tools.
- **v1 paid:** complete the in-scope requirements, robust import/review/export, office presets, reviewed AI journey, installer, support and recovery documentation.
- **v1.x only after evidence:** better signature-page suggestions; additional local models/cloud BYOK; smarter Excel mapping; user-requested integrations; additional document types.
- **v2 candidates:** buyer side, integrations, bulk agent communications, shared office workflows, remote sync; each requires separate feasibility and liability review.

## 2. User journeys and business workflow

### 2.1 First launch / office onboarding

1. Welcome screen: choose "Use a starter checklist" or "Import my office checklist." Explain no account needed and where files are stored.
2. Enter office name (optional), agent names, office-submission email (optional), work preferences. Import XLSX/CSV and map columns such as task/document/status/phase/required/notes. Unmatched rows preserved in review queue.
3. Show editable starter tasks. Never assume office requirements or mandatory legal forms; each requirement carries source = user/office/template and template version.
4. Ask for initial transaction folder only when importing. Permissions limited to selected files/folders.
5. Check on-device AI model availability and show "Assistant available" or "Manual mode — full document workflow still works." No account or cloud setup required.

### 2.2 Workflow A: Prepare a House for Sale

The supplied TC describes these administrative steps; all task labels below are editable:

| ID | Human-readable task | App contribution | Completion requirement |
|---|---|---|---|
| L01 | Receive signed listing agreement | Import/label, link original | TC confirms receipt and signatures |
| L02 | Send listing documents and new listing form to office | Prepare export package/checklist | TC marks sent outside app |
| L03 | Determine which property questionnaires are needed | Import office Excel list; surface checklist | TC confirms requirements |
| L04 | Set up questionnaires in Glide | Provide checklist and copying reference info | TC marks done outside app |
| L05 | Send questionnaires to client | Prepare communication draft | TC sends outside app |
| L06 | Prepare and send DocuSign request | Track forms needing signatures | TC completes in DocuSign |
| L07 | Collect completed signed documents | Import return PDFs, link versions, flag missing | TC verifies |
| L08 | Assemble disclosure package in Disclosures.io/Homewise | Export organized copies and manifest | TC uploads outside app |
| L09 | Mark listing preparation complete | Summarize finished/pending work | TC approves transition |

### 2.3 Workflow B: Accepted Offer — Seller Side

| ID | Human-readable task | App contribution | Completion requirement |
|---|---|---|---|
| A01 | Receive accepted purchase agreement | Import, classify, preview | TC marks received |
| A02 | Verify all required parties signed | Surface signature-review pages | TC or licensed agent checks actual document |
| A03 | Send agreement and newly accepted-offer form to office | Prepare bundle | TC marks sent outside app |
| A04 | Confirm key facts and deadlines | Propose fields with original-page evidence | TC approves every consequential field |
| A05 | Create transaction timeline | Use confirmed fields, export report | TC reviews and approves |
| A06 | Draft introduction to buyer's side, escrow, perhaps lender | Use saved template and verified fields | TC reviews and sends outside app |
| A07 | Share disclosure-package link | Pre-fill draft with approved URL | TC confirms recipients and link |
| A08 | Collect buyer's signed disclosures | Import returned forms, compare required set | TC verifies completeness/signatures |
| A09 | Collect buyer agent's visual inspection document (AVID) | Match to office checklist | TC confirms form received |
| A10 | Forward signed documents to designated office address | Export grouped files / draft cover email | TC sends outside app |
| A11 | Draft escrow demand/referral instructions | Controlled worksheet from verified values | Agent/office reviews before external use |
| A12 | Close or archive internal TC workflow | Outstanding issue summary and export | TC confirms, no legal closing certification |

**Workflow flexibility:** tasks have state (not_started/in_progress/waiting_on_someone/ready_for_review/completed/not_applicable), custom labels, conditions controlled by user selections, order/dependencies, evidence links, owner, and due date. Changing a template affects **new transactions only** unless user accepts a migration preview.

### 2.4 Example agent instruction

> "I got an accepted offer. Set up the transaction from these PDFs, check our checklist, make the timeline, and draft the buyer-side introduction."

Expected visible actions: transaction created (or existing matched and user chooses); originals imported; classifications and field suggestions made with source pages; checklist matched with uncertainty and pending reviews shown; timeline built only from verified data, otherwise marked draft; email draft created with missing field placeholders rather than invented values; human review summary includes what needs action and where.

## 3. UX specification

### 3.1 Core surfaces (three main sections)

**My Transactions**: prominent "New transaction", recent transactions, search/filter by address, office, stage, status; quick "Continue" action. No jargon in main controls.

**Workspace**: header (address, office, workflow, last updated), a primary "What should I do next?" area, document import drop zone, three task views (To Do / Needs Review / Done), tabs or disclosure sections (Documents, Timeline, Drafts, Activity). Full-width evidence review opens source PDF and extracted field side-by-side.

**Office Settings**: office profiles, checklist templates, import Excel, user-friendly naming rules, communication templates, data/backup, AI provider status, privacy, licenses.

**Persistent assistant panel**: optional compact chat area in workspace with suggested prompts; agent activity is displayed as progress events and completed actions. Users can close chat and do everything manually.

### 3.2 UX principles

- Use common English in primary controls: "Get Documents", "Missing Items", "Make Timeline", "Prepare Email", "Save Package". Explain acronyms in tooltips and advanced detail views.
- Progressive disclosure: one recommended action and primary CTA; details hidden unless relevant. Advanced functionality is permitted but need not occupy the main screen.
- Multiple visual states: Present (detected), Verified (human checked), Missing (required per selected office template, no candidate document), Needs Review (uncertain), Not Applicable, Not Yet Requested. Do **not** equate "present" with "legally complete."
- User can always override a machine guess, with optional reason and retained history. Never overwrite original files.
- Preview first: before changes to templates, exports, or externally consequential documents, show a plain-English confirmation.
- Accessibility: VoiceOver, keyboard navigation, native macOS text scaling, sufficient contrast; user needs no terminal.
- First-time success: transaction created, docs imported, checklist populated, first report exported, with no login or cloud API key.

### 3.3 Error copy examples

- "I could not read pages 4–6. The original PDF is safe. You can open those pages or try again."
- "I found two possible closing dates. Please choose which one you want in the draft timeline."
- "The AI assistant is unavailable on this Mac. Documents, checklists, reports, and timelines still work."
- "This item appears to be missing from your office checklist. It is not a legal compliance determination."

## 4. Technical architecture

### 4.1 Platform and technology selection

- Swift 6 / SwiftUI native desktop app; PDFKit for PDF viewing and text layer; Vision for OCR; Foundation/UniformTypeIdentifiers for import/export; CryptoKit for hashing and optional encrypted exports; Keychain for secrets; SQLite via C interface or auditable permissive wrapper; CoreXLSX (Apache 2.0, pinned release) for XLSX import. CSV via Foundation.
- Apple Foundation Models framework for tool calling where available. Runtime availability must be checked; macOS 26+, Apple silicon, Apple Intelligence supported/enabled. Model fallbacks: manual mode first; an optional cloud BYOK provider is **not required to ship the initial paid release** but must be architecturally possible.
- User-facing main app uses no Python runtime, container, web server, or Homebrew. Any OCR improvement engine must be embedded and license-audited if added later.
- Mac App Store is not required for v1. Use a Developer ID signed and notarized DMG for direct sale.

### 4.2 Suggested repo structure

```text
Sorrelgate/
  README.md
  LICENSES/                     # Third-party notices; app source stays proprietary
  docs/
    PRODUCT_SPECIFICATION.md
    ARCHITECTURE.md
    SECURITY_AND_PRIVACY.md
    ACCEPTANCE_TESTS.md
    DECISIONS.md
  Sorrelgate.xcodeproj/
  App/
    SorrelgateApp.swift
    UI/Transactions/
    UI/Workspace/
    UI/Review/
    UI/Settings/
    UI/Assistant/
  Packages/SorrelgateCore/
    Sources/
      Domain/                   # Value objects, state, errors
      Persistence/              # SQLite, migrations, backups
      Documents/                # Import, PDF, OCR, digest, index
      Recognition/              # Classify and propose fields
      Workflows/                # Template engine and tasks
      Validation/               # Evidence-linked checks
      Drafts/                   # Timeline, communication text
      Exports/                  # Copies and manifest
      Actions/                  # Typed and guarded business commands
      Agents/                   # Provider-agnostic orchestrator
      Security/                 # Permission / audit / redaction
    Tests/
  Tests/UITests/
  Fixtures/Synthetic/           # Fake data only; no client docs
  Scripts/                      # Build/sign/test automation, dev only
  .github/workflows/            # macOS compile/test and license audit
```

### 4.3 Architecture rules

1. **One implementation per business operation.** SwiftUI and LLM both invoke `ActionDispatcher` commands, not independent paths.
2. **No business logic in UI event handlers** beyond invoking commands and presenting results.
3. Separate extraction from interpretation: raw OCR text, proposed structured value, human-approved value, all separately persisted.
4. **Provenance first**: any extracted value or issue has document ID, page number, original file SHA-256, processing method/version, and confidence or reason. Unsupported observations are flagged as unverified.
5. Local persistence is durable: atomic writes/migrations, backup+restore, no destructive automatic cleanup.
6. Model-independent orchestration: typed tool registry, bounded planning, capability permissions, deterministic checks, action receipts; AI is never authoritative for final state.
7. Background processing uses Swift Concurrency/actors, cancellation, progress and checkpoints; UI remains responsive.
8. Do not package unlicensed blank copyrighted forms or confidential sample documents.

### 4.4 Data model (relational entities)

- `Office(id, name, default_template_id, settings_json, created_at)`
- `Agent(id, office_id, display_name, email, notes)`
- `Transaction(id, office_id, agent_id, label, address, workflow_type, stage, status, created_at, updated_at)`
- `Contact(id, transaction_id, role, name, email, phone, verified_at)`
- `Template(id, office_id, workflow_type, version, name, created_at, immutable_snapshot_hash)`
- `TemplateTask(id, template_id, task_key, label, order_index, required, condition_json, document_type_key, instructions)`
- `Task(id, transaction_id, task_key, status, owner, due_at, notes, verified_by_user, last_changed_at)`
- `Document(id, transaction_id, sha256, original_filename, internal_copy_path, mime_type, page_count, imported_at, import_source)`
- `DocumentPage(id, document_id, page_index_zero_based, extracted_text, method, confidence, processing_version)`
- `DocumentClassification(id, document_id, proposed_type, confidence, status, human_override, model_version, evidence_json)`
- `ExtractedField(id, transaction_id, document_id, page_index, field_key, raw_value, normalized_value, status, confidence, evidence_json, source_method)`
- `TaskEvidence(task_id, document_id, page_index, evidence_type, status, notes)`
- `Issue(id, transaction_id, type, severity, description, source_document_id, source_page, status, dismissed_reason)`
- `TimelineEvent(id, transaction_id, label, date_value, source_field_id, status, verified_by, notes)`
- `Draft(id, transaction_id, kind, template_id, generated_content, source_values_json, status, reviewed_at)`
- `ActionReceipt(id, transaction_id, action_type, actor_type, approval_id, inputs_hash, result_json, changed_ids_json, created_at)`
- `AgentRun(id, transaction_id, provider, request, plan_json, state, started_at, ended_at)`
- `Approval(id, transaction_id, action_id, scope, status, requested_at, resolved_at)`
- `Export(id, transaction_id, output_path, manifest_hash, created_at)`

**Persist template snapshots per transaction**, because office requirements change. Database rows should use UUID identifiers; path names are never authority or primary keys. User data is local and should not be uploaded to GitHub or diagnostic services.

## 5. Document engine

### 5.1 Processing pipeline

1. **Discover** user-selected files/folder; canonicalize URLs and reject path traversal, symlink escapes where relevant, unsupported types, oversized decompression, and malicious archive structures. No files read outside authorized selection.
2. **Copy originals** into app-managed transaction storage without editing; record file attributes and SHA-256; avoid duplicate copies by content hash (but retain distinct import provenance records).
3. **Open** with PDFKit; collect text layer per page. Identify page text density/quality and image-only pages.
4. **OCR** only necessary pages via Vision, with pre-rendering at appropriate resolution and language configuration; retain page spans and confidence; skip pages where native text is sufficient.
5. **Normalize** extraction for search while retaining raw text; capture original page mapping. For combined packets, do not split by guessed document boundaries without review in v1.
6. **Classify** document types based on file names, page headers, optional on-device LLM support; return a ranked candidate list and reason. Unknown remains unknown.
7. **Extract** candidate key facts from known sections, using rules and optional structured LLM; retain unmodified verbatim text evidence.
8. **Validate** cross-document values with deterministic comparisons and candidate-evidence links; detect duplicate hashes and near-duplicates only with explicit threshold.
9. **Map** candidate documents to required checklist document types; a match means detected, **not automatically verified.**
10. **Report** findings and allow corrected labels/values; the corrected information drives drafts and exports.

### 5.2 Signature handling

For v1: identify candidate signature-bearing pages using keyword cues and basic visual hints; surface them for human review. Do **not** advertise automatically verified legal signatures, signatory identity, handwriting authenticity, complete initials, or DocuSign audit verification. Actual completed status requires human approval; false positives must never mark a transaction legally compliant.

### 5.3 Provenance and audit

One-click from issue to original PDF page. Store displayed quote/region and extraction method; a model can propose a field but cannot remove the evidence trail. On update, persist old and new values and user who approved. Export includes a manifest with hashes for originals and produced files.

### 5.4 Documents and file output

Use a stable export layout:

```text
123 Main Street - Transaction Package/
  00_Overview/Transaction_Summary.pdf
  00_Overview/Outstanding_Items.pdf
  00_Overview/Timeline.pdf
  00_Overview/Document_Manifest.csv
  01_Agreements/
  02_Disclosures/
  03_Escrow_and_Closing/
  04_Other/
  99_Original_Filenames_Map.csv
```

These are output copies only; the internal original store is never mutated. User may customize folder names and categories. If a category is uncertain, the document goes in `04_Other` with a review marker rather than being silently discarded.

## 6. Workflow engine and office customization

- Templates are editable in normal UI, support drag-reorder, optional vs required, unique task identifier, notes, linked document label, owner, due date and optional conditions driven by user selections.
- No arbitrary scripting for user templates in v1; structured conditions only (e.g., `property_has_hoa == true`, `agent_requests_lender_copy == true`) to avoid unpredictable behaviors.
- Excel import can map columns after preview. Import rows as inactive proposals until confirmed; preserve original spreadsheet as evidence.
- A single app supports multiple offices, each with an independent saved profile, naming scheme, checklists, and email templates.
- Task statuses must distinguish not started, waiting, ready for review, completed, not applicable; inability to find a document should not be auto-translated into a legal assertion.
- When office templates change, existing transactions continue on their recorded snapshot. Offer explicit migration with diff and rollback.

## 7. AI agent and tool execution

### 7.1 Core goal

User speaks in natural language and the LLM **executes validated internal business actions**, not mouse automation, shell code, or external web browsing. The app must remain fully usable when the model is unavailable.

### 7.2 Architecture

`User request -> ProviderAdapter -> Plan -> Typed ActionDispatcher -> Authorization/Approval -> Domain Service -> Verified ActionReceipt -> Summary + Review Queue`.

Agents never directly edit SQLite, arbitrarily read a filesystem path, run shell commands, execute generated code, send network requests, or bypass application policy. Model output is treated as an untrusted proposal.

### 7.3 V1 tool catalog

| Tool | Behavior | Risk | Approval |
|---|---|---|---|
| `transactions.list` | Query current authorized transactions | Read | No |
| `transactions.create` | Create transaction | Reversible write | No |
| `transactions.updateMetadata` | Propose/update non-consequential fields | Write | Yes for verified dates/financial terms |
| `documents.list` | Read metadata and safe retrieved excerpts | Read | No |
| `documents.importSelected` | Import user-granted files | Reversible write | Initial file picker grant |
| `documents.classify` | Create reviewable suggested labels | Reversible write | No |
| `documents.search` | Retrieve permitted text and source pointers | Read | No |
| `documents.previewPage` | Display page pointer to UI | Read | No |
| `fields.propose` | Suggest values with provenance | Reversible write | No |
| `fields.confirm` | Mark legally consequential field verified | High-consequence | Explicit user confirmation |
| `checklist.list` | Retrieve tasks | Read | No |
| `checklist.matchDocuments` | Suggest linkage between docs/tasks | Reversible write | No |
| `checklist.updateTask` | Change progress status | Reversible write | Yes for completed legal-signature task |
| `issues.scan` | Generate evidence-backed issue candidates | Read/write findings | No |
| `timeline.prepare` | Create draft from verified dates | Draft | No |
| `drafts.prepareEmail` | Produce proposed message (no sending) | Draft | No |
| `drafts.prepareEscrowWorksheet` | Produce high-review worksheet | Draft | Required human review |
| `exports.preview` | Show proposed package/filenames | Read | No |
| `exports.writeSelectedDestination` | Save files to selected folder | External filesystem write | Human approval before write |
| `history.undo` | Reverse supported reversible actions | Controlled write | Confirm where appropriate |

No tool in v1 can send email, place orders, sign documents, delete originals, negotiate, or provide legal opinions.

### 7.4 Agent lifecycle

- **Plan:** interpret request and discover needed tools; ask at most one focused question if essential (e.g., which of two transactions) and otherwise proceed with safe reversible work.
- **Execute:** each command is typed, validated, bounded, idempotent where possible, and logged. Tool call carries transaction scope, user grant, action ID, timeout, and expected precondition.
- **Verify:** read real `ActionReceipt`s and transaction state. Never report success based solely on model prose or intent.
- **Review:** grouped review queue for ambiguous data, dates, signatures, export destinations, external correspondence. Show brief user-friendly descriptions.
- **Finish:** summarize completed, remaining, blocked and needs-review work with one-click source evidence. Do not tell user a deadline was legally calculated unless confirmed source rules exist and human approved.

### 7.5 Provider policy

- **Default v1:** Apple Foundation Models on eligible Apple Intelligence Macs; feature detect at runtime. No per-use cloud API charge. Use small, targeted context payloads; avoid inserting complete 50-PDF bundles into model prompt.
- **Fallback:** fully functional non-AI manual UI plus deterministic document processing and checklists.
- **Optional future provider:** cloud bring-your-own-key (BYOK), Keychain key storage and explicit per-workspace consent before transmitting client text; show what types of data leave the Mac; never default to cloud.
- **Optional future provider:** local open-weight model via an audited runtime and separately audited model license. Do not bundle large unknown-license weights initially.
- The consumer ChatGPT subscription is **not** an unlimited API entitlement. Cloud inference costs require a separately approved arrangement.

### 7.6 Token, prompt injection, and privacy controls

- Search/field evidence retrieval instead of dumping entire document corpora to a model. Chunk with document/page IDs; max excerpts per tool result; deterministic citations.
- PDFs and email drafts are untrusted inputs; text inside a document is not a system instruction. Model cannot gain extra permissions from any retrieved content.
- Hard transaction scope per agent run and permission checks inside each tool; minimum necessary data returned to the model; no cross-office retrieval without user-approved switch.
- Rate and step limits, bounded retries and cancellation; deduplicate action IDs; tool-level timeouts.
- User can inspect the action history and reverse supported changes. Model cannot assert its own approvals.

## 8. Rule-based extraction and deadline handling

- Fields are **proposed** with `raw`, `normalized`, `source`, `confidence`, and `status = unconfirmed` until verified. The initial test corpus should include multiple conflicting closing dates and addenda.
- Normalize dates only with explicit locale and date semantics. Use calendar dates (not UTC timestamps) for contractual dates; preserve original string and source context.
- Do not use a default 17-day inspection or other boilerplate deadline as an authoritative prediction; signed agreement terms, amendments, delivery events, and contract version matter.
- Timeline entries come from confirmed dates. Unknown dates yield `Needs confirmation` placeholders, not guessed dates.
- An agent drafting a timeline or email must not invent names, addresses, financial values, recipient email addresses, or terms; use labeled placeholders pending verification.

## 9. Security, privacy, compliance

**Baseline**:
- Customer docs stored locally in app-specific Application Support storage, with restrictive file permissions; no telemetry of document content; no default uploads. App does not depend on background cloud servers.
- Treat local disk encryption separately from application encryption: do not claim application-level encryption unless implemented and tested. Recommend FileVault; consider optional password-encrypted export in v1.x.
- Keychain for keys and secrets; never log documents, full extracted text, passwords, or API keys. Support privacy-preserving troubleshooting bundle (version, error codes, anonymized timings only).
- File access via native file/folder picker and security-scoped permissions where required. Limit file-system access; test on a clean normal-user account.
- Use secure DB transactions, migrations and backups, atomic exports to temporary directory then rename; periodic local backup with clear restore workflow.
- Treat PDF parsing as untrusted input: guard against malformed files, decompression bombs, path attacks, very large files, malware in attachments; never execute embedded scripts/macros.
- No blank licensed C.A.R. forms redistributed or embedded. Process only transaction-specific customer-authorized materials consistent with usage rights. Have license and legal policy reviewed before commercial launch.
- Do not classify the software as providing licensed real estate services. Requirements and notices must preserve human broker/agent supervision.
- Product documentation must say "organizational assistance, not legal or brokerage compliance certification" without making that disclaimer a substitute for technical safeguards.

**Threats to test**: malicious PDF prompt injection; cross-office data leak; overbroad folder read; silent source corruption; OCR date confusion; wrong transaction auto-match; duplicated agent command; unauthorized export; stale template changes; compromised API key if optional cloud support added.

## 10. Performance and quality targets

Targets below are **engineering acceptance thresholds**, not measured outcomes:

| Metric | Target or gate | Method |
|---|---|---|
| UI responsiveness | interactive while OCR running; most local UI actions under 200 ms | Xcode Instruments and UI telemetry (local) |
| Import reliability | zero lost originals; retryable partial failures for a 50-PDF / 300-page mixed batch | fixture test on target Mac |
| Original integrity | 100% SHA-256 match after copy and upon export | test every fixture |
| Document classification | macro-F1 >=0.95, with unknown/abstain separately measured | blind held-out labeled set |
| Field extraction | >=0.98 precision on automatically proposed high-confidence core fields; report coverage too | held-out ground truth |
| Source traceability | 100% findings open correct original PDF and page | audit all test cases |
| Wrong verified completion | zero agent-created 'verified' legal-signature/deadline statuses without human approval | adversarial tests |
| Model workflow completion | >=0.90 for 30 representative safe multi-step prompts on supported hardware | deterministic scoring of receipts |
| Approval enforcement | 100% of approval-required actions blocked without approval | unit/integration/e2e |
| User time saving | median >=15 minutes per transaction after review/correction | human baseline vs assisted, comparable tasks |
| Clean Mac install | no terminal, Python, Homebrew, developer tools or login | acceptance on clean nondeveloper Mac |
| Offline function | all manual/core document tasks offline; AI where model available | disable networking in test |
| Crash recovery | no corrupted transaction data; checkpoint and restart | terminate during each stage |

Keep separate datasets for development and final held-out evaluation. Do not present accuracy without sample size, denominators, coverage and error categories. Any critical failures remain release blockers even if averages pass.

## 11. Tests and evidence collection

**Fixture collection**: synthetic templates and fake names/property details created for unit/CI tests; for product evaluation, 20+ appropriately authorized, redacted real transaction packages including multiple offices and edge cases, with explicit permission and no data checked into Git. Separate training/dev/test cases. Include scanned pages, rotated pages, missing pages, addenda, contradictory dates, multiple signers, duplicates, unreadable handwriting, and 100+ page packets.

**Test layers**:
- Unit: each parsing, normalization, matching, workflow and permission function; deterministic golden files.
- Property/negative: never overwrite original, never silently promote candidate to verified, never send external messages, cannot escape transaction scope.
- Integration: PDFKit/Vision extraction, SQLite schema migrations, app restart, Excel import, export manifest, model tool call receives permission denial.
- End-to-end UI: onboarding, create transaction, import, correction, checklist, draft, export, restore, nontechnical usability.
- Agent E2E: 30 natural-language scenarios, seeded known file fixtures, compare actual backend state and action receipts, not model textual self-assessment.
- CI: `xcodebuild test` on macOS runner, package tests, Swift formatting/static analysis, SBOM/license scan; notarization pipeline separated and uses secure credentials.

**Quality gates**: no unresolved P0/P1 data-loss or privacy bugs, no exposed personal data in diagnostics, all permissions negative controls pass, nontechnical user completes workflow without assistance, signed-notarized release tested on clean Mac.

## 12. Distribution, licensing, and commercial operations

- Keep source repository private, application source proprietary. Dependencies must have independently checked license/NOTICE; pin each version and list transitive dependency tree. Apple SDK frameworks are not Apache-licensed, but are usable as part of commercial Mac apps under Apple terms.
- Product key/license implementation is optional for the first private pilot; for commercial release, prefer simple offline-capable signed license receipts, explicit device transfer policy, and an accessible lost-key process. Avoid introducing a permanent activation server dependency if offering a one-time product.
- Provisional pricing: pilot $149 / standard $249 per user; license covers the purchased major version with bug/security maintenance policy defined in legal purchase terms; paid future major upgrades optional.
- Mac release: configure Bundle ID, privacy strings and entitlements, app icon, versioning, Developer ID signing, hardened runtime, notarization and stapling; create drag-to-Applications DMG. Test Gatekeeper on a machine without Xcode. Apple Developer Program membership and any hosting/domain fees are business costs even with a no-per-request AI stack.
- Provide 1-page Quick Start, 3-minute onboarding, simple backup/restore and privacy FAQs, sample synthetic demo transaction, version and support contact.

## 13. Build sequence and hard exit criteria

### M0 — Repo, platform, skeleton
- Private repo, SwiftUI macOS project, CI, dependency/license baseline, `SorrelgateCore` package, SQLite migration framework.
- **Exit:** build/test pass on Mac; app creates/reopens an empty transaction; no customer terminal requirements.

### M1 — First vertical slice (highest priority)
- Import 10 PDFs, text extraction + OCR fallback, PDF preview, immutable original storage, SHA-256, checklist with manual linkage, simple export.
- **Exit:** end-to-end realistic example survives relaunch and preserves every original byte. No AI required yet.

### M2 — Office workflows and customization
- Both seller-side checklists, editable task templates and statuses, office profiles, CoreXLSX/CSV import/mapping, versioned template snapshots.
- **Exit:** TC can reproduce their office's actual workflow with no developer help.

### M3 — Document intelligence
- Classification/unknown handling, field proposals with page evidence, mismatch detection, duplicate reporting, issue review UI.
- **Exit:** measured ground-truth metrics and no unsupported completion/verification; all findings link to original page.

### M4 — Drafting and exports
- Confirmed timeline, introductory/follow-up drafts, escrow worksheet, packaged PDF reports, manifest, user-selected export folder.
- **Exit:** complete accepted-offer transaction assistance with manual controls, and review/exports correct.

### M5 — Agent execution
- Foundation Models adapter + feature detection, typed action registry, permissions, receipts, bounded orchestration, suggested prompts, review queue, agent E2E tests.
- **Exit:** single natural-language multi-step prompt produces real verified app state changes; zero prohibited actions.

### M6 — Commercial Mac release
- Backups, error recovery, accessibility, user testing, security/license audit, signed and notarized DMG, simple one-time license design.
- **Exit:** all quality gates above pass on clean nondeveloper Mac. Ship only then.

**No churn rule:** Do not continually rewrite the architecture. Decisions in this spec remain the baseline unless a reproducible failure or test result justifies a change. Favor completing a full vertical slice over building abstract frameworks or replacing dependencies without demonstrated benefit.

## 14. Decisions frozen vs to validate

**Frozen**: macOS native; Apple silicon first; local-first; offline manual workflow; SwiftUI/SWIFT; original file integrity; office-specific seller-side templates; two workflows; agent tool calling (not GUI automation); no external email sends; one-time commercial software; private source; no GPL/AGPL runtime dependencies; human review for consequential actions.

**Validation items**: supported minimum macOS 26 point release / Xcode version; exact Swift package versions; minimum acceptable Mac RAM based on benchmark; Apple Foundation Models feature availability and multi-step quality; whether CoreXLSX handles sample spreadsheet layout; customer office template import edge cases; signature-page candidate accuracy; nature of licensing and legal review; user time-saved benchmarks; developer signing credentials; accessibility testing.

## 15. Primary external references (checked 2026-11-20)

- Apple Foundation Models overview and tool calling: https://developer.apple.com/documentation/foundationmodels/
- Apple on-device model availability: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
- Apple Vision OCR: https://developer.apple.com/documentation/vision/recognizing-text-in-images
- Apple macOS direct distribution: https://developer.apple.com/macos/distribution/
- Apple notarization: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- CoreXLSX Apache 2.0: https://github.com/CoreOffice/CoreXLSX
- California DRE unlicensed assistants: https://www.dre.ca.gov/Licensees/UnlicensedAssistants.html
- California DRE 2026 AI advisory: https://www.dre.ca.gov/Licensees/Advisories/Advisory_2026_03_17_AI_in_California_Real_Estate.html
- California Association of REALTORS forms policy: https://www.car.org/transactions/zipform/zf/standardformsterms

## 16. First customer interview/test inputs

Before coding domain-specific classification, obtain **with permission** the TC's task spreadsheet, their "To do for listings/seller side" checklist, empty sanitized office submission templates where permitted, anonymized sample generated document packages and timeline/email examples, document naming conventions, and a list of exceptions they encounter. Do not require actual confidential client documents to be stored in public repositories or transmitted to a cloud model.

**This plan is sufficiently specific to begin M0/M1 immediately.** It intentionally avoids pretending that real-world classification accuracy, LLM performance, regulatory sufficiency, customer value, or Apple AI compatibility have already been validated.