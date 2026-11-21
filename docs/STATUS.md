# Sorrelgate — Current state

****Last checked:** 2026-11-21T04:11:26.509Z (UTC)ntation baseline; before M0
**Repository:** https://github.com/Kajin-0/sorrelgate
**GitHub visibility at kickoff:** PUBLIC — must change to private before proprietary source is pushed.
**Release:** NOT STARTED; no application code, Mac builds, installers, OCR accuracy data, or AI control verified.

## Verified baseline
- GitHub connector account Kajin-0 has administrative and push rights.
- This repository was confirmed empty before the initial README/docs commit.
- Planning materials were renamed to Sorrelgate and added as the permanent product baseline.
- 20 documentation/configuration files committed to main; milestone issues #1–#7 and visibility blocker #8 opened.
- The two workflows are office-customizable administrative templates; not a legal checklist.

## Gates
| Milestone | Status | Actual verification |
|---|---|---|
| M0 native Mac shell / persistence | Not started | No Xcode run |
| M1 PDF import / OCR / preview / checklist / export | Not started | No implementation |
| M2 office profiles / XLSX / workflow versioning | Not started | No implementation |
| M3 document recognition / checks | Not started | No evaluation |
| M4 timelines / draft communications / packages | Not started | No implementation |
| M5 guarded LLM tool execution | Not started | No agent scenarios run |
| M6 paid Mac release | Not started | No notarized build or pilot |

## Immediate next steps
1. **Make repository private** (tracked in [issue #8](https://github.com/Kajin-0/sorrelgate/issues/8)) in GitHub Settings > General > Danger Zone. Current visibility is public.
2. Start Codex on an authorized Apple-silicon Mac with Xcode; record actual macOS/Xcode/Swift versions and Foundation Models availability.
3. Complete M0 then M1 vertical slice (create transaction → import PDFs → OCR/preview → checklist → safe export → quit/reopen persistence), with real test outputs.
4. Obtain appropriately authorized, sanitized office checklists and representative TC samples without committing real customer data.

## Maintenance protocol
Each meaningful change must update this status, append a timestamped entry to `docs/CHANGELOG.md` and record new scope/architecture decisions in `docs/DECISIONS.md`. Never upgrade status based on a design-only claim.
