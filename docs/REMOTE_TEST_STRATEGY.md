# Sorrelgate — CI-first development, no local Mac, external tester handoff

**Decision:** 2026-11-21T04:54:03.882Z (UTC). Owner has no Mac. No further request for owner-side Mac testing should block engineering.

## What we CAN validate continuously
- GitHub Actions on macOS Apple Silicon: Swift compilation, package tests, database migrations, synthetic PDF import and OCR comparisons, export checks, hash preservation, error handling, action dispatcher permissions.
- With suitable CI automation: process launch, cold-start database setup, clean restart, deterministic functional smoke scenarios, screenshots or UI tests **only if reliable in the hosted runner**.
- Replay synthetic transactions, including unreadable PDFs, duplicates, cancelled imports, malformed fields, and prompt-injection samples. Confirm changes through SQLite records and file hashes.
- Record runner image, Xcode/Swift versions, GitHub run links, test counts, pass/fail and known blind spots.

## What CI cannot substitute for
- Human readability, comfortable interactions, visual polish, actual Finder/picker behavior, unfamiliar user's experience.
- First-install Gatekeeper behavior on a customer's Mac, VoiceOver/keyboard ergonomics, actual target-model performance, and end-to-end on-device Apple Foundation Models behavior without an eligible device/model runtime.
- Real TC workflow utility. All of these are **PENDING EXTERNAL MAC PILOT** until tested, not "passed" or "not needed."

## Delivery plan for the FIRST external Mac tester
1. Finish an actually useful MVP vertical slice: create transaction, select files, OCR scanned PDFs, link documents to checklist, preserve originals, export review package. Favor synthetic documents for initial use.
2. Prepare a distinct TESTER release configuration with versioned installer and clear first-run instructions.
3. Preferred low-friction distribution: Developer ID code-signed, hardened runtime, Apple-notarized application, packaged/stapled DMG; alternative supported App Store Connect/TestFlight flow where available. Apple Developer account, identities and related credentials are prerequisites and must be securely managed as GitHub encrypted secrets, **never committed to public repo**. This setup is not completed.
4. Do not send an unsigned GitHub Actions build as a routine one-click install to a nontechnical TC; Gatekeeper may block. Never direct them to disable system-wide Mac security.
5. Give the tester a short five-minute onboarding guide and a small synthetic sample transaction. Ask them to open, import, inspect, export, quit/relaunch, and report confusing screens.
6. Gather results via version number, Mac model, macOS version, pass/fail tasks, redacted screenshots and opt-in sanitized diagnostics. Keep real client PDFs, signatures and financial information out of public GitHub issues.
7. Fix defects, rerun CI, and repeat until user navigation and output are reliable. Only then begin a real supervised TC workflow test with proper permission and privacy.

## Explicit quality/status nomenclature
- **CI passed:** specific hosted automated tests were executed successfully.
- **App compiled:** Xcode produced .app; no claim it was manually opened.
- **Unsigned artifact:** developer ZIP for controlled testing only, **not** the product install.
- **Tester ready:** installable beta passes CI, signing, notarization (or eligible alternative), privacy prerequisites, and launch/readme packaging.
- **Human verified:** real Mac user executed named tasks on target hardware and reported outcomes.
- **Sellable:** all release gates, including usability, privacy, licensing and authorized TC pilot, have passed.

## Development precedence
Proceed M0 test hardening → M1 PDF/checklist/export → M2 office customization → M3 recognition → M4 drafts → M5 safe LLM actions. Do not implement a huge speculative UI just because nobody can yet inspect it; favor conventional native controls, accessibility labels, small vertical slices and deterministic QA.

This policy intentionally separates **lack of physical testing** from **inability to test**. We can test extensively in macOS CI; final human usability validation is deferred, not waived.
