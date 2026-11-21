# Sorrelgate — Security and privacy requirements

**Status:** planned controls; no security audit yet.

## Information at risk

Real estate paperwork can contain signatures, home addresses, identities, private financial terms and banking instructions. Keep originals, OCR, indexes, contacts and task history local by default. Never upload to cloud models without a distinct explicit opt-in and clear disclosure. Do not commit any customer document, contact list, signing key, private office template or C.A.R. copyrighted blank forms.

## Required controls

- Native user-selected file grants; reject unsupported files, traversal, unsafe symlinks and oversized/problematic inputs.
- Immutable internally stored PDF originals with SHA-256 and metadata. No silent deletion or overwrite; atomic persistence, safe restart, backups/restore.
- Typed least-privilege tools, enforced transaction scope, deterministic approval tokens, complete action receipts.
- Human confirmation of consequential dates/terms and signature-review outcomes. Finding a signature is **not** validating it.
- No v1 external email sending, arbitrary shell, code execution or general filesystem/network tools for the agent.
- Treat PDF text, OCR text, spreadsheets and imported content as **untrusted data**, including embedded instructions or tool-looking text.
- Clear, privacy-safe errors and local diagnostics with content redaction; avoid PII in logs and crash reports.
- Explicit export preview; user-selected target, no silent overwrite, reliable manifest and integrity checks.
- Apple notarization/signing and dependency/model-weight license audit before commercial release.

## Required negative controls

Prompt-injection PDFs, cross-transaction read attempts, replayed approvals, corrupted PDFs, zero-byte files, malicious filenames/path traversal, OCR cancellation, SQLite crash/recovery, privacy leakage, unauthorized export, unexpected external network contact, and source-file mutation must be tested with synthetic fixtures. Any confirmed data loss, unauthorized external transmission or unapproved legally consequential action blocks release.
