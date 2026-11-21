#!/usr/bin/env python3
"""Release gate for a customer/tester bundle. Scan ALL payload bytes, not only text."""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Keep internal provenance in the development system; never ship it in a ZIP.
DENIED_BYTES = {
    "source-hosting URL": re.compile(
        rb"(?:github\.com|githubusercontent\.com|gitlab\.com|bitbucket\.org)", re.I
    ),
    "developer/account identifier": re.compile(rb"kajin[-_]?0", re.I),
    "source-build instruction": re.compile(
        rb"(?:source commit|commit sha|git clone|git checkout|git fetch|"
        rb"xcodebuild\s|xcodegen\s|swift test\s|AGENTS\.md|"
        rb"CODEX_MASTER_PROMPT|BUILD INFO\.txt)", re.I
    ),
    "developer/CI path": re.compile(
        rb"(?:/Users/[A-Za-z0-9_.-]+/(?:work|Developer|Projects|src|Documents)/"
        rb"|/home/runner/|/mnt/data/|\.build/DerivedData"
        rb"|/SorrelgateApp/|/Sources/SorrelgateCore/)", re.I
    ),
    # Standalone forty-hex revisions, not the permitted 64-hex file SHA-256.
    "40-character source revision": re.compile(
        rb"(?<![0-9a-f])[0-9a-f]{40}(?![0-9a-f])", re.I
    ),
}

DENIED_SUFFIXES = {
    ".swift", ".swiftmodule", ".swiftdoc", ".swiftinterface", ".xcodeproj",
    ".xcworkspace", ".pbxproj", ".dSYM", ".dia", ".o", ".a",
}
DENIED_NAMES = {
    ".git", ".github", "package.swift", "package.resolved",
    "agents.md", "build info.txt", "__preview.dylib",
    "sorrelgate.debug.dylib",
}


def violations(root: Path) -> list[str]:
    problems: list[str] = []
    if not root.is_dir():
        return [f"missing payload directory: {root}"]
    expected = [
        root / "Sorrelgate.app/Contents/Info.plist",
        root / "Sorrelgate.app/Contents/MacOS/Sorrelgate",
        root / "START HERE.txt",
        root / "FOR CODEX - SETUP AND TEST.txt",
        root / "TEST RESULTS.txt",
        root / "Sample Documents",
    ]
    for path in expected:
        if not path.exists():
            problems.append(f"required payload missing: {path.relative_to(root)}")

    for path in root.rglob("*"):
        rel = path.relative_to(root)
        parts = rel.parts
        if any(part.lower() in DENIED_NAMES for part in parts):
            problems.append(f"internal source/build file: {rel}")
        if any(part.endswith(tuple(DENIED_SUFFIXES)) for part in parts):
            problems.append(f"source/debug artifact: {rel}")
        if path.is_symlink():
            target = path.resolve(strict=False)
            if not target.is_relative_to(root.resolve()):
                problems.append(f"symlink outside release bundle: {rel}")
            continue
        if not path.is_file():
            continue
        content = path.read_bytes()
        for reason, pattern in DENIED_BYTES.items():
            if pattern.search(content):
                # Do not print embedded sensitive content into shared logs.
                problems.append(f"{reason} in {rel}")

    return sorted(set(problems))


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: verify_customer_bundle.py PAYLOAD_DIRECTORY", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    found = violations(root)
    if found:
        print("CUSTOMER_BUNDLE_REJECTED", file=sys.stderr)
        for item in found:
            print(f"  {item}", file=sys.stderr)
        return 1
    print("CUSTOMER_BUNDLE_SANITIZED_PASS (binary and text scanned)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
