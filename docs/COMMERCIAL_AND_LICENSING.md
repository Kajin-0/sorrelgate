# Sorrelgate — Commercial use and third-party licensing

**Commercial intent:** proprietary one-time-licensed macOS software (proposed $149 pilot / $249 standard; subject to validation). The user should never need to pay for external AI or document-processing API requests to use the core application.

- Swift and selected code dependencies may use commercially permissive licenses such as Apache 2.0, MIT and BSD; audit exact versions, complete dependency graph and bundled notices.
- SwiftUI, PDFKit, Vision and Foundation Models are **Apple SDK frameworks**, not Apache 2.0 open-source libraries; follow Apple developer terms.
- SQLite core is public-domain; CoreXLSX is Apache 2.0 subject to verifying the selected release. Verify any redistributed AI model weights separately.
- Initial product policy excludes GPL/AGPL dependencies from the distributed runtime; exclude unlicensed copyrighted blank C.A.R. forms.
- Generate and review an SBOM and all applicable NOTICE/license documents. Never bundle customer documents, certificates, keys, or credentials.
- Directly distributed Mac app needs a Developer ID signed hardened runtime, notarization and stapled DMG. Apple Developer Program/signing costs are not included in the zero third-party runtime license target.
- Before charging: specify user-license scope, support window, security patches, optional paid major upgrades, transfers, refunds, activation and privacy terms.
- **Owner decision (2026-11-20):** GitHub may remain PUBLIC; this is not a block to source development or paid distribution. Public GitHub exposes code for reading/copying; do not assume secrecy or protection from imitation. Publishing code without an explicit open-source license does not grant ordinary open-source permissions. Do not add an open-source license to Sorrelgate application code without explicit owner approval. Never publish client data, credentials, private office material, signing certificates or licensed blank forms.

The repository's planning documents do not themselves grant any open-source permission over future proprietary application code.
