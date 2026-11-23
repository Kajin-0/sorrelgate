# Sorrelgate — free, Codex-assisted first Mac pilot

**UPDATE 2026-11-23T18:14:27.249Z: FIRST TESTER IS ON macOS VENTURA 13.7.8.** Earlier Beta 0.1.1 requiring macOS26 cannot run; do not use it. Beta 0.1.2 universal macOS13+ ZIP from [verified CI #45235033999](https://github.com/Kajin-0/sorrelgate/actions/runs/45235033999), artifact 14848697514 is the current allowed first-pilot deliverable. The app is unsigned and NOT Apple notarized. The tester uses Finder and the shipped `START HERE.txt`; the ChatGPT/Codex macOS desktop app requires macOS14, so do not demand Codex/Xcode/Terminal on Ventura. Only Apple normal app-specific Open Anyway decision after informed consent, no security disabling, no real client PDFs. True Ventura run still UNVERIFIED. This document is internal and MUST NEVER be copied into the user ZIP, which stays source/repo-reference-free.

**Sanitized distribution VERIFIED (2026-11-21T17:37:12.627Z):** [PR #23](https://github.com/Kajin-0/sorrelgate/pull/23) merged, exact-head macOS runs #44930449639 and #44930455830 succeeded. Share only the **standalone compiled Release app ZIP**; previous developer/Debug ZIPs, this internal document and source links are not for testers. The standalone has no source files, no repository/developer identifiers, only plain local setup instructions and sample data. The recipient must not be directed at source hosting. The app is UNSIGNED; macOS may require informed per-app approval and real on-device testing remains pending.

**CURRENT DELIVERY POLICY (2026-11-21T17:23:12.407Z):** This document is **developer-only** and may contain historical source links for internal provenance. Do not copy it into any tester/customer ZIP or Codex prompt. The previously uploaded Beta 0.1.0/0.1.1 Debug development handoffs are obsolete for external sharing because binaries can embed build paths. Going forward, CI makes a separate **Release-configuration standalone ZIP** with `Sorrelgate.app`, fictional samples, `START HERE.txt`, `FOR CODEX - SETUP AND TEST.txt`, `TEST RESULTS.txt`, and SHA-256 manifests. The assistant only installs and tests supplied compiled files; no source hosting, accounts or developer tools. `scripts/verify_customer_bundle.py` checks all distribution bytes. CI results for this change are pending at this entry; do not distribute an unverified artifact.

## Beta 0.1.1 — first real Mac pilot

One versioned, **unsigned** ZIP artifact was verified in [macOS CI #44924654096](https://github.com/Kajin-0/sorrelgate/actions/runs/44924654096) (59/59 XCTest, native build, PDFKit checks and ZIP integrity), named Sorrelgate-Beta-0.1.1-UNSIGNED-macOS. It expires December 5, 2026; if expired, regenerate using the repository workflow. It contains the native application, three fictional seven-page-total PDFs, optional task CSV, source commit, SHA-256 sample checksums, README FIRST.txt, TEST RESULTS.txt and TECHNICIAN SETUP.md.

**For a nontechnical tester:** No terminal commands are required of you. With your permission, an authorized Codex/technician must set up the app on your Mac. Read README FIRST.txt and complete TEST RESULTS.txt with fabricated PDFs only. Do not disable any Mac security protections.

**For the technician:** Follow [Beta 0.1.1 technical instructions](BETA_0_1_TECHNICIAN.md); check out the exact source revision from BUILD INFO.txt, use free Xcode/XcodeGen, compile and open Sorrelgate locally rather than pretending a downloaded unsigned ZIP is a notarized installer.

**Human pilot stopping point:** A real eligible user completes create/checklist/import/preview/evidence-review/export/reopen on an Apple-silicon macOS 26+ Mac. A CI result cannot establish usability; do not add speculative features to delay this test.

**Purpose:** Install and run a development build on the actual TC's Mac without paying Apple, using Codex or another authorized technical assistant to handle terminal/developer setup. This is **not** the final one-click customer installation experience.

## Requirements and boundaries
- Tester authorizes Codex/engineer to operate **their own Mac**. The Mac must be Apple silicon (M1 or newer) and run the currently targeted macOS **26+**; Codex checks compatibility first.
- Free Xcode from the Mac App Store (large download and disk-space requirement), free XcodeGen (MIT, developer-only) and public Sorrelgate GitHub source. A normal free Apple ID may be needed for App Store downloads, but **no paid Apple Developer membership**.
- Do not ask the nontechnical tester to type commands. Codex may use terminal, install authorized developer software, and troubleshoot. Never disable system-wide Gatekeeper, SIP or other security safeguards.
- Avoid real client contracts for the initial smoke test. Use synthetic/local PDFs; keep all personal information, credentials and signing materials out of public GitHub issues and logs.

## Instructions for Codex on the tester's Mac
You are setting up a **free, local, supervised Sorrelgate beta** for a nontechnical Mac owner. Obtain their authorization before installing packages or changing macOS settings. Read https://github.com/Kajin-0/sorrelgate/AGENTS.md and docs/STATUS.md and the source build configuration. Verify `sw_vers`, `uname -m`, `xcodebuild -version`, `swift --version` and available free disk space. If macOS 26 or Apple silicon is unavailable, report the incompatibility instead of installing anything.

Install full Xcode (free) if missing and complete only its normal first-run setup with the owner's permission. Install XcodeGen if absent, preferring the documented compatible free method. Clone the **public** repository to an agreed folder. From the repo, generate `Sorrelgate.xcodeproj` with `xcodegen generate --spec project.yml`; run `swift test --parallel`; then build via `xcodebuild -project Sorrelgate.xcodeproj -scheme Sorrelgate -configuration Debug -destination "generic/platform=macOS" -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build`. Locate `.build/DerivedData/Build/Products/Debug/Sorrelgate.app` and launch locally with `open`. A locally built development app is different from an unsigned downloaded archive. Do not bypass operating-system protection if blocked: inspect the actual security warning and ask permission before any safe resolution.

If installation/launch fails, preserve exact non-sensitive logs and troubleshoot. Never declare a working app without opening and operating it on the Mac.

## Five-minute smoke-test script
1. Start the application; create a new synthetic **Accepted Offer** transaction.
2. Confirm the 12 starter administrative tasks appear; rename one, add one and mark one completed.
3. Import 2–5 synthetic PDFs, select a document and verify its actual pages render.
4. Link a PDF to a checklist item; change another task; verify the selected PDF remains visible.
5. Export the transaction and inspect copied PDFs, Checklist.txt and Manifest.json.
6. Quit and relaunch; verify transactions, tasks, linked documents and stored previews persist.

## Test report
Report Mac hardware, macOS/Xcode/Swift versions, exact commit, run result per step, errors, sanitized screenshots and any confusing interface behavior. Never upload actual customer documents or private data to public GitHub. The app may be imperfect: report issues rather than masking problems.

## Later (not now)
After the MVP is strong and the owner approves spending, prepare a signed/notarized or supported App Store distribution for genuine click-to-install customer experience. This pilot guide does not require or initiate that payment.
