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
