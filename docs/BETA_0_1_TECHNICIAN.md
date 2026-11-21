# Sorrelgate Beta 0.1.0 — Mac technician / Codex setup

**Goal:** Conduct the first free supervised usability test on an authorized
Apple-silicon Mac running macOS 26+. This ZIP contains an UNSIGNED .app,
fabricated PDF fixtures and tester notes. It is not a normal one-click
customer installer. Do not disable Gatekeeper, SIP, or other protections,
remove quarantine to bypass checks, or use real client data.

## Setup (technician handles terminal commands)

1. Ask permission before installing free tools or touching user files.
   Verify arm64 CPU with uname -m, macOS version with sw_vers, and space
   for the full Xcode installation. Stop if minimum requirements are unmet.
2. Install free Xcode from the Mac App Store if needed, and perform normal
   first-run setup. Install free XcodeGen if needed and authorized. No
   paid Apple Developer membership or cloud API key is required.
3. Clone https://github.com/Kajin-0/sorrelgate. Check out the *exact*
   commit from BUILD INFO.txt for reproducible Beta 0.1.0 testing rather
   than silently building a moving main branch.
4. From the repository root run:

       swift test --parallel
       xcodegen generate --spec project.yml
       xcodebuild -project Sorrelgate.xcodeproj -scheme Sorrelgate \
         -configuration Debug -destination "generic/platform=macOS" \
         -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build
       bash scripts/package_beta_handoff.sh \
         .build/DerivedData/Build/Products/Debug/Sorrelgate.app

5. Locate the locally built app in
   .build/DerivedData/Build/Products/Debug/Sorrelgate.app
   and open it with permission. Keep the sample PDFs visible in Finder.
   A locally compiled debug app is not Developer ID signed/notarized.
   If macOS blocks launch, diagnose the warning and stop rather than
   suggesting security-bypass instructions. Do not overwrite old user
   data or a previous installation without separate consent.

## Observe the human, not just the compiler

Let the tester follow README FIRST.txt; record each PASS/FAIL in
TEST RESULTS.txt. Watch whether they can create a transaction, understand
the checklist, import PDFs, inspect original pages, mark proposals
Confirm/Reject/Unknown, export a package, quit, and reopen. Offer
assistance only if they are blocked.

Verify source files and exports retain the sample SHA-256 digests as
appropriate. Document the actual Mac/OS/Xcode, source SHA, step, failure
and sanitized screenshots; never include confidential client data in
public issues or logs.

**Stop rule:** A working CI app is NOT a completed human pilot.
Commercial self-service DMG signing/notarization remains deferred
until the owner approves spending and all relevant release gates pass.
