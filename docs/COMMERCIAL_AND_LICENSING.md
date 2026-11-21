# Sorrelgate — Commercial use and third-party licensing

**Commercial intent:** proprietary one-time-licensed macOS software (proposed $149 pilot / $249 standard; subject to validation). The user should never need to pay for external AI or document-processing API requests to use the core application.

- Swift and selected code dependencies may use commercially permissive licenses such as Apache 2.0, MIT and BSD; audit exact versions, complete dependency graph and bundled notices.
- SwiftUI, PDFKit, Vision and Foundation Models are **Apple SDK frameworks**, not Apache 2.0 open-source libraries; follow Apple developer terms.
- SQLite core is public-domain; CoreXLSX pinned at 0.14.2 is Apache-2.0. Transitive XMLCoder and ZIPFoundation are MIT (version resolution/notice audit required before distribution). Verify any redistributed AI model weights separately.
- Initial product policy excludes GPL/AGPL dependencies from the distributed runtime; exclude unlicensed copyrighted blank C.A.R. forms.
- Generate and review an SBOM and all applicable NOTICE/license documents. Never bundle customer documents, certificates, keys, or credentials.
- Directly distributed Mac app needs a Developer ID signed hardened runtime, notarization and stapled DMG. Apple Developer Program/signing costs are not included in the zero third-party runtime license target.
- Before charging: specify user-license scope, support window, security patches, optional paid major upgrades, transfers, refunds, activation and privacy terms.
- **Owner decision (2026-11-20):** GitHub may remain PUBLIC; this is not a block to source development or paid distribution. Public GitHub exposes code for reading/copying; do not assume secrecy or protection from imitation. Publishing code without an explicit open-source license does not grant ordinary open-source permissions. Do not add an open-source license to Sorrelgate application code without explicit owner approval. Never publish client data, credentials, private office material, signing certificates or licensed blank forms.

The repository's planning documents do not themselves grant any open-source permission over future proprietary application code.


## M2 third-party parser inventory (2026-11-21T05:42:06.767Z; verification of build pending)
- CoreXLSX 0.14.2 — Apache-2.0, https://github.com/CoreOffice/CoreXLSX/blob/0.14.2/LICENSE.md.
- XMLCoder (resolved from CoreXLSX's 0.14.x requirement) — MIT, https://github.com/CoreOffice/XMLCoder; exact resolved version and notices must be frozen in Package.resolved.
- ZIPFoundation (0.9.x, resolved by SwiftPM) — MIT, https://github.com/weichsel/ZIPFoundation; exact resolved version and license/NOTICE must be reviewed before commercial distribution.
- The importer is entirely local and read-only; no cloud/paid API. This preliminary inventory is NOT the final SBOM/transitive audit.
