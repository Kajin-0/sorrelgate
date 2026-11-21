# Sorrelgate — Current verified state

**Last verified:** 2026-11-21T04:39:17.086Z (UTC)
**Phase:** M0 implemented, CI verified; physical Mac user testing outstanding.
**Repository:** https://github.com/Kajin-0/sorrelgate (public by owner's choice)
**Release:** NOT READY. Unsigned CI development build only; no notarized installer or real-world TC pilot.

## Verified CI results
- [GitHub Actions run #1](https://github.com/Kajin-0/sorrelgate/actions/runs/44866969670): **SUCCESS**, on commit \`36a0639b949dc8017ab428e063f31d38dd4cae94\`.
- Environment: macos-26-arm64 runner; **Apple Silicon arm64**; **Xcode 26.6**; **Swift 6.3.3**.
- \`brew install xcodegen\`: success; XcodeGen 2.46.0 (developer-only MIT tool).
- \`swift test --parallel\`: exit 0; **four XCTest cases invoked** (create/list, reopen persistence, missing-address rejection, SQL string stored as data). The separate Swift Testing harness reported **0 Swift Testing cases**; that line must not be mistaken for zero XCTest invocations.
- \`xcodegen generate --spec project.yml\`: exit 0; generated native project.
- \`xcodebuild -project Sorrelgate.xcodeproj -scheme Sorrelgate -configuration Debug -destination "generic/platform=macOS" -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build\`: **BUILD SUCCEEDED**.
- \`ditto\` packaging and \`actions/upload-artifact@v4\`: success. [Unsigned development build](https://github.com/Kajin-0/sorrelgate/actions/runs/44866969670), 216,314-byte archive, artifact ID 14692755902; expires 2026-11-28.
- These are **CI build and test** results; there has been **no physical user-interface smoke test**.

## Implemented
- Native SwiftUI transaction list, create-transaction sheet, selected detail, Settings.
- \`SorrelgateCore\` Swift package with typed create/list actions, input validation and local SQLite persistence.
- Core automated test cases and \`macos-26\` GitHub Actions pipeline.
- Project handoff protocol and change tracking available to regular ChatGPT and Codex.

## Milestone gates
| Milestone | State | Evidence |
|---|---|---|
| M0 Native Mac foundation / CI | IN PROGRESS (CI passed) | Actions run #1 green; interactive Mac launch and full M0 negative tests still required |
| M1 PDF import / OCR / preview / checklist / export | NOT STARTED | No PDF engine yet |
| M2 Office profiles / XLSX / versioning | NOT STARTED | No implementation |
| M3 Classification / linked document checks | NOT STARTED | No implementation |
| M4 Timeline / draft communications / exports | NOT STARTED | No implementation |
| M5 Guarded LLM-controlled actions | NOT STARTED | No model execution |
| M6 Commercial Mac release | NOT STARTED | No signed/notarized build or pilot |

## Next executable steps
1. Obtain a physical Mac smoke test of the [unsigned development build](https://github.com/Kajin-0/sorrelgate/actions/runs/44866969670) through authorized developer testing; confirm app launch, create, quit/reopen and transaction persistence. Never instruct nontechnical customers to bypass macOS Gatekeeper as the normal installation path.
2. Expand restart/SQLite failure tests and explicitly record findings for M0.
3. Implement M1: user-selected batch PDF intake, preserved original copies + SHA-256, PDFKit text extraction, Vision OCR fallback, preview and checklist/export, without a user terminal.
4. For each implementation iteration, check GitHub CI, update this file and append timestamped verification to CHANGELOG.

**Security/quality:** No real contracts or secrets in Git; all original PDF data must remain immutable. Cloud inference is opt-in only. Agent tool access is not implemented yet.
