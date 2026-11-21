# Sorrelgate — Append-only timestamped change log

Every substantive change gets an ISO-8601 timestamp with timezone, scope, tested results (or **not run**), limitations, and GitHub commit/PR. Keep newest entries first and update `docs/STATUS.md` in the same change.

## 2026-11-21T05:06:56.566Z — M1 automated test suite and native Mac build verified successful
- **CI:** [Run #5](https://github.com/Kajin-0/sorrelgate/actions/runs/44869071688) on `da8ca53d6b984d4eb59f404163866cdbecb71cd3` **SUCCESS**; Xcode 26.6, Swift 6.3.3, macOS 26 arm64.
- **Verification:** `swift test --parallel` exit 0, nine XCTest cases (five synthetic-PDF scenarios plus four transaction tests); `xcodegen` generation PASS; `xcodebuild` native Mac app BUILD SUCCEEDED; archive and artifact upload successful.
- **Artifact:** Unsigned development ZIP `Sorrelgate-macOS-unsigned-debug`, ID 14692309510, size 551,168 bytes, 7-day retention. NOT a one-click customer installer.
- **Coverage:** Byte-for-byte SHA256 preservation, PDFKit digital text extraction, duplicate/invalid input handling, ten synthetic PDFs, persisted per-transaction checklists and restricted links, copied exports verified by hash, SQLite persistence and input validation.
- **Not yet verified:** User-visible Mac launch and UI, Finder permissions, actual scanned-document OCR accuracy, cancellation/retry failure cases, 50-PDF batch performance, Apple Intelligence and signing/notarization. The owner has no Mac.
- **Next:** M1 robustness fixes and M2 office-checklist configuration. No costs or Mac required until first tester beta.
- **Commit:** Verifies preceding M1 code fix commit; this is a documentation update.

## 2026-11-21T05:03:40.139Z — Repair M1 Swift parsing failure from first CI attempt
- **Failure evidence:** [CI run #4](https://github.com/Kajin-0/sorrelgate/actions/runs/44868984731) failed at Swift package compilation with extraneous closing brace in `DocumentSQLiteStore.insertDocument` around line 493; related missing-member errors were parser cascade.
- **Change:** Removed precisely one extra closing brace; no change to intended SQL transaction semantics.
- **Tests:** New run triggered by this commit. No success claim until observed.
- **Next:** Review CI compiler/test output; repair any remaining problems before proceeding.
- **Commit:** See accompanying fix commit.

## 2026-11-21T05:02:40.473Z — Implement M1 PDF/preview/checklist/export slice, CI pending
- **Changes:** Added DocumentWorkspace actor (PDFKit + Vision OCR, SHA-256, immutable copies, SQLite-backed document/page/checklist, cross-transaction link constraints, verified package export), SwiftUI import/preview/checklist/export interface and five synthetic-PDF XCTest scenarios.
- **Defect discovered:** CI [run #3](https://github.com/Kajin-0/sorrelgate/actions/runs/44868312124) FAILED: exact Date equality after SQLite REAL round-trip in testCreateAndListTransactions. Corrected test to compare stable fields and timestamp with 1 ms tolerance, preserving real persisted time precision rather than weakening production behavior.
- **Tests at submission:** New M1 code **NOT YET RUN**; a new GitHub Actions run will be triggered by this commit. No macOS owner device.
- **Safety:** Sources immutable, imports user-authorized, no secrets or copyrighted blank forms, no cloud transport; failed OCR leaves unavailable state.
- **Limitations:** Document classification, office presets, bulk folder import, detailed source provenance, AI agent, code signing/notarization and human UI tests remain pending. Do not claim paid release.
- **Next:** Read CI run, fix compilation/tests, update verified evidence and continue incremental M1 hardening.
- **Commit:** See accompanying M1 implementation commit.

## 2026-11-21T04:54:03.882Z — Confirmed no owner Mac; revised CI-first delivery and external beta gates
- **User constraint:** No Mac accessible to project owner. Do not pause coding until external Mac tester receives a usable build.
- **Policy changes:** Mac CI remains mandatory for compilation and automated tests. Human UI/installer/Apple Intelligence runtime testing is deferred and remains unverified. First external tester path prioritizes a simple signed/notarized installer (or an eligible TestFlight route).
- **Documents:** Updated AGENTS.md, README, docs/STATUS.md, docs/DECISIONS.md (ADR-009), docs/PROJECT_ROADMAP.md, docs/IMPLEMENTATION_CHECKLIST.md; added docs/REMOTE_TEST_STRATEGY.md.
- **Tests:** Documentation-only changes; no new native app code or CI builds performed for this entry.
- **Next:** Expand automated M0 negative tests and proceed to M1 PDF ingestion without waiting for local hardware.
- **Commit:** Recorded in corresponding GitHub documentation commit.

## 2026-11-21T04:39:17.086Z — First verified Apple-silicon build and four XCTest executions
- **Verification:** [Actions run #1](https://github.com/Kajin-0/sorrelgate/actions/runs/44866969670) completed SUCCESS on commit 36a0639b949dc8017ab428e063f31d38dd4cae94.
- **Environment:** macos-26-arm64, Xcode 26.6, Swift 6.3.3, developer-only XcodeGen 2.46.0.
- **Tests:** \`swift test --parallel\` returned zero exit code; test runner invoked four XCTest methods (create/list, reopen durability, blank-address rejection, SQL string safety). Note: Swift Testing's separate "0 tests" message does not count XCTest cases.
- **Build:** Generated project; \`xcodebuild ... CODE_SIGNING_ALLOWED=NO build\` returned BUILD SUCCEEDED; uploaded 216,314-byte unsigned Mac artifact (ID 14692755902, expires 2026-11-28).
- **Limitations:** Physical Mac UI launch, accessibility, signed/notarized distribution, PDF OCR, and AI tool execution remain untested/unimplemented; no release claim.
- **Next:** M0 Mac smoke test + failure paths; then M1 PDF vertical slice.
- **Documentation update:** STATUS, README, AGENTS, checklist, issue #1.

## 2026-11-21T04:36:43.885Z — Begin M0: native SwiftUI, SQLite persistence, macOS Actions CI
- **Scope:** Establish a true native Mac app, independent SorrelgateCore typed actions, SQLite persistence, restart/validation tests, XcodeGen project specification and macos-26 GitHub Actions workflow.
- **Changed files:** Package.swift, project.yml, SorrelgateApp/, Sources/SorrelgateCore/, Tests/SorrelgateCoreTests/, .github/workflows/macos-ci.yml, .gitignore, README, STATUS, AGENTS, DECISIONS and checklist.
- **Tests at commit creation:** NOT RUN in this chat environment; GitHub CI is triggered by push and must be inspected before declaring a build success.
- **Security:** No real documents or credentials. Only synthetic test strings. App produces no outgoing messages.
- **Next executable step:** Inspect first Actions run, resolve actual compile/test errors, then perform Mac usability verification and finish M0.
- **Commit:** See commit on main adding native M0 scaffold.

## 2026-11-20T23:19:47-05:00 — Public repository approved and agent handoff corrected
- **Reason:** Owner explicitly stated public GitHub visibility is acceptable; priority is useful software and steady sales.
- **Changes:** Removed private-repository stop gate from AGENTS.md, README, current status, Codex instructions, licensing notes, and implementation checklist; added ADR-007 superseding ADR-005; corrected malformed STATUS header; deprecated GitHub issue #8.
- **Verified:** GitHub main contained 20 documented files including AGENTS, product specification, change log, current status, and workflows; milestone issues #1–#7 exist.
- **Tests:** Documentation consistency and repository presence review; **native Mac build, OCR and AI execution NOT RUN**.
- **Security constraint:** Public repository does not permit public client contracts, credentials, licensed blank forms, private office material or signing keys.
- **Next:** Codex begins M0 on authorized Mac; no visibility requirement.

## 2026-11-21T04:11:41.409Z — Verified GitHub bootstrap and opened milestone issues
- **Scope:** Opened GitHub issues #1–#7 (M0–M6) and #8 (make repository private before adding proprietary source); updated README and current status with links.
- **Verification:** Confirmed 20 repository files, exact required handoff paths, 21 starter tasks in JSON, and GitHub main branch writes. Reviewed AGENTS.md and STATUS.md remotely.
- **Not run:** Native Mac build, OCR processing, agent execution and customer pilot. These remain NOT STARTED.
- **Outstanding blocker:** Repository is still public; owner must switch it to private before source development.
- **Commit:** See latest documentation commit on main.

## 2026-11-20T23:08:11-05:00 — Initialize Sorrelgate specification and agent handoff
- **Scope:** Rename the product Sorrelgate and establish the selected GitHub repository as its context and documentation source.
- **Work:** Root README / AGENTS, comprehensive product specification, Codex instructions, milestone checklist, two California seller-side office-editable workflows, current-status tracker, architectural decisions, security, tests and release policy.
- **Verified:** GitHub repo was public and empty with authenticated push/admin access; JSON workflow parsed; source docs available.
- **Not tested:** No Mac app, Xcode build, OCR benchmark, PDF processing, LLM action, signed installer or pilot.
- **Risk:** Repo must be changed to private before adding proprietary code.
- **Reference:** Initial GitHub documentation commits.

### Template
```text
## YYYY-MM-DDTHH:MM:SS±HH:MM — summary
- Scope / reason:
- Changed code / documents:
- Tests (machine, command, exit status, measured outcome; or NOT RUN):
- Limitations / blockers:
- Commit / PR:
- Next executable step:
```
