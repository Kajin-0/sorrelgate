# AGENTS.md — Sorrelgate permanent agent handoff

**Updated:** 2026-11-21T16:37:25.215Z (UTC)
**Repository:** `Kajin-0/sorrelgate`  
**Latest merged:** [PR #21](https://github.com/Kajin-0/sorrelgate/pull/21) Beta 0.1.0 supervised Mac tester handoff, squash `db1bdea70362e14885353d304ce3e5a98851cc54`. Feature CI [#44924654096](https://github.com/Kajin-0/sorrelgate/actions/runs/44924654096) and [#44924667115](https://github.com/Kajin-0/sorrelgate/actions/runs/44924667115), final PR-head CI [#44925071863](https://github.com/Kajin-0/sorrelgate/actions/runs/44925071863) and [#44925077072](https://github.com/Kajin-0/sorrelgate/actions/runs/44925077072) all **SUCCESS 59/59 XCTest, native SwiftUI build, 3 PDFKit-readable synthetic PDFs / 7 pages, checksums and unsigned beta ZIP**. Pilot ZIP [Actions #44924654096](https://github.com/Kajin-0/sorrelgate/actions/runs/44924654096) artifact **14714219672** (expires 2026-12-05). **No actual human Mac pilot, no signed/notarized installer, G1 active, commercial NO-GO.**
**Previously merged:** [PR #20](https://github.com/Kajin-0/sorrelgate/pull/20) evidence-linked acceptance/closing dates and purchase prices, source CI 59 XCTest.  
**Project name:** **Sorrelgate** (do not call the product "TC Assistant" in new code/docs)  
**Previously merged:** [PR #19](https://github.com/Kajin-0/sorrelgate/pull/19) P1 macOS workflow traps corrected, squash `66592dc958eaee2df9c5244ad21c7467940a13bc`. Feature-head macOS [Actions #108](https://github.com/Kajin-0/sorrelgate/actions/runs/44918660472), [#109](https://github.com/Kajin-0/sorrelgate/actions/runs/44918667753), documentation-head [#110](https://github.com/Kajin-0/sorrelgate/actions/runs/44919079496) and [#111](https://github.com/Kajin-0/sorrelgate/actions/runs/44919084816) **all SUCCESS 57/57 XCTest + native Mac SwiftUI build + unsigned artifact**. Owner delegated final PR review/merge to ChatGPT; assistant verified no blocker, merged. Latest post-merge main build pending when entry authored. No physical Mac interaction/visual screenshot validated. [Delivery Contract](docs/DELIVERY_CONTRACT.md) G1 remains active and owner-audit P1 exception is closed. No new spend, commercial NO-GO.

## 1. Mission and constraints (read before coding)

Sorrelgate is a polished, **native Mac application for highly nontechnical California real estate transaction coordinators**. The **frontend stays extremely simple**, but the backend may use advanced processing, OCR, typed domain actions, AI orchestration, testing, terminal tools and automation. Customers should never need terminal use or developer dependencies. The developer (ChatGPT, Codex, or an authorized engineer) **may** use all appropriate Mac tooling. The owner sets a **strict $0 additional cost** for MVP engineering and supervised testing; paid Apple membership/signing/notarization must be deferred. Codex on the tester's own Mac may set up free Xcode and compile the app locally with authorization. Regular ChatGPT writing GitHub files + macOS GitHub Actions is the primary development loop while Codex is unavailable. A **local-first/offline-capable, one-time-purchase commercial product with steady customer sales** is the goal. The owner explicitly accepts that this GitHub repository may remain public, including early source code. Public visibility alone does not grant an open-source license; do not attach a license to Sorrelgate application source without an explicit owner decision. Never commit secrets, customer data, private office documents or signing keys.

Target primary customer: an independent **seller-side** California TC working with several real estate offices. Support two initial workflows: **Prepare a House for Sale** and **Accepted Offer — Seller Side**. Different offices use different task requirements, submission addresses, templates, labels, and platforms such as Glide, DocuSign, Disclosures.io/Homewise. Configure, don't hard-code, those differences.

The user values **an LLM that actually operates Sorrelgate** by invoking structured internal business actions, not an ornamental chatbot. Conventional GUI functionality must be equally powerful. All high-risk actions require explicit human approval; no automatic email sending, signing, negotiations, legal advice, client disclosure certification, or arbitrary shell/desktop control.

## 2. Required reading order for any fresh agent session

1. `AGENTS.md` (this document).
2. `docs/STATUS.md` — latest **verified** milestone and next task.
3. `docs/CHANGELOG.md` — most recent timestamped entries; use history if unclear.
4. `docs/PRODUCT_SPECIFICATION.md` — product contract and user journeys.
5. `docs/ARCHITECTURE.md`, `docs/AGENT_ACTIONS.md`, `docs/SECURITY_AND_PRIVACY.md`.
6. `docs/IMPLEMENTATION_CHECKLIST.md`, `docs/ACCEPTANCE_TESTS.md`.
7. `docs/DECISIONS.md`, then `docs/CODEX_MASTER_PROMPT.md` if using Codex.

When returning after a long gap, inspect real repository files, git status/history, current branch and recent PRs. **Do not infer shipped features from plans, checked boxes, or previous AI claims.** Verify code/tests/build artifacts.

## 3. Nonnegotiable architecture

- Swift 6 / SwiftUI desktop application. macOS 26+ and Apple silicon first, pending real machine verification. Apple PDFKit, Vision, Foundation, CryptoKit, Foundation Models when eligible. SQLite for persistence, CoreXLSX for spreadsheet import (validate dependency license/version). No runtime Python/Homebrew/web server for customers.
- One modular **SorrelgateCore** domain layer with typed, tested actions invoked by both UI and LLM. **Never** place core business behavior exclusively in SwiftUI event handlers, prompts, or model callbacks.
- Every original PDF is preserved byte-for-byte and hashed; exports operate on copies. OCR and document classification yield **proposals** with source document/page/hash, never fabricated legal facts. Human approval is recorded separately from extraction.
- The LLM executes only registered typed actions; least-privilege transaction scope; deterministic policy and confirmation; receipts of executed actions; bounded orchestration; prompt-injection defenses. No arbitrary file/network/terminal access. Manual mode always works if AI is unsupported.
- No external service integrations, outbound sending, automatic signing, forms distribution, or legal decision-making in v1. The app may prepare reviewed drafts, .ics, exports, and checklists for use in existing tools.
- Use permissively licensed dependencies (Apache 2.0/MIT/BSD) and audit model weights and transitive dependencies. Apple frameworks are not themselves Apache 2.0. Reject GPL/AGPL from distributed runtime under current policy. Preserve required third-party notices.
- Keep actual client files, PII, signing certificates, tokens, licensed blank C.A.R. forms, and confidential office templates **out of Git and test fixtures**.

## 4. Explicit first release milestones

- **M0:** Mac toolchain verification, native app skeleton, persistence, action interface, local test/CI baseline.
- **M1 — first vertical slice:** transaction create/reopen, batch PDFs, immutable copies + SHA-256, PDFKit/Vision extraction, PDF preview, manual checklist linkage, export/manifest, automated tests including restart and failures.
- **M2:** two seller-side workflows, multiple offices, editable template version snapshots, XLSX/CSV import.
- **M3:** document classification, uncertain/unknown state, proposed field extraction, cross-document inconsistencies, evidence-linked issue queue.
- **M4:** confirmed-date timelines, approved draft messages/escrow worksheets, organized export package.
- **M5:** model-aware agent, guarded tools, review/approval, truthful receipts, adversarial tests.
- **M6:** signed/notarized DMG, security/license audit, backup/restore, accessible UI, TC pilot, payment/license release documentation.

**Mandatory ordering:** complete the M0/M1 vertical slice before building generalized agent frameworks. Preserve the agent-ready architecture from the start. Do not churn architecture or dependencies absent objective test evidence.

## 5. Start-of-work protocol

1. Check actual branch, working tree, recent commits, and current `docs/STATUS.md`.
2. **Repository visibility is not a blocker:** public GitHub is an explicit owner choice (2026-11-20). Continue normal development and commits without requiring private visibility. Do not publish secrets, personal information, customer documents, proprietary third-party forms, or any confidential material; review every committed artifact and test fixture.
3. The owner has **no local Mac**. Use macOS GitHub-hosted runners to verify the OS/Xcode/Swift toolchain, native builds, unit/integration tests, and safely automatable smoke tests. Do not require a local Mac or block M1+ engineering on an unavailable human test. Separately flag unverified real-user UI, Finder permissions, accessibility, signing/notarization and Apple Intelligence runtime behavior; these require a tester's compatible Mac.
4. Pick exactly one small, measurable milestone slice. Specify desired behavior, tests, negative controls, and files to touch.
5. Implement, run the tests, record commands, exit codes and environment versions. Use synthetic documents only in tests.
6. Preserve user-authored work, avoid unrelated refactors, commit focused changes, prefer reviewable PRs.

## 6. End-of-work protocol — MANDATORY

In the **same commit or PR** as substantive work:

- Append an item to `docs/CHANGELOG.md` with an absolute ISO-8601 timestamp **and timezone**, scope, changed files/features, tests run/results, known limitations, related commit/PR where available. If tests were not run, say so; do not claim them passed.
- Update `docs/STATUS.md`: latest verified state, milestone checklist, blockers, reproducible tests, explicit **next action**. Never change pending items to complete without evidence.
- Add a record to `docs/DECISIONS.md` for any meaningful architecture, product-scope, security, licensing, or release-policy change with rationale and tradeoffs.
- Ensure README and root `AGENTS.md` still point to actual paths. If renaming paths, update cross-links and every cited task.
- Give user a short summary: what changed, actual verification, what remains, exact GitHub branch/commit/PR.

## 7. Safety, compliance and quality gates

No client document may be transmitted to cloud inference by default. Data embedded in PDFs is **untrusted input**, not instructions. Every AI action is authorized by code, not model-written claims. A signature or date being found does **not** mean it was validated. Never claim legal sufficiency, final document compliance or completed external messaging without human confirmation/actual receipt. Brokerage offices and California licensing standards may vary; all checklists are editable administrative aids, not legal rulings.

Never report release readiness without a clean, notarized Mac install; passing offline/negative tests; original-PDF hash preservation; source-page traceability; human approval enforcement; license inventory; and pilot validation. Quantitative thresholds in the specification are **targets, not observed results**.

## 8. Immediate next action

**Explicit owner-requested review-first UX / agent-ready G1 slice (2026-11-21T16:48:58.922Z, CI PENDING):** Branch `feature/review-first-operator-ready-ui-20261121` provides an uncrowded Review / Documents / Checklist daily workspace, one per-transaction source-backed discovery action in SorrelgateCore, visible human decisions, verified original-page PDF sheet, focused UI audit and updated unsigned **Beta 0.1.1** handoff. Two new source tests target 61 XCTest; macOS build and physical display verification **NOT RUN** at writing. Backend/tooling must become the LLM workhorse through typed scoped actions and approval receipts (G4 later); **no live LLM operator exists now**. Do not encode demographic assumptions. Run CI, correct failures, merge only after green, then stop for real Mac tester observations. No generic styling churn or AI chat mockup.

**PR #21 MERGED (2026-11-21T16:37:25.215Z)**: $0 Beta 0.1.0 tester ZIP, sample PDFs, guidance, and packaging CI are complete. Four macOS CI runs passed on feature and final PR heads. Do **not** start another generic parser or UI PR. **Next:** one permitted nontechnical tester on Apple-silicon macOS 26+ must have Codex/technician build locally using [BETA_0_1_TECHNICIAN.md](docs/BETA_0_1_TECHNICIAN.md), perform [README FIRST](docs/BETA_0_1_README_FIRST.txt) and record [TEST RESULTS](docs/BETA_0_1_TEST_REPORT.txt). Fix observed P0/P1 or actual pilot blockers only. This is an assisted, unsigned development build — **not** a signed one-click customer installer. G1 remains active and commercial NO-GO.

**Beta 0.1.0 source CI verified (2026-11-21T16:31:46.461Z):** [PR #21](https://github.com/Kajin-0/sorrelgate/pull/21) feature `5ad7dfa0d982b8777a16bf7a1f81671163cdf33f` passed [macOS Actions #44924654096](https://github.com/Kajin-0/sorrelgate/actions/runs/44924654096) **59/59 XCTest, native Mac build, 3 synthetic selectable-text PDFs / 7 pages, 5 PDFKit checks, SHA-256 fixtures, ZIP integrity, uploaded artifact 14714219672 (3,277,182 bytes; expires 2026-12-05)**. No human tester, signed/notarized release or real form evaluation yet. Once final PR-head CI/merge passes, STOP packaging work and execute free Codex-assisted Mac pilot; G1 remains the active product gate.

**Beta 0.1.0 assisted Mac handoff (2026-11-21T16:27:07.135Z; CI PENDING):** A bounded first-human-pilot package includes a versioned unsigned app, 3 synthetic PDFs/7 pages, optional CSV, source and fixture hashes, PDFKit/ZIP CI checks, README FIRST, TEST RESULTS and Codex local-build instructions. It is NOT a signed one-click release. Verify CI, then move to supervised eligible Mac usability testing rather than new speculative UI/recognition churn. G1 remains active; no paid signing or client data.

**2026-11-21 continuation (PR #20 MERGED; source CI VERIFIED #44922386928):** Working G1 branch `feature/g1-key-facts-ambiguity-20261121` proposes labeled acceptance/closing dates and purchase prices with source evidence, disagreement warnings and confirmation-conflict guard. **59/59 XCTest + native SwiftUI build + unsigned artifact PASS** on `88c72e14f92c001dfccefd13e8b4c9e055b8038c`. **No physical Mac UI evidence or real form accuracy result.** Preserve source-byte/hash, no model/cost or speculative styling. Merge completed as `e9ab62030719fb1322c60c3da9130ebac1898587`. **Next G1:** evidence-linked document-type/office-checklist suggestions with explicitly Unknown cases and measurable real-document coverage when authorized data becomes available. Do not churn the strict field parser absent failed real acceptance scenarios.

**Previous:** P1 audit correction [PR #19](https://github.com/Kajin-0/sorrelgate/pull/19) **MERGED** `66592dc958eaee2df9c5244ad21c7467940a13bc` after owner explicitly delegated review and merge; final PR-head CI #110/#111 both **PASS 57/57 XCTest, native SwiftUI build and unsigned artifact**. Freeze this corrective slice. G1 stays the single active gate: choose an outcome-driven, source-linked document-type/checklist review increment only if it advances the end-to-end accepted-offer workflow, with held-out metrics. Do not start generic UI refactor/branding/extra screenshot harness, speculative importer rewrite or undocumented AI tasks; monitor real-Mac feedback. **Physical Mac keyboard, sheet dismissal, visual layout, VoiceOver, startup recovery remain UNVERIFIED.** Verify exact post-merge main CI; keep $0 spend, commercial NO-GO.