# Sorrelgate — Append-only timestamped change log

## 2026-11-21T15:03:27.041Z — PR #18 G1 first source-linked human review source CI verified; merge pending
- [macOS Actions #101](https://github.com/Kajin-0/sorrelgate/actions/runs/44916706166) and [#102](https://github.com/Kajin-0/sorrelgate/actions/runs/44916709858) **both SUCCESS** on feature code `ade611dd71eda55d013b984a5284a24b45f9d1ce`: **54/54 XCTest** (51 prior + 3 new) and native SwiftUI app build, with unsigned artifact packaging/upload success.
- Three real PDFKit/SQLite tests: exact acceptance-date on second page of a three-page synthetic PDF bound to source SHA/document/transaction and actual PDFKit page text; two-transaction scope denial for discovery/review/source and independence across reopen; explicit Confirm/Reject/Unknown persists and rediscovery preserves decision; prose/TBD/impossible calendar dates produce **zero guessed candidates**; deliberate archived-original byte corruption blocks source navigation and any confirmation.
- Domain persists a separate proposed-vs-human-decided state and the original citation, with transaction scope and SQLite document/page foreign keys. Native page navigation is implemented and compiled, but **human UI behavior not independently tested**. This is the first G1 **engineering slice only**; no held-out document-type classifier/field precision, actual field scans, model call or legal validation.
- No new dependency/spending. PR #18 merge pending at log time.


## 2026-11-21T14:58:16.158Z — G1 first source-backed field proposal → human review → reopen (CI PENDING)
- **Gate:** [Delivery Contract](DELIVERY_CONTRACT.md) G1; single complete vertical slice on branch `feature/g1-evidence-review-vertical-slice-20261121` (target **54 XCTest** from 51 baseline). **Not tested on macOS yet; merge only green.**
- **Domain / SQLite:** Added `FieldProposal` with source document SHA-256, transaction ID, document ID, zero-based page index, exact supporting extracted line, fixed acceptance-date kind and `proposed/confirmed/rejected/unknown` states. Additive SQLite table, unique proposal identity and foreign-key page ownership; re-discovery preserves human decisions, cross-transaction review/open is denied. Rehash original PDF before discovery, review or source navigation.
- **Extraction:** Only fully explicit `Acceptance Date: YYYY-MM-DD` line, validated Gregorian calendar date, from existing PDFKit/Vision text. Missing, free-form or impossible dates **abstain**. No model, legal-deadline calculation, automatic verified state, or general recognition claim.
- **macOS UI:** Manual `Find in Selected PDF`, evidence snippet, source PDF filename + human page number, actual PDFKit page jump, explicit user review menu and durable UI refresh; no speculative view architecture.
- **Tests:** Three new real synthetic PDFKit/SQLite tests verify multipage source and immutable bytes/hash, two-transaction isolation, idempotent confirmed status, persisted Unknown/Rejected/reopen, abstention on invalid dates and corrupted-source refusal. Native build and test still **PENDING**.
- **Limits:** G1 held-out field accuracy/coverage and full workflow remain open; no authorized real estate document corpus, human Mac tester, storage recovery/agent action testing. No new dependency or cost.


## 2026-11-21T14:29:48.465Z — Outcome-gated product contract; stop synthetic microhardening churn
- **Scope:** New [docs/DELIVERY_CONTRACT.md](DELIVERY_CONTRACT.md) defines one Accepted Offer north-star workflow and five measurable gates: G1 evidence-backed review, G2 human-reviewed deliverables, G3 recovery/security, G4 permissioned agent, G5 external Mac pilot/commercial release.
- **Current evidence:** [main Actions #97](https://github.com/Kajin-0/sorrelgate/actions/runs/44910712360) success at `704e39c93947261305145dd5f944833df2c4a78a`: 51 XCTest/native SwiftUI build. This change is **planning/documentation only**; it makes **no new product capability claims** and has **no new runtime tests**.
- **Decision:** Freeze M1 synthetic OCR/IO edge-case additions unless a measured gate fails or P0/P1 occurs. Prioritize G1 smallest complete PDF source-link/user confirmation/persistent reopen slice, then end-to-end accepted-offer outputs before AI.
- **Stop policy:** one active gate, one complete vertical outcome per PR, two non-advancing PRs force diagnosis rather than a third speculative change; all gates report PASS/FAIL/BLOCKED. When CI engineering exits pass but external Mac/user data unavailable, stop feature work and request the external pilot. Commercial release is NO-GO until actual human/installer evidence and explicit spending approval.
- **No architecture or runtime changes; no new dependencies; no cost.**


## 2026-11-21T13:48:25.927Z — PR #16 degraded multipage OCR + filesystem integrity merged into main
- **Merge:** [PR #16](https://github.com/Kajin-0/sorrelgate/pull/16) squash-merged `d896b47efd5c732c776f76bc331a0ca6d1cab934`. Post-merge CI pending at this entry; source [#92](https://github.com/Kajin-0/sorrelgate/actions/runs/44909992770), [#93](https://github.com/Kajin-0/sorrelgate/actions/runs/44909997219) and docs-head [#95](https://github.com/Kajin-0/sorrelgate/actions/runs/44910402256) all **SUCCESS: 51/51 XCTest, native SwiftUI build, unsigned artifact**.
- **Proven scope:** image-only 5-page PDF baseline/skew/low-contrast/Gaussian blur 7/7 synthetic tokens on each of four content pages, blank page refused OCR; staged 256 KiB in a POSIX FIFO before active-read cancellation; source/destination chmod denial, verified zero records/leftovers and successful retry; previously imported missing/corrupt original never called duplicate; disk-write failure identified as storage.
- **Repeated CI 50-PDF timings:** #92 10.373 s (4.820/s), #93 8.113 s (6.163/s), final docs-head #95 9.035 s (5.534/s), on hosted Mac; this spread demonstrates timing variability rather than a controlled regression. Do not extrapolate to client scans.
- **Limits:** true macOS ENOSPC, actual Finder security-scoped URL revocation, process kill, unpredictable field OCR and first human Mac pilot remain open. $0 additional spend. Commercial NO-GO.


## 2026-11-21T13:44:21.185Z — PR #16 degraded OCR + blocked FIFO cancellation source CI PASS; merge pending
- **Verification:** [macOS Actions #92](https://github.com/Kajin-0/sorrelgate/actions/runs/44909992770) and [#93](https://github.com/Kajin-0/sorrelgate/actions/runs/44909997219), both SUCCESS at source `524506ce7c7cf8374cf443517d7026668581f630`. **51/51 XCTest** (46 baseline + 5), native SwiftUI `xcodebuild` SUCCESS, unsigned artifact uploaded; suite includes real FIFO cancellation with 256 KiB staged, POSIX read/write permission denial and recovery, and duplicate SHA rehash under deliberate corruption/deletion.
- **Vision metrics:** Five **image-only** PDF pages including one blank. Synthetic seven-token word recall = **1.000** for baseline, 4° skew, 0.48 gray low-contrast text and Gaussian blur radius 2.2px. Blank abstained (`unavailable`); page order, original PDF SHA-256/bytes and reopen confirmed. This is controlled legible text, **not** performance on authentic field-scanned real-estate documents.
- **50-PDF benchmark repeated:** [#92](https://github.com/Kajin-0/sorrelgate/actions/runs/44909992770) **10.373 s, 4.820 files/s, p50 0.003 s, p95 1.881 s**; [#93](https://github.com/Kajin-0/sorrelgate/actions/runs/44909997219) **8.113 s, 6.163 files/s, p50 0.003 s, p95 1.463 s**, on hosted macOS 26, 46 digital+4 raster one-page PDFs; earlier #83 6.043 s, showing runner contention/variance. No controlled throughput regression conclusion.
- **Fix trail:** Initial macOS CI #88/#89 hit unavailable blocking semaphore in an async XCTest; replaced by actor release gate `5148cc1`. CI #90/#91 then showed 4 KiB pipe data had not populated staged file because `FileHandle.read(upToCount:)` could await a complete 256 KiB chunk; fixture now feeds full 256 KiB before holding FIFO open. Both #92/#93 PASS without weakening the staged-byte assertion.
- **Scope:** PR #16 not yet merged at entry; no client files, cloud services, paid runtime libraries, or architecture redesign. True ENOSPC, sandbox bookmarks, real scan generalization and physical Mac UX remain NO-GO.


## 2026-11-21T13:35:07.774Z — M1 degraded multipage Vision OCR and real I/O fault tests (CI PENDING)
- **Branch:** `feature/m1-degraded-ocr-io-faults-20261121` based on green `main` `d1dc1375`, [Actions #86](https://github.com/Kajin-0/sorrelgate/actions/runs/44881602182) PASS 46 XCTest/native macOS app.
- **Production:** Existing-document duplicate path now rehashes the actual saved original; missing/corrupted originals throw `corruptedOriginal` rather than claiming duplicate success. Failure to create staged PDF due to disk/permissions yields dedicated `DocumentProcessingError.storage` instead of falsely declaring an invalid PDF. No schema, dependency, cloud, or UI changes.
- **Synthetic macOS XCTest additions (NOT YET RUN):** (1) Five image-only PDF pages: baseline, 4° rotated text, gray/low-contrast text, CoreImage Gaussian-blurred text (radius 2.2), fully blank page. Require actual PDFKit/Vision per-page text method and 7-token recall per page with blank abstention; persist page index and source hash across reopen. (2) POSIX FIFO source writer holds read open after delivering 4096 bytes; test observes staged bytes, cancels active import, releases writer, confirms CancellationError and no persisted original/task. (3) Import previously stored PDF after deliberately corrupting then deleting the archived original: reject duplicate until original bytes restored. (4) chmod-protected destination denies temporary write: clear storage error, zero metadata and retry after restoring permissions. (5) chmod-protected input denies read, leaves source/DB intact, then retries.
- **CI:** Target 51 XCTest (46 old + five new), actual Vision degradation metrics emitted as `M1_MULTIPAGE_OCR_CI` and required in hosted macOS workflow. **Pending; do not claim measured outcomes until successful job logs.**
- **Still open:** True filesystem ENOSPC, Finder security-scoped bookmark expiry/revocation, process kill during copy, difficult actual TC documents, handwriting/OCR confidence calibration, human Mac UI. No additional spending.


## 2026-11-21T07:43:48.888Z — M1 raster Vision and 50-PDF reliability PR #15 merged; quantified macOS CI
- **Merge:** [PR #15](https://github.com/Kajin-0/sorrelgate/pull/15) squash-merged as `e8828a87b6d4d752a473a1ad0bdd2eadb970be8c` after [Actions #79](https://github.com/Kajin-0/sorrelgate/actions/runs/44881078287), [#80](https://github.com/Kajin-0/sorrelgate/actions/runs/44881082647) and metrics-enabled [#83](https://github.com/Kajin-0/sorrelgate/actions/runs/44881324257) success.
- **Tests/build:** Each successful run executes **46/46 XCTest** (39 prior + 7 new). Native XcodeGen/SwiftUI unsigned build and artifact upload PASS. #83 requires and prints OCR/batch metrics from RUNNER_TEMP (parallel XCTest stdout is otherwise suppressed).
- **Measured metrics (macos-26 GitHub runner; clean 1-page synthetic PDFs):** true image-only Apple Vision OCR **7/7 selected English terms = 1.000 recall**, numeric ID checked; mixed **50 PDFs = 46 selectable text + 4 raster** finished **6.043 s** (from generation through import), **8.274 files/s**, import durations p50 **0.002 s**, p95 **1.039 s**. SHA-256 and byte-for-byte source/store equality for all 50, stored per-page extraction provenance, no .incoming files, document reopen/identity confirmed. P50/p95 include import calls only; 6.043 s includes fixture generation.
- **Cancellation/rollback:** Pre-cancel, partial eight-file cancellation/resume, blocked destination, forced SQLite insert abort and successful retry, wrong-hash collision rejection pass. Added cancellation checkpoints after PDF parse, Vision, chunk writes and before DB commit; stored originals unchanged.
- **Caveat:** No measured field-scan accuracy; synthetic 7-token recall does not characterize OCR WER across real legal forms. Real ENOSPC, Finder security scoped URL revocation, active mid-read interruption, multipage and human Mac UI remain open. New dependencies/spend: none. Post-merge main CI pending at this entry.


## 2026-11-21T07:36:41.448Z — M1 PDF/Vision OCR, cancellation and 50-PDF mixed stress tests (CI PENDING)
- **Scope:** `feature/m1-pdf-reliability-20261121` atop verified main `37b909a2` (Actions #77 SUCCESS, 39 XCTest/native app). M1 reliability only; no new dependencies, paid tools, client files, or UI redesign.
- **Production:** PDF import now checks Task cancellation after PDFKit open, immediately following Vision OCR, after each staged chunk write and sync, and immediately before document-side SQLite insert. If cancellation occurs after staging the final SHA-named file but before database insertion, the newly installed file is deleted in the existing catch rollback path; pre-existing matching originals remain protected.
- **Synthetic tests added, not yet run:** (1) real bitmap-only PDF (no text layer) sent through PDFKit rasterization and Apple Vision; measured token recall + numeric ID; (2) pre-cancelled import creates no rows and retries; (3) cancel/resume eight-file batch preserving three already committed records; (4) obstructed destination directory leaves source unchanged and recovers; (5) deterministic SQLite trigger abort demonstrates metadata transaction rollback and removal of newly moved original; (6) wrong-hash existing original is never overwritten; (7) mixed **50 unique one-page PDFs, 46 digital/4 raster** verify exact SHA-256 and byte copy for all, document OCR/digital provenance, no .incoming stages, 50 document reopen persistence, throughput and p50/p95 measured in macOS CI.
- **Testing gate:** CI **PENDING**. Expected 46 XCTest (39 prior + 7 new), native SwiftUI Mac build and unsigned artifact. Tests use only harmless generated data. Synthetic token recall/throughput should not be presented as accuracy on real TC documents or physical target machines.
- **Not covered:** Real low-disk ENOSPC, book-mark revocation, true mid-read interruption, poor camera scans, manual Mac UI/performance and notarized release. No benchmark claims until logs are captured.


## 2026-11-21T07:00:36.788Z — PR #14 crash-safe creation and restart replay merged, 39-test CI PASS
- **Merge:** [PR #14](https://github.com/Kajin-0/sorrelgate/pull/14) squash-merged to `main` as `4037eb86de729f80c27251ccb2cccaeeda5528a1`.
- **Evidence:** Feature-source macOS Actions [#72](https://github.com/Kajin-0/sorrelgate/actions/runs/44877714802) and [#73](https://github.com/Kajin-0/sorrelgate/actions/runs/44877718244), and docs-head [#74](https://github.com/Kajin-0/sorrelgate/actions/runs/44877944051) all **SUCCESS**: `swift test --parallel` invoked **39/39 XCTest cases**, XcodeGen native Mac application BUILD SUCCEEDED, unsigned artifact uploaded. This update is documentation only, so post-merge `main` CI remains pending at entry time.
- **Implemented:** Atomic transaction+frozen office checklist intent, two-step idempotent document-side task/provenance commit and acknowledgment, automatic launch retry, non-destructive conflict handling, a single async GUI Create action preventing repeated submissions, and six restart/rollback/snapshot tests.
- **Known limits:** Two SQLite files remain separate; legacy records without intents cannot reconstruct an originally selected office. Synthetic file-handle reopen tests are not a physical abrupt-process-kill or human Mac UX test. Commercial readiness remains NO-GO.
- **Next:** Post-merge main CI, then M1 Vision scanned OCR/cancellation/low disk and 50-PDF throughput.


## 2026-11-21T06:57:02.364Z — Crash-safe transaction initialization CI verified (PR #14; merge pending)
- **Verification:** [Actions #72](https://github.com/Kajin-0/sorrelgate/actions/runs/44877714802) and [#73](https://github.com/Kajin-0/sorrelgate/actions/runs/44877718244) both SUCCESS on `21078ef603f584d7fa82151f503faba222344aa9`. Each ran **39/39 XCTest cases** (33 baseline + 6 new), generated Xcode project, built native SwiftUI Mac app with signing disabled, and uploaded an unsigned artifact. No real macOS user GUI was exercised.
- **Repair trail:** Initial CI #68/#69 found a throwing-expression Swift compiler error in `OfficeTemplateStore`; fixed at `a8befc5`. CI #70/#71 then exposed `await` in XCTest assertion autoclosures; fixed at `21078ef`. The final source CI is green; no data-loss assertion failures were observed.
- **Covered interruption cases:** transaction commit before document-side checklist commit, document-side commit before intent ack, exact office revision frozen through later edits, user checklist conflict preserving tasks while other intents recover, legacy record with no intent not guessed, atomic creation rollback on duplicate, normal ready receipt and invalid-office preflight.
- **Scope:** PR #14 merge pending at entry time. Two SQLite databases still do not share an atomic transaction; durable intent/replay provides convergence. Filesystem fault injection, human Mac relaunch and commercial readiness not verified.


## 2026-11-21T06:50:55.923Z — Durable transaction checklist intents and restart replay (CI PENDING)
- **Scope:** Close the gap between the separately committed transaction record and asynchronous document-side checklist by using a persistent transaction creation intent with frozen exact office/version and task metadata. Avoid a storage-engine redesign or unsafe multi-database atomicity claims.
- **Implementation:** `ChecklistSeedPlan` is Codable and copied from the selected office/built-in starter BEFORE transaction insert; `SQLiteTransactionStore.insert(record,pendingChecklist:)` commits record+plan together in `transactions.sqlite` (new additive intent table, schema version 2). Document-side `OfficeTemplateStore.seedPreparedTransaction` atomically inserts tasks+source in `documents.sqlite`. `TransactionInitializationCoordinator` replays pending intents at launch, verifies source identity and acknowledges only after successful completion; preserves historical edits and refuses conflicts with manual tasks. SwiftUI Create now awaits the typed coordinator and blocks duplicate taps while saving; manual 'Load Starter' honors pending office intent first. No network/cloud or new dependencies.
- **Tests added (NOT YET RUN):** Six synthetic macOS XCTest scenarios: crash after transaction commit with office revision changed; crash after document commit before ack with user edits; manual conflict while continuing recovery of other records; normal creation and missing-office refusal; old transaction without intent not guessed; atomic insert duplicate rollback. Baseline 33 XCTest; target **39**.
- **Limitations:** Old records created before this patch without intents have no reliable original office context; no automatic attribution or checklist reconstruction. Separate SQLite files are not one atomic distributed transaction. Human Mac UI/relaunch, disk failure injection and multi-process/reentrant contention remain to be tested. M1/M3–M6 still incomplete, commercial release NO-GO.
- **Next:** Run macOS CI on `feature/m2-crash-safe-initialization-20261121`, repair failures, merge only after clean test/build gate.


## 2026-11-21T06:39:55.323Z — PR #13 spreadsheet metadata mapping merged after 33/33 Mac XCTest
- **Merge:** [PR #13](https://github.com/Kajin-0/sorrelgate/pull/13) squash-merged to `main` as `404ac3cd2cb19e52e4f8ed98b1b9076cdf9c39c6`.
- **Evidence:** [macOS Actions #63](https://github.com/Kajin-0/sorrelgate/actions/runs/44876286333) and [#64](https://github.com/Kajin-0/sorrelgate/actions/runs/44876289970) both **SUCCESS** on `fa666ed07a47a2555ebe107883d5ac40ee1fef2f`; `swift test --parallel` invoked all **33/33 XCTest methods** (27 baseline + 6 new), XcodeGen and full native SwiftUI Mac build PASS. Unsigned debug artifact #64 ID 14695893650 (2,862,259 bytes, expires 2026-11-28). CI verifies compiled app and synthetic workflows only.
- **Functional coverage:** Explicit selected CSV/XLSX task/requirement/notes mapping, strict row refusal, actual zipped XML/XLSX sparse data, and a tested office Save -> transaction snapshot chain with immutable history.
- **Remaining:** Post-merge main CI pending at this entry; multi-DB transaction creation recovery, M1 scanned OCR/cancel/disk failure paths, full real Mac UI, M3–M6 not verified. Release NO-GO.
- **Next:** Verify post-merge main build; repair transaction-creation interruption path before unrelated features.


## 2026-11-21T06:35:23.324Z — Explicit CSV/XLSX office requirement and notes review (CI PENDING)
- **Branch:** `feature/m2-spreadsheet-metadata-20261121` based on green main `fc36634`; scoped shared importer/UI extension, no new dependencies or paid services.
- **Core:** Add `CSVChecklistMapping(titleColumn,requirementColumn?,notesColumn?)` and `CSVChecklistReview.tasks` typed `OfficeTaskSpec`, preserving legacy `.titles` and title-only review API. Mappings must be distinct and in range. Optional fields are NEVER inferred. Requirement mappings accept Required, Optional, Unspecified, Yes/No, True/False or 1/0 (case insensitive); blank becomes Unspecified. Invalid tokens, >500-character notes, duplicate/invalid titles, row-width errors and preexisting XLSX formula issues prohibit import approval; preserve physical source line/row references. All issues shown rather than only first 50.
- **GUI:** Shared SwiftUI review explicitly selects title, optional office requirement and notes columns; previews each, displays row-level errors and blocks 'Use' on any issue. Use stages typed tasks in the unsaved office draft; user must separately Save to append a revision. XLSX still requires explicit worksheet selection.
- **New tests (NOT YET RUN):** 4 CSV tests (mixed quote/newline semantics/row numbers, invalid token+long note+duplicate negative controls, no-header-inference/duplicate mappings, reviewed task-to-office-save-to-immutable snapshot) and 2 actual zipped OOXML XLSX tests (multi-column metadata with sparse physical rows and unknown-value block). Baseline 27 XCTest; target 33 tests.
- **Known limitations:** Human Mac UI/real office file compatibility unverified; task status/due date, Excel fuzzing, interrupted transaction initialization, real scanned OCR and paid release remain pending. Never interpret office 'Required' as legal sufficiency.
- **Next:** Inspect exact Mac CI; repair, update STATUS with verified evidence, then merge only when green.


## 2026-11-21T05:59:37.188Z — M2 task requirement/notes PR #12 merged; main CI pending
- **Merge:** [PR #12](https://github.com/Kajin-0/sorrelgate/pull/12) squash-merged to `main` as `990f6094caa159e095aace8895fd70f0c06b9ed9` after successful feature CI [#56](https://github.com/Kajin-0/sorrelgate/actions/runs/44872995179) and documentation-head CI [#58](https://github.com/Kajin-0/sorrelgate/actions/runs/44873214162).
- **Evidence:** Both runs PASS 27/27 XCTest, XcodeGen project generation, native SwiftUI app build and unsigned artifact. This documentation-only follow-up does not claim completed post-merge main CI yet.
- **Remaining:** Rich spreadsheet column mapping, transaction initialization recovery, M1 OCR/failure tests, real Mac usability, notarization, and M3–M6. Release remains NO-GO.


## 2026-11-21T05:56:46.154Z — M2 office requirement/notes CI verified (source PR #12)
- **Evidence:** [macOS Actions #56](https://github.com/Kajin-0/sorrelgate/actions/runs/44872995179) SUCCESS on `f5820de053a87b9dc5c2a0bdfddf9dafc4c5c979` (feature branch). `swift test --parallel` executed **27/27 XCTest cases** (24 baseline + 3 new metadata/migration cases); XcodeGen and native SwiftUI app BUILD SUCCEEDED; unsigned test ZIP artifact 14693969678 uploaded (2,833,304 bytes; seven-day retention).
- **Coverage:** Real legacy SQLite schema upgraded in place without resetting existing task completion; historical requirement/notes snapshots survive office edits and reopen; metadata-only revision and invalid 501-character note rejection verified. Tests do not substitute for real user Mac GUI.
- **Deployment:** PR #12 remains draft/merge-pending at entry time. No signing/notarization, outside-Mac usability, live office documents, or document OCR performance verified. No new paid services.
- **Next:** Merge only after latest docs commit CI; continue explicit CSV/XLSX metadata mappings and M1 reliability.


## 2026-11-21T05:53:40.145Z — M2 office requirement and notes: implementation and migration tests (CI PENDING)
- **Scope:** Add an explicit office requirement value (unspecified / office required / office optional) and optional notes to versioned office tasks. Copy both fields into immutable transaction checklist rows; expose in native Office Checklists editor. Avoid interpreting unlabeled historical checklists as legally required.
- **Schema migration:** Existing `office_template_rows` and `checklist_tasks` receive additive idempotent columns with `unspecified` and empty-note defaults. No destructive rewrite and no new dependency. User-edited historical completion/document links are preserved.
- **Compatibility:** Legacy title-only save still supported and preserves metadata for matched existing titles. CSV/XLSX title-only imports remain available but new metadata-column mappings are a separate scope.
- **Tests added:** Three macOS XCTest scenarios: historical snapshot immutability across revision/restart, metadata-only version changes plus invalid-note refusal, and migration from real pre-metadata SQLite schemas.
- **Verification:** New code/test/native app CI PENDING. Prior merged baseline `e6b6291` completed macOS Actions #54 successfully. No real Mac GUI or migration on real customer data tested.
- **Next:** Repair and verify CI; merge only when clean. Expand spreadsheet mapping and M1 robustness without architectural churn.


## 2026-11-21T05:47:04.155Z — XLSX feature passes 24 XCTest and native Mac build (CI #50)
- **Evidence:** [macOS Actions run #50](https://github.com/Kajin-0/sorrelgate/actions/runs/44872179791) **SUCCESS** for source commit `33686e2b2bb321d92f2238bec3e89adbc18d3ee8`. `swift test --parallel` invoked **24 XCTest cases** (20 previous + 4 new real ZIP/XML XLSX tests); XcodeGen project and native SwiftUI app BUILD SUCCEEDED; unsigned ZIP artifact uploaded. Code-signing and physical UI not tested.
- **Implementation:** Multi-sheet Excel XLSX parser with shared+inline strings, sparse rows, formula/error refusal, ZIP archive declared-size safeguards; native XLSX file/sheet picker, explicit task-title column review and unsaved office checklist draft. Workbook parsing moved to detached user-initiated task to avoid blocking SwiftUI.
- **Resolved dependency evidence (GitHub Actions logs):** CoreXLSX 0.14.2 (Apache-2.0), XMLCoder 0.14.0 (MIT), ZIPFoundation 0.9.20 (MIT). Full notices/SBOM, threat-model evaluation and locked package revisions remain release requirements.
- **Failure repair:** First XLSX runs #38–#45 failed from SwiftPM argument ordering; corrected and reran tests/GUI. Runs #46, #47 and #50 passed. No feature change was merged on failed evidence.
- **Remaining:** M2 rich task fields and mapping, M1 scanned OCR/negative path testing, on-device Mac UX and notarization; release NO-GO.
- **Next:** Complete office task metadata/migration and harden import/document reliability with measurable macOS CI.

## 2026-11-21T05:42:06.767Z — XLSX import and worksheet review implementation submitted (CI PENDING)
- **Branch/PR:** `feature/m2-xlsx-import-20261121`, [PR #11](https://github.com/Kajin-0/sorrelgate/pull/11), from main `2cca715` (20-case CSV baseline).
- **Core:** Add pinned CoreXLSX 0.14.2 (Apache-2.0) with ZIPFoundation + transitive XMLCoder (MIT). Inspect ZIP entries (2 MiB input, 24 MiB declared expansion, 200 members), cap 20 worksheets / 2,000 data rows / 64 columns, reject formula/error cells and invalid shared strings. Parse sparse cell references and preserve Excel row numbers. Shared CSV mapping/review blocks acceptance on errors.
- **UI:** Native XLSX picker, named worksheet selection, existing explicit task-title column mapping, review and separate manual Save for office template revision; historical transactions remain untouched.
- **Tests:** Four new XCTest cases with real synthetic multi-sheet zipped OOXML workbook (shared/inline text, sparse rows, formula rejection, invalid/oversize), **CI PENDING**. Initial SwiftPM manifest argument-order error corrected; not yet evidence of XLSX parsing success.
- **Unverified:** actual end-user Mac GUI, compressed-to-expanded archive adversarial fuzzing, richer field mappings, app signing/notarization. No paid services used.
- **Next:** Mac CI gate and fixes; retain draft PR until green.

## 2026-11-21T05:36:33.235Z — CSV import and native UI verified (20/20 XCTest in macOS Actions #33)
- **Verified:** [Actions #33](https://github.com/Kajin-0/sorrelgate/actions/runs/44871510490) completed SUCCESS on code commit `445949d54d26b4e02e30d83794649edd09ff7b8f`; macOS 26 Apple Silicon, Swift 6.3.3, Xcode 26.6. `swift test --parallel` invoked **20/20 XCTest** (16 previous, 4 new CSV); native XcodeGen/SwiftUI app BUILD SUCCEEDED and unsigned artifact uploaded.
- **Failure/fix:** Earlier run #31 failed on Windows CRLF test fixtures because Swift Character groups CRLF into a grapheme cluster; switched tokenizer to Unicode scalars, then passed all CSV fixtures and app build in #33.
- **Scope:** PR #10 staged native CSV file selection, explicit title column mapping and review of all invalid/duplicate rows; accepted tasks are copied only into unsaved office revision draft. No automatic office save or historical transaction change.
- **Limits:** No physical Mac usability test, XLSX support, task status/required/notes column mapping, or office migration UX; M2 incomplete. Continue $0 budget.
- **Next:** XLSX import with review/mapping, then M1 robustness gates.


## 2026-11-21T05:32:20.683Z — M2 CSV parser, column review and native import interface (CI PENDING)
- **Branch:** `feature/m2-csv-import-20261121`, scoped extension following merged office-profile PR #9 (`8c127df`).
- **Core:** UTF-8 CSV parser with BOM support, quoted commas/embedded newlines, escape handling, 2 MiB/2,000 row/64 column limits and non-silent errors; explicit mapped title column, full invalid/duplicate row review, no silent partial import.
- **GUI:** User-selected local CSV picker with security-scoped grant, read-only preview, mapped-column choice, blocking invalid rows; approved titles copied into unsaved office template draft. Saving still requires explicit action and creates a versioned revision; existing transactions unaffected.
- **Tests:** Four synthetic CSV XCTest cases added (quotes/BOM, multiline, duplicate/mismatch, oversize/malformed/encoding). **NOT RUN at commit creation**; macOS SwiftUI compilation/CI must be inspected.
- **Next:** Fix CI if needed, close CSV gate, then XLSX import. No additional paid runtime service.


## 2026-11-21T05:30:27.176Z — M2 office profiles and snapshot CI verified
- **Evidence:** [macOS Actions #14](https://github.com/Kajin-0/sorrelgate/actions/runs/44870973186) SUCCESS for source commit `eb106533ca49bf106c84e70772b8f44cf11d13e1` on macOS 26.7.2 Apple Silicon, Xcode 26.6, Swift 6.3.3.
- **Tests:** `swift test --parallel` ran **16/16 XCTest cases** successfully (11 prior + 5 new), separate Swift Testing harness has 0 native Swift Testing cases. XcodeGen generated project; native SwiftUI app `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` PASS; artifact uploaded. No actual Mac GUI test.
- **Scope:** PR #9 draft; named independent offices, append-only seller checklists and transaction-bound source revisions, task editor and office selector are compiled and backend-tested.
- **Remaining:** CSV/XLSX importer, richer task requirements/states, migration UX and real-user Mac interaction; $0 additional cost maintained.
- **Next:** CSV with column mapping and preview, then XLSX; continue scoped Mac CI and release NO-GO.


## 2026-11-21T05:27:44.886Z — M2 office profile/template slice submitted; CI verification pending
- **Branch:** `feature/m2-office-profiles-20261121` (do not merge until macOS Swift/Xcode CI green).
- **Core:** New OfficeTemplateStore in the existing document SQLite file: case-insensitively unique named offices, independent listing/accepted-offer workflow versions, immutable revision rows, optimistic edit conflicts, atomic per-transaction task snapshot/provenance, legacy/manual checklist no-overwrite.
- **GUI:** New Office Settings sheet with task editing and ordering; new-transaction office selector; workspace displays source revision.
- **Tests added:** Five synthetic XCTest cases covering office isolation, snapshot versioning/reopen, manual task preservation, duplicate/stale/invalid rejection, starter provenance and editing durability.
- **Tests:** NOT RUN for this new feature at documentation time; GitHub Actions must be inspected before claiming success.
- **Next:** Repair any compilation/test failures, verify native build, then CSV column-mapping and importer.


Every substantive change gets an ISO-8601 timestamp with timezone, scope, tested results (or **not run**), limitations, and GitHub commit/PR. Keep newest entries first and update `docs/STATUS.md` in the same change.

## 2026-11-21T05:18:08.321Z — 11 Mac tests green; versioned seller checklists and edit UI verified
- **GitHub Actions:** [#7](https://github.com/Kajin-0/sorrelgate/actions/runs/44870027594) completed SUCCESS for commit `5b419be1f9a7bce6a0402c069f55463930a52c13`, Apple Silicon macOS 26 / Xcode 26.6 / Swift 6.3.3.
- **Tests:** All 11 XCTest cases invoked successfully. New tests validate 9 listing + 12 accepted-offer tasks, idempotent seeding, restart persistence and scoped task edits; older M0/M1 tests also pass.
- **Build:** SwiftUI native app BUILT successfully; unsigned debug artifact 690,515 bytes, ID 14693785979, 7-day retention. No real Mac GUI test.
- **Policy:** Owner explicitly requires $0 additional expenses through initial MVP and allows future Codex-assisted local Xcode build on actual tester Mac. No Apple developer membership, notarization, hosting or paid LLM API required now.
- **Remaining:** Saved named office profiles, XLSX/CSV import, OCR performance on real scans, UI polish and AI-controlled app actions.
- **Next:** Implement M2 office-specific templates and CSV import with CI gating; preserve existing transaction checklist snapshots.

## 2026-11-21T05:15:20.571Z — Wire seller starter tasks into Mac interface and document free pilot installation
- **UI:** Automatically initialize an editable snapshot on new transaction; Load Starter Tasks for older empty transactions; task edit sheet provides rename/confirmed removal and preserves PDFs; keep selected PDF preview on checklist updates.
- **Tester plan:** FREE_MAC_TESTER_HANDOFF.md gives Codex instructions for a supervised zero-cost local Xcode build and test on the user's Mac; paid Apple notarization deferred.
- **Verification:** Source changes submitted; latest Mac CI run must be inspected before claiming new GUI compiles. Physical UI has not been tested.
- **Next:** Resolve CI, then build office profiles/template management with Excel import.

## 2026-11-21T05:14:07.576Z — Add bundled versioned starter checklist domain actions; $0 assisted pilot policy
- **Added:** 9 listing and 12 accepted-offer administrative starter tasks loaded from JSON via Swift Package resources; atomic idempotent SQL seed, scoped task rename/remove, and two XCTest suites covering counts, no overwrite, restart persistence and cross-transaction denial.
- **Budget:** Apple paid enrollment/signing/notarization deferred. Free Codex-assisted local Xcode build approved for the first external Mac pilot.
- **Verification:** Prior M1 CI run #5 passed; **new changes not yet tested**, trigger Actions on commit.
- **Next:** Verify CI, connect starter UI, then office-specific editable profiles and Excel/CSV importer.
- **Commit:** Source commit associated with this entry.

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
