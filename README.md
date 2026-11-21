# Sorrelgate

**Mac-native, local-first AI assistant for California real estate transaction coordinators.**

> **Status:** M1 ingestion safety [PR #16](https://github.com/Kajin-0/sorrelgate/pull/16) **merged** as `d896b47`; [macOS CI #92](https://github.com/Kajin-0/sorrelgate/actions/runs/44909992770), [#93](https://github.com/Kajin-0/sorrelgate/actions/runs/44909997219) and [#95](https://github.com/Kajin-0/sorrelgate/actions/runs/44910402256) PASS **51 XCTest + native SwiftUI app build**. Controlled five-page raster OCR recognized 7/7 chosen words for baseline/4° skew/low contrast/2.2px blur, with blank-page abstention; FIFO mid-copy cancellation after 256 KiB staged, POSIX permission denial/retry and archived-original SHA verification also passed. No real-world scan accuracy, ENOSPC, Finder sandbox scope, physical Mac UX, safe LLM controls or signed/notarized distribution yet. **Commercial NO-GO; $0 additional cost.**

Sorrelgate helps a nontechnical transaction coordinator organize signed PDFs, track office-specific tasks, identify potential missing paperwork or contradictory information, draft communications, and export a reviewable transaction package. The application is designed to be operated either through simple native Mac controls **or** through natural-language requests that invoke the same guarded backend actions.

## First release

- **Platform:** Apple-silicon macOS application, SwiftUI + Swift 6, with macOS 26+ as the provisional minimum to validate on the target Mac.
- **Primary user:** Independent California **seller-side** transaction coordinator working across different offices and agents.
- **Workflows:** "Prepare a House for Sale" and "Accepted Offer — Seller Side".
- **Core engine:** PDFKit extraction, Vision OCR fallback, immutable document copies with SHA-256, configurable checklists, provenance-linked validation, approved timelines and drafts, safe export.
- **AI:** Apple Foundation Models when available; provider-agnostic typed tool layer; offline manual mode always functional. No autonomous sending, signing, legal decisions, or arbitrary computer access.
- **Experience:** No terminal, Python, Homebrew, API keys, or cloud account for customers' core workflows. Developer tools can be as sophisticated as necessary.
- **Business:** Planned one-time proprietary commercial Mac license. Indicative $149 pilot / $249 retail; not a final commercial commitment.

## Read this first

| File | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Durable context and mandatory operating rules for Codex/other agents |
| [`docs/STATUS.md`](docs/STATUS.md) | Current verified state, blockers, next action; **read at session start** |
| [`docs/PRODUCT_SPECIFICATION.md`](docs/PRODUCT_SPECIFICATION.md) | Full functional scope, flows, data model, quality gates |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Module boundaries, persistence, execution model |
| [`docs/AGENT_ACTIONS.md`](docs/AGENT_ACTIONS.md) | AI tool contracts and approval policy |
| [`docs/IMPLEMENTATION_CHECKLIST.md`](docs/IMPLEMENTATION_CHECKLIST.md) | M0–M6 milestone gates; check only with actual tests |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | Timestamped, append-only work history |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Architectural and product decisions + rationale |
| [`docs/CODEX_MASTER_PROMPT.md`](docs/CODEX_MASTER_PROMPT.md) | Instructions for starting Codex on an authorized Mac |
| [`docs/workflows/CA_SELLER_SIDE_STARTER.json`](docs/workflows/CA_SELLER_SIDE_STARTER.json) | Editable starter tasks, **not legal forms or legal advice** |

## Tracked implementation issues

Milestones are tracked in [issues #1–#7](https://github.com/Kajin-0/sorrelgate/issues), each with explicit acceptance tests. [Issue #8](https://github.com/Kajin-0/sorrelgate/issues/8) was closed after the owner explicitly approved public repository visibility; it is **not a development blocker**.

## Develop without Codex — ChatGPT + GitHub Actions

GitHub Actions automatically runs \`swift test --parallel\` and builds the native Mac app on \`macos-26\` whenever \`main\` or a \`feature/**\` branch is pushed. See [CI](.github/workflows/macos-ci.yml) and [Actions runs](https://github.com/Kajin-0/sorrelgate/actions).

The source of the native Xcode project is [\`project.yml\`](project.yml), generated with XcodeGen (MIT; developer-only). On a developer Mac: \`brew install xcodegen\`, \`xcodegen generate\`, then open \`Sorrelgate.xcodeproj\`. Customers never install developer tools. Artifacts from CI are **unsigned development builds**, not customer releases.

## $0 early MVP and assisted Mac pilot

No Apple membership or paid API is required during current testing. When the real Mac user is ready to help, Codex can install **free Xcode** and build Sorrelgate from source on their Mac; no terminal commands are required of the user. This is an assisted pilot, not the final one-click public installation. See [FREE_MAC_TESTER_HANDOFF.md](docs/FREE_MAC_TESTER_HANDOFF.md).

## No local Mac: testing and first external beta

The owner currently has **no Mac**. Continue active implementation using GitHub Actions macOS runners and synthetic fixtures, while deferring hands-on UI and on-device model verification until a Mac tester can receive a build. An unsigned CI archive is **not** a normal nontechnical installation package. For the first low-friction external beta, prepare a signed and notarized build (or an eligible TestFlight distribution) when developer-account credentials are available. See [`docs/REMOTE_TEST_STRATEGY.md`](docs/REMOTE_TEST_STRATEGY.md). Do not pause M1–M5 work solely to await hardware access.

## First coding goal — milestone M0/M1

Create a real transaction, import a mixed batch of PDFs, preserve original hashes, extract text / OCR, display source pages, attach docs to an editable checklist, export a manifest, then close and reopen with state intact. **Build and test on a Mac**. Only after this verified vertical slice should broader automation be layered on.

## Repository and privacy

This repository is **public by deliberate owner choice**. Do **not** stop coding or request a visibility change. Public GitHub content is visible to others; do not commit real client contracts, personal/financial information, signatures, office credentials, blank copyrighted real estate forms, signing keys, or anything that must remain confidential. No open-source license for Sorrelgate's own application code has been granted merely by publishing it. License, support, distribution and commercial terms still require deliberate decisions. Third-party dependencies may be Apache 2.0, MIT, BSD or similarly audited commercially permissive licenses; Apple system frameworks remain subject to Apple terms.

## Maintainers / agent handoff

Every substantive implementation change must update [`docs/CHANGELOG.md`](docs/CHANGELOG.md) and [`docs/STATUS.md`](docs/STATUS.md) in the same PR, with exact test evidence or an explicit **not run** entry. Record architectural deviations in [`docs/DECISIONS.md`](docs/DECISIONS.md). See [`AGENTS.md`](AGENTS.md) for the full protocol.

**No customer data is included in this repository.** The starter workflow is based on a TC's described job rather than an authoritative compliance list.