# Sorrelgate — Decision register

**Policy:** Never silently reverse decisions. Append dated records with rationale, competing alternatives and outcome.

## ADR-001 — 2026-11-20T23:08:11-05:00 — Identity and scope
**Accepted:** Sorrelgate is a Mac-first, California **seller-side** transaction coordinator assistant, with two office-editable workflows: Prepare a House for Sale and Accepted Offer. No buyer-side or interstate rules in v1. **Why:** concrete TC workflow and shortest pilot feedback path.

## ADR-002 — 2026-11-20T23:08:11-05:00 — Native Mac stack
**Accepted provisionally:** Swift 6, SwiftUI, PDFKit, Vision OCR, SQLite, CoreXLSX, Apple Foundation Models on eligible hardware; Apple silicon, macOS 26+ to validate on real equipment. Developers may use terminal; customers never need it. **Why:** native usability, offline documents, minimal installation. **Unknown:** actual model availability/performance.

## ADR-003 — 2026-11-20T23:08:11-05:00 — Real LLM-driven application actions
**Accepted:** UI and LLM invoke the **same** typed domain actions via deterministic permissions, approval, scope and receipts. Agent has no arbitrary desktop/shell/network access and cannot legally verify signatures, deadlines or send emails. **Why:** useful natural-language execution with safeguards.

## ADR-004 — 2026-11-20T23:08:11-05:00 — Commercial and licensing
**Accepted direction:** Proprietary one-time-license macOS app, proposed $149 introductory / $249 standard; local-first and no mandatory paid API. Audit Apache 2.0/MIT/BSD/public domain dependencies and model weights; exclude GPL/AGPL runtime under initial policy. Apple system frameworks are under Apple terms, not Apache 2.0.

## ADR-005 — 2026-11-20T23:08:11-05:00 — GitHub repo protection
**Action required:** The selected repo was **public** at kickoff. Publish nonsecret documentation first; change to private before proprietary source or sensitive IP. Never commit customer PDFs, blank copyrighted C.A.R. forms or private credentials.

## ADR-006 — 2026-11-20T23:08:11-05:00 — Build order
**Accepted:** First deliver actual M0/M1 end-to-end Mac vertical slice. No premature multi-provider agent abstractions, integration work or rewrites without measured need. Maintain agent-ready architecture from first code.
