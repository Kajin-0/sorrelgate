# Sorrelgate — Release and support (planned only)

**Standalone source-isolation gate passed (2026-11-21T17:37:12.627Z):** The customer ZIP from exact PR-head #44930449639/#44930455830 passes the binary-aware source/repo reference scan, 7 negative/positive tests, native Release build and checksum/ZIP checks. All earlier Debug/test handoffs are superseded. Do not conflate the clean package with notarization or a completed Mac pilot.

**Permanent external distribution policy (2026-11-21T17:23:12.407Z):** Every file, artifact, prompt and test report delivered to a customer/tester must be source-free and free of owner repository/account identifiers, revisions, debug symbols and CI/developer paths. The internal repository documentation and technical builds are **never** included. Source-free ZIP is compiled in Release configuration, scanned byte-by-byte including binaries by `scripts/verify_customer_bundle.py`, and packaged with only standalone guides and fictional files. A successful scan does **not** equal Apple Developer ID signing or notarization; commercial status remains NO-GO.

**Release status:** Commercial NO-GO. Native Mac builds exist; a Beta 0.1.1 **unsigned assisted tester ZIP** is now prepared by CI. No notarized self-service installer or human Mac pilot has passed.

Required sequence: verify Mac/Xcode/Swift and Apple Foundation Models eligibility → run all unit, integration, UI, offline, source-integrity and adversarial tests → audit full transitive license inventory/SBOM and secrets → test backups/restore and upgrade migrations → sign with Developer ID + hardened runtime → notarize and staple DMG → test Gatekeeper/drag-to-Applications on a clean nondeveloper Mac → validate accessibility, nontechnical onboarding, error recovery and user training → run authorized TC pilot with measured time savings → finalize commercial purchase/support/refund/license terms.

Publish a short quick-start guide, privacy FAQ, sample synthetic transaction and uninstall/backup instructions. Do not assert release readiness on documentation, simulated tests, or success-looking UI screenshots.
