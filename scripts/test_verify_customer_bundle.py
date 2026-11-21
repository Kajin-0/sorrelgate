#!/usr/bin/env python3
"""Negative controls for the source/distribution separation gate."""
import tempfile
import unittest
from pathlib import Path

from verify_customer_bundle import violations


class ReleaseBundleScannerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "Sorrelgate-Standalone-Test"
        (self.root / "Sorrelgate.app/Contents/MacOS").mkdir(parents=True)
        (self.root / "Sample Documents").mkdir()
        for relative in [
            "Sorrelgate.app/Contents/Info.plist",
            "Sorrelgate.app/Contents/MacOS/Sorrelgate",
            "START HERE.txt", "FOR CODEX - SETUP AND TEST.txt",
            "TEST RESULTS.txt",
        ]:
            (self.root / relative).write_bytes(b"Clean user-visible content.")

    def assertBlocked(self, relative, data):
        file = self.root / relative
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(data)
        self.assertTrue(violations(self.root), relative)

    def test_clean_minimal_bundle_passes(self):
        self.assertEqual(violations(self.root), [])

    def test_rejects_owner_repo_url(self):
        self.assertBlocked("START HERE.txt", b"https://github.com/Kajin-0/sorrelgate")

    def test_rejects_internal_debug_path_even_in_executable(self):
        self.assertBlocked(
            "Sorrelgate.app/Contents/MacOS/Sorrelgate",
            b"\x00/Users/runner/work/sorrelgate/sorrelgate\x00"
        )

    def test_rejects_source_revision_metadata(self):
        self.assertBlocked("TEST RESULTS.txt", b"Source commit: " + b"a" * 40)

    def test_rejects_included_source_file(self):
        self.assertBlocked("Sources/Main.swift", b"import SwiftUI")

    def test_rejects_debug_dylib(self):
        self.assertBlocked(
            "Sorrelgate.app/Contents/MacOS/Sorrelgate.debug.dylib",
            b"Fake debug library"
        )

    def test_allows_sample_sha256_without_confusing_it_with_a_commit(self):
        (self.root / "SAMPLE SHA256.txt").write_text("a" * 64 + "  Sample Documents/a.pdf\n")
        self.assertEqual(violations(self.root), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
