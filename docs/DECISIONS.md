# Sorrelgate — Decision register

**Policy:** Never silently reverse decisions. Append dated records with rationale, competing alternatives and outcome.

## ADR-007 — 2026-11-20T23:19:47-05:00 — Public repository accepted; steady sales prioritized
**Accepted (supersedes ADR-005):** Keep `Kajin-0/sorrelgate` public if desired. **Public visibility is not a stop gate** for implementation, releases, or sales. The owner prioritizes a useful product and steady commercial customers over concealing early source. Continue to protect credentials, private client information, confidential office templates, licensed third-party forms and signing materials. Do not add an open-source license to Sorrelgate's own code unless the owner expressly chooses it. Publishing code publicly makes it viewable/copiable in practice even if its license does not grant redistribution; price and support based on delivered value, not source secrecy. **Tradeoff:** public code can be inspected or replicated; commercial distribution and app licensing can still be offered.

## ADR-001 — 2026-11-20T23:08:11-05:00 — Identity and scope
**Accepted:** Sorrelgate is a Mac-first, California **seller-side** transaction coordinator assistant, with two office-editable workflows: Prepare a House for Sale and Accepted Offer. No buyer-side or interstate rules in v1. **Why:** concrete TC workflow and shortest pilot feedback path.

## ADR-002 — 2026-11-20T23:08:11-05:00 — Native Mac stack
**Accepted provisionally:** Swift 6, SwiftUI, PDFKit, Vision OCR, SQLite, CoreXLSX, Apple Foundation Models on eligible hardware; Apple silicon, macOS 26+ to validate on real equipment. Developers may use terminal; customers never need it. **Why:** native usability, offline documents, minimal installation. **Unknown:** actual model availability/performance.

## ADR-003 — 2026-11-20T23:08:11-05:00 — Real LLM-driven application actions
**Accepted:** UI and LLM invoke the **same** typed domain actions via deterministic permissions, approval, scope and receipts. Agent has no arbitrary desktop/shell/network access and cannot legally verify signatures, deadlines or send emails. **Why:** useful natural-language execution with safeguards.

## ADR-004 — 2026-11-20T23:08:11-05:00 — Commercial and licensing
**Accepted direction:** Proprietary one-time-license macOS app, proposed $149 introductory / $249 standard; local-first and no mandatory paid API. Audit Apache 2.0/MIT/BSD/public domain dependencies and model weights; exclude GPL/AGPL runtime under initial policy. Apple system frameworks are under Apple terms, not Apache 2.0.

## ADR-005 — 2026-11-20T23:08:11-05:00 — Initial repo protection assumption (SUPERSEDED)
**Historical decision only:** Originally required switching from public to private before source development. **Superseded by ADR-007** at the owner's explicit direction. Still never commit customer PDFs, blank copyrighted C.A.R. forms, credentials or other confidential material.

## ADR-006 — 2026-11-20T23:08:11-05:00 — Build order
**Accepted:** First deliver actual M0/M1 end-to-end Mac vertical slice. No premature multi-provider agent abstractions, integration work or rewrites without measured need. Maintain agent-ready architecture from first code.

## ADR-008 — 2026-11-21T04:36:43.885Z — ChatGPT + GitHub Actions as primary implementation loop
**Accepted:** Regular ChatGPT via connected GitHub writes implementation files; a public-repository GitHub Actions workflow runs Swift package tests and native Xcode builds on macOS 26 Apple-silicon runners. Codex is optional. XcodeGen (MIT, development-only) generates the native Xcode project from a readable project.yml; users never install XcodeGen. App uses SwiftUI and a local SorrelgateCore Swift package with SQLite3 (system library). Build output is unsigned test-only until commercial signing/notarization. **Tradeoff:** CI proves compilation and unit tests, not interactive usability or supported Foundation Models runtime; real Mac smoke tests remain required.

## ADR-009 — 2026-11-21T04:54:03.882Z — No owner Mac; CI-first development and deferred physical beta
**Accepted:** The owner has **no local macOS machine**. Regular ChatGPT + GitHub Actions macOS runners will handle source development, compilation, automated unit/integration tests, synthetic PDF fixtures, and feasible headless launch verification. Lack of an owner Mac **must not block** implementing M1–M5. Physical interaction, real-world usability, Finder permissions, accessibility, Apple Intelligence runtime tests, and clean installation remain **explicitly unverified** until a real Mac tester is available. The first external tester build must target a low-friction signed/notarized Mac installer (or supported TestFlight route), contingent on Apple developer credentials; an unsigned archive is development-only. **Rationale:** Minimize friction and avoid premature tester requests while still preserving evidence-based quality gates. **Tradeoff:** Some UI/system-specific failures will only be discovered at beta, so keep functionality modular and testable in CI.


## ADR-010 — 2026-11-21T05:02:40.473Z — First PDF/document vertical slice
**Accepted:** Build a typed Swift actor `DocumentWorkspace` around local SQLite document/checklist metadata, immutable file copies by SHA-256, PDFKit source page extraction, Vision OCR fallback for pages without digital text, copy-only exports with hash verification, and manual document-to-task links. Do not create a cloud dependency or require Mac terminal use. Document import is user-selected and task execution is serializable in the actor. **Tradeoffs:** Initial document metadata resides in a separate SQLite file from transaction metadata, with transaction UUID scoping; batch progress and cancel are controlled by the GUI. OCR failures remain reviewable/unavailable rather than silently asserting success. Test user-visible Finder and OCR behavior later on external Mac; CI tests gate core correctness.

## ADR-011 — 2026-11-21T05:14:07.576Z — Free assisted pilot and versioned seller-side checklists
**Accepted:** Spend $0 additional during MVP development and supervised testing. The first Mac tester may authorize Codex to install free Xcode/developer tools, build Sorrelgate locally from source, and open it on their Mac; Apple paid developer enrollment, signing, notarization and cloud inference are deferred until a strong MVP. **This is not the final one-click customer installer.** Starter checklist entries are a versioned embedded administrative resource; an atomic idempotent per-transaction snapshot never overwrites existing custom tasks. The source contains no licensed blank C.A.R. forms.
