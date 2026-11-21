#!/bin/bash
# Pack a single UNSIGNED assisted beta. This is NOT an end-user notarized installer.
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1/Contents" ]; then
  echo "usage: bash scripts/package_beta_handoff.sh PATH_TO_Sorrelgate.app" >&2
  exit 2
fi
if [ "$(uname -s)" != "Darwin" ]; then
  echo "Packaging requires macOS." >&2
  exit 2
fi
app="$1"
version="0.1.1"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist" | grep -Fx "$version"
test -f "$app/Contents/MacOS/Sorrelgate"
mkdir -p dist
staging="$(mktemp -d -t SorrelgateBeta)"
trap 'rm -rf "$staging"' EXIT
bundle="$staging/Sorrelgate-Beta-$version-macOS"
mkdir -p "$bundle/Sample Documents"
ditto "$app" "$bundle/Sorrelgate.app"
python3 scripts/generate_beta_fixtures.py "$bundle/Sample Documents"
swift scripts/verify_beta_fixtures.swift "$bundle/Sample Documents"
cp docs/BETA_0_1_README_FIRST.txt "$bundle/README FIRST.txt"
cp docs/BETA_0_1_TEST_REPORT.txt "$bundle/TEST RESULTS.txt"
cp docs/BETA_0_1_TECHNICIAN.md "$bundle/TECHNICIAN SETUP.md"
{
  echo "Sorrelgate Beta $version - UNSIGNED, assisted local test only"
  echo "Source commit: $(git rev-parse HEAD)"
  echo "Built UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "Minimum target: Apple silicon macOS 26"
  echo "Not a signed/notarized release or human-pilot certification."
} > "$bundle/BUILD INFO.txt"
(
  cd "$bundle"
  : > "SAMPLE SHA256.txt"
  for fixture in "Sample Documents"/*; do
    shasum -a 256 "$fixture" >> "SAMPLE SHA256.txt"
  done
  shasum -a 256 -c "SAMPLE SHA256.txt"
)
archive="dist/Sorrelgate-Beta-$version-macOS-UNSIGNED.zip"
ditto -c -k --keepParent "$bundle" "$archive"
unzip -tq "$archive"
echo "BETA_HANDOFF_PACKAGE_PASS archive=$archive version=$version pdfs=3 csv=1"
