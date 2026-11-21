# Review-first interface audit — 2026-11-21T16:48:58.922Z

**Method:** Static inspection of the complete native SwiftUI workflow (main window,
new transaction, office checklist editor, spreadsheet import sheets, task editor
and PDF preview) together with the backend action/persistence path. This is a
source-level audit and a bounded remediation. **No physical Mac screenshot,
human readability, VoiceOver, Finder file-picker interaction or 700-point
window test has passed.** A native Xcode build is not a substitute.

## Daily workflow: before → after and stopping criterion

| Area | Source-observed issue | Bounded change | Remaining evidence |
| --- | --- | --- | --- |
| Transaction detail | Sidebar + PDF list + checklist + PDF preview + review compete for space; review is below the preview | One content mode at a time: **Review** (default), **Documents**, **Checklist**; section labels are plain language | Render and navigate at normal/large text sizes on an actual Mac |
| First action | User previously had to select each file to find candidate fields | One **Find details in PDFs** call over all already-imported files in the selected transaction | Verify user finds it without coaching |
| Review queue | Proposed and decided values mixed in one cramped scroller | Proposed/Unknown remain in the visible queue; Confirmed/Rejected are grouped under **Previous decisions** | Test handling many documents, scrolling, keyboard and VoiceOver |
| Human decisions | Critical Confirm/Reject/Unknown choices hidden inside a generic menu | **Confirm**, **Not sure**, **Reject** are explicit; state text says **Confirmed by you** and **Not sure yet** | Test human understanding; no confirmation is legal validation |
| Original citation | PDF preview shared the right side with review, pushing review below | **View original** opens verified PDF at the exact page in its own sheet | Physical page navigation and screen sharing not yet observed |
| Contradictions | Conflicting value marked with technical field-name copy | Short plain-language warning to compare original source pages | Evaluate layout with two different candidates and corrections |
| Task list | Always visible alongside document review, with two icon-only actions per task | Separate Checklist view with native checkboxes and one clearly named task-options menu | Human Mac discoverability and focus order |
| Office settings | Large editor with advanced CSV/XLSX column mapping in core daily window toolbar | Retain separate modal; daily review does not expose template internals | Office editor remains complex and needs pilot, not an automatic redesign |
| Empty state | “0 to review” can wrongly imply completed verification | **No suggestions yet**, plus explanation that recognition does not check completeness | Verify no false sense of contract compliance |
| Document processing | Per-PDF scanning drove repeated GUI work | New actor-level transaction-wide discovery with source hash/review decisions preserved | No actual model controller or agent receipts exists |

## UI rules for remaining engineering

- **Default to user decisions, not backend configuration.** User sees what needs
  attention, source evidence and what was done. Export is present but cannot
  imply legal completeness or automatically email anything.
- **Only one primary task per screen.** Prefer short verbs and natural labels to
  technical categories; give clear Undo/correction routes before adding more
  automation. Keep model/provider internals out of everyday screens.
- **The backend is the workhorse.** Repeatable, scoped, typed operations, data
  integrity, audit receipts and adversarial checks belong in SorrelgateCore.
  UI and eventual model must call the *same* services; model authorization
  happens outside the model. The existing batch recognizer is only a primitive.
- **Never call finding a value a legal verification.** Every candidate starts
  unverified; source-page links and human decisions remain explicit. PDFs are
  untrusted data, not instructions.
- **Reduce friction only when safety stays visible.** Preserve import errors,
  partial success notices, missing-source refusal, unsaved-office confirmations
  and original document integrity checks. Do not auto-send, sign or delete.
- **External evidence is required.** The unsigned Beta 0.1.1 must be exercised
  by a real, nontechnical user on a supported Mac, including reading PDFs,
  managing a contradictory value, exporting and relaunching. Note the tasks
  they struggle with; fix only the demonstrated blockers.

## Deferred, not claimed done

Physical UI rendering at narrow widths and text scaling; VoiceOver and keyboard
focus; office-sheet overflow and editable spreadsheet mapping complexity;
a clean macOS installer; native AI operator, authorization/receipts and
model reliability. Actual usability and task completion must come from the
authorized Mac pilot. No generic assistant chat UI is introduced here.
