# Sorrelgate — Current verified state

**Last verified:** 2026-11-21T04:39:17.086Z (UTC)
**Phase:** M0 CI verified; owner has NO Mac; interactive external tester validation deferred. Work proceeds to M1 using CI.
**Repository:** https://github.com/Kajin-0/sorrelgate (public by owner's choice)
**Release:** NOT READY. Unsigned CI development build only; no notarized installer or real-world TC pilot. Signed distribution will be necessary for normal low-friction use by a nontechnical Mac tester.

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
| M0 Native Mac foundation / CI | IN PROGRESS (CI passed) | Actions run #1 green; add automation and negative tests. Human Mac testing deferred to external beta |
| M1 PDF import / OCR / preview / checklist / export | NOT STARTED | No PDF engine yet |
| M2 Office profiles / XLSX / versioning | NOT STARTED | No implementation |
| M3 Classification / linked document checks | NOT STARTED | No implementation |
| M4 Timeline / draft communications / exports | NOT STARTED | No implementation |
| M5 Guarded LLM-controlled actions | NOT STARTED | No model execution |
| M6 Commercial Mac release | NOT STARTED | No signed/notarized build or pilot |

## Hardware and test constraints — owner confirmation 2026-11-21T04:54:03.882Z
- **Owner has no local Mac.** Do not repeatedly request a physical Mac or treat missing hands-on UI evaluation as a stop gate for implementing M1–M5.
- Use the hosted Apple-silicon macOS CI runner for automated build, unit, integration, synthetic-document, and feasible app-launch tests. Track their actual outcomes separately from hands-on acceptance.
- Real human UI, Finder interaction, VoiceOver, Gatekeeper first install, and Apple Foundation Models on-device operation remain **UNVERIFIED** until external Mac tester access.
- See [remote test strategy](REMOTE_TEST_STRATEGY.md). Aim for a simple signed/notarized tester-ready distribution, not terminal instructions or routine Gatekeeper bypass.

## Next executable steps
1. Expand M0 persistence/SQLite negative tests and feasible automated Mac launch smoke testing in GitHub Actions.
2. Begin M1 now: approved PDF intake, SHA-256 immutable copies, PDFKit/Vision OCR fallback, preview, checklists and export. CI verification is required for every significant slice.
3. When the core workflow is useful, prepare the first external Mac beta with signing/notarization or supported TestFlight distribution and a short feedback script; tester hardware and developer-account credentials will be needed then.
4. Keep CHANGELOG, STATUS and acceptance test status updated without conflating successful CI with human UI testing.

**Security/quality:** No real contracts or secrets in Git; all original PDF data must remain immutable. Cloud inference is opt-in only. Agent tool access is not implemented yet.
