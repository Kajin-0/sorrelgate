# UI audit triage — 2026-11-21

**Source:** Owner-supplied independent static SwiftUI review. Assessed against GitHub `main` at `2bcdbca1f4a78653b5e2b0b6d4cb46cdd03bcb03`. This is a **source-level audit**; no physical Mac interaction, VoiceOver, visual screenshot, Finder/sandbox behavior, or half-screen tiling has been demonstrated.

**Decision:** One narrow **P1 correctness/usability exception** to the [Delivery Contract](DELIVERY_CONTRACT.md), expiring at close of this pull request. Keep **G1** the active product gate, stop at the defect remediation verified by macOS CI. Do not interpret the imported auditor's larger PR B/C prompt as automatic authorization for broad UI redesign. All code changes are UI/view-model except one additive pure import-report composition type and unit tests.

| Audit ID | Source verification | This PR disposition | Rationale / remaining evidence |
|---|---|---|---|
| A0 screenshot CI | No existing rendered Mac screenshot evidence | **DEFERRED** | Building a brittle full UX automation harness in this correctness PR would not demonstrate real TC usability. Unverified until authorized Mac visual pilot; do not claim screenshots. |
| A1 CSV Cancel/Use hidden on invalid mapping | **CONFIRMED** | **FIXED in code** | Footer outside optional review, thrown review errors visible, issues placed before sample rows. Needs real Mac interaction confirmation. |
| A2 Office editor unsaved changes lost on Done/switch | **CONFIRMED** | **FIXED in code** | Track actual draft vs saved snapshot, Save/Discard/Keep Editing on Done/office/workflow changes, interactive dismiss prevented while dirty, persist before transition. |
| A3 Relaunch empty state mislabels existing transactions | **CONFIRMED** | **FIXED in code** | Restore local last selected UUID if still present; otherwise show `Select a Transaction` rather than first-time creation. |
| A4 WindowGroup + per-window SQLite model | **CONFIRMED as multiple windows**; auditor's “second app instance” is imprecise | **FIXED in code** | One `Window` scene (one workspace view model), ⌘N wired to New Transaction. No additional app-global mutable scene or command architecture. |
| A5 Linked PDF rendered as second List root row | **CONFIRMED structurally** | **FIXED in code** | One VStack root per checklist item with linked filename inside. |
| A6 Created transaction warning appears in error alert; notices cross clients | **CONFIRMED** | **PARTIAL FIX** | Checklist deferred save is a warning notice, not an error alert; notices cleared at selection and async import/checklist/export outcomes scoped to origin. Existing generic error-alert title still present; no generalized status-action infrastructure. |
| A7 Import summary loses successes, duplicates filenames and truncates errors silently | **CONFIRMED** | **FIXED in code + unit tests** | Add pure `ImportBatchReport` with full counts, singular/plural, interrupt status, no redundant filename and explicit `And N more errors`. On partial failure show summary plus actionable error details. |
| A8 Index-bound draft rows and duplicate fileImporters | Index-bound editing **CONFIRMED**; fileImporter conflict **UNVERIFIED** | **PARTIAL FIX** | Stable UUID draft row bindings replace index bindings. Both importers retained pending reproducible Mac failure; no speculative view refactor. |
| A9 Async reload flashes empty state | **CONFIRMED** | **FIXED in code** | Explicit loading state hides false empty controls while fetching. Clear previous client's state intentionally rather than leaking old documents across a switch. |
| A10 Fatal startup DB errors leave dead interface | **CONFIRMED at code level** | **DEFERRED** | Needs a scoped recovery UX and fault-injected startup test; do not casually add a reset/delete option. Revisit if it blocks G3 or a pilot. |
| B1–B9, C1–C8 visual redesign / identity / shortcuts / preview / copy | Mostly **STATIC OBSERVATIONS OR UNVERIFIED VISUAL INFERENCES** | **DEFERRED** | The product's quality goal is legitimate but release gate evidence and physical Mac inspection are missing. Avoid premature broad styling refactor. |
| D transaction/document/office rename/archive/remove | Missing actions **CONFIRMED in current GUI/core** | **PROPOSED ONLY** | Design explicit authenticated, undoable local actions with safe document retention. Do not code deletion/renaming until user workflows and impact are specified. |

### Exit criteria and stop

1. All pre-existing **54** macOS XCTest plus new import-message tests pass, native Mac SwiftUI app builds, unsigned CI artifact uploads. **Target 57 XCTest.**
2. P1 sheet exits remain discoverable in invalid states in code; opening the office editor/selection is non-destructive to saved transactions, and no new PDF storage or source-hash behavior was touched.
3. User-visible copy never marks a partial success as complete failure or places a warning under an error-only alert. The warning/notification system is *not* claimed universally polished.
4. **NO physical Mac evidence**: SwiftUI rendering, keyboard focus/shortcuts, modal dismissal, Finder permissions, accessibility, 700-point layout, and screenshot automation are **NOT VERIFIED**.
5. Stop after a green PR and review; **no merge without owner review**, and no PR B/C without a distinct reason tied to observed failure or explicit next authorization.

**Verification added 2026-11-21T15:24:46.007Z:** [PR #19](https://github.com/Kajin-0/sorrelgate/pull/19) feature commit `780fffea41ad94bfe0ccb883b860f774a1cc2726`; macOS [#108](https://github.com/Kajin-0/sorrelgate/actions/runs/44918660472) and [#109](https://github.com/Kajin-0/sorrelgate/actions/runs/44918667753) **PASS 57/57 XCTest, native app build, unsigned artifact**. Three new import-report tests passed. This is **not** a visual or human Mac validation. PR remains DRAFT and UNMERGED for owner review.

**Recorded 2026-11-21T15:19:20.413Z.**
