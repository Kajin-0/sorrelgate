# Sorrelgate — Current verified state

**Last verified:** 2026-11-21T05:06:56.566Z (UTC)
**Repository:** https://github.com/Kajin-0/sorrelgate (public by owner choice)
**Phase:** M1 backend and SwiftUI code now built in macOS CI; still NOT a tested customer release.
**Owner hardware:** NO Mac. Human UI and model testing deferred to the first external Mac tester.
**Expenses:** GitHub public-repository hosted CI and Apple SDK components used so far; no paid runtime APIs or Apple Developer membership.

## Latest full verification: PASS
- [GitHub Actions run #5](https://github.com/Kajin-0/sorrelgate/actions/runs/44869071688) completed **SUCCESS**, commit `da8ca53d6b984d4eb59f404163866cdbecb71cd3`.
- Runner: Apple Silicon macOS 26; Xcode 26.6, Swift 6.3.3; XcodeGen 2.46.0 developer-only.
- `swift test --parallel`: **9 XCTest cases executed**, exit 0. The five new PDF suite cases cover synthetic PDF original-byte SHA-256 integrity/digital-text extraction, duplicate detection, invalid PDF rejection, persisted checklist and cross-transaction link restrictions, ten distinct PDFs in a batch, and verified export copies/manifest. Existing four tests cover transaction persistence and SQL injection/empty input handling.
- NOTE: Swift Testing may separately show a `0 tests in 0 suites` summary, distinct from the 9 XCTest case invocations. CI step exit 0.
- Native Xcode project generation: pass; native SwiftUI `.app` `xcodebuild`: **BUILD SUCCEEDED**.
- Archive packaging and Actions artifact upload: pass. `Sorrelgate-macOS-unsigned-debug`, artifact ID 14692309510, size 551,168 bytes; access via the linked workflow run (artifact retention 7 days). **Unsigned developer ZIP is not a normal nontechnical Mac installer.**
- Earlier [run #3](https://github.com/Kajin-0/sorrelgate/actions/runs/44868312124) exposed a Date precision test assertion, fixed by tolerance; [run #4](https://github.com/Kajin-0/sorrelgate/actions/runs/44868984731) exposed one extraneous Swift brace, now fixed. The latest verification is green.

## Implemented
- SwiftUI desktop shell with transaction create/list, selecting a transaction, Finder-approved multi-PDF import, progress/cancel control, PDF viewer, checklist creation/completion/document linking, export destination picker and basic status messages.
- Typed `SorrelgateCore` local SQLite transactions and `DocumentWorkspace` actor with separate SQLite metadata: original PDF copies stored under transaction UUID + SHA256 name, per-page PDFKit text or Vision OCR fallback (OCR failures remain unavailable), duplicate detection, immutable source, verified hash-on-export, JSON manifest and readable checklist.
- All core functionality is local, with no cloud inference, secrets, or real customer documents in the repo.

## Milestones and limitations
| Milestone | State | Actual evidence / missing tests |
|---|---|---|
| M0 native app + transactions + CI | CI PASS, human verification pending | native build and persistence unit tests pass; interactive launch not yet tested |
| M1 PDF/checklist/export | Core CI PASS, still IN PROGRESS | tests pass; physical UI, Finder security scope, cancellation/resume, folder intake, large-batch & OCR accuracy still need evidence |
| M2 office presets and XLSX | NOT STARTED | starter JSON documented but not loaded into app |
| M3 document recognition/validation | NOT STARTED | no classifier or measured accuracy |
| M4 timelines and draft communications | NOT STARTED | no code |
| M5 controlled LLM operation | NOT STARTED | typed service foundation exists, model not connected |
| M6 consumer distribution | NOT STARTED | no signed/notarized installer, pilot or Apple developer membership |

## Next action — do not wait for a Mac
1. Harden M1: non-blocking refresh/select behavior, import cancellation and integrity tests, corrupted/zero-page PDFs, OCR synthetic scan test, transaction data recovery, efficient large batches. Keep running macOS Actions on each code change.
2. M2: load configurable office-specific seller-side starter checklists from versioned bundled resources, allow editing/reordering and Excel import.
3. Continue M3–M5 in modular, testable increments. Physical user feedback begins with the first **signed/notarized** external Mac beta, not with an unsigned developer archive.
4. After substantive work, update this file, CHANGELOG and DECISIONS if necessary. Do not classify a successful CI compilation as verified human usability.

**Public repository privacy:** Never commit client contracts, private office materials, PII, signed forms, credentials, Apple signing material, licensed blank forms or API keys. External messaging and legally consequential decisions stay human-controlled.
