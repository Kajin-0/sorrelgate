#!/bin/bash
# Standalone, source-free Mac tester package. Runs on the trusted CI Mac.
set -euo pipefail
if [ "$#" -ne 1 ] || [ ! -d "$1/Contents" ]; then
  echo "usage: bash scripts/package_beta_handoff.sh PATH_TO_RELEASE_Sorrelgate.app" >&2
  exit 2
fi
if [ "$(uname -s)" != "Darwin" ]; then
  echo "Packaging requires macOS." >&2
  exit 2
fi
app="$1"
version="0.1.2"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$app/Contents/Info.plist" | grep -Fx "$version"
test -f "$app/Contents/MacOS/Sorrelgate"
/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$app/Contents/Info.plist" | grep -Fx '13.0'
lipo "$app/Contents/MacOS/Sorrelgate" -verify_arch arm64 x86_64
for arch in arm64 x86_64; do
  vtool -show-build -arch "$arch" "$app/Contents/MacOS/Sorrelgate" | grep -Eq 'minos 13\\.0'
done
mkdir -p dist
staging="$(mktemp -d -t SorrelgateStandalone)"
trap 'rm -rf "$staging"' EXIT
bundle="$staging/Sorrelgate-Standalone-Test"
mkdir -p "$bundle/Sample Documents"
ditto "$app" "$bundle/Sorrelgate.app"

# The Xcode SwiftPM integration may inject build-machine LC_RPATH entries
# even into an optimized Release binary. Remove ONLY absolute developer/CI
# search paths from the copied unsigned executable, never relative framework
# paths needed by the running app. The binary-aware scanner below is the final
# fail-closed gate for any remaining embedded build paths.
executable="$bundle/Sorrelgate.app/Contents/MacOS/Sorrelgate"
while IFS= read -r rpath; do
  [ -n "$rpath" ] || continue
  case "$rpath" in
    /Users/*|/home/*|/mnt/data/*)
      echo "Removing build-only executable search path"
      install_name_tool -delete_rpath "$rpath" "$executable"
      ;;
  esac
done < <(
  otool -l "$executable" | awk '
    $1 == "cmd" && $2 == "LC_RPATH" { inside = 1; next }
    inside && $1 == "path" { print $2; inside = 0 }
  '
)
# Remove any nonessential DWARF/local-symbol material from the outgoing
# unsigned Release executable; never modify the source build in DerivedData.
strip -S -x "$executable"

python3 scripts/generate_beta_fixtures.py "$bundle/Sample Documents"
swift scripts/verify_beta_fixtures.swift "$bundle/Sample Documents"
cp docs/TESTER_START_HERE.txt "$bundle/START HERE.txt"
cp docs/TESTER_CODEX_SETUP.txt "$bundle/FOR CODEX - SETUP AND TEST.txt"
cp docs/TESTER_REPORT.txt "$bundle/TEST RESULTS.txt"
(
  cd "$bundle"
  : > "SAMPLE SHA256.txt"
  for fixture in "Sample Documents"/*; do
    shasum -a 256 "$fixture" >> "SAMPLE SHA256.txt"
  done
  shasum -a 256 -c "SAMPLE SHA256.txt"
  {
    echo "SORRELGATE APPLICATION FILE INTEGRITY (SHA-256)"
    echo "These file hashes check this package, not Apple notarization."
    find "Sorrelgate.app/Contents/MacOS" -type f -print0 |
      LC_ALL=C sort -z |
      while IFS= read -r -d '' executable; do
        shasum -a 256 "$executable"
      done
  } > "APP INTEGRITY.txt"
)
# Mandatory binary-aware release gate; failure prevents uploaded distribution.
python3 scripts/verify_customer_bundle.py "$bundle"
archive="dist/Sorrelgate-$version-Ventura-Standalone-Mac-Test.zip"
ditto -c -k --keepParent "$bundle" "$archive"
unzip -tq "$archive"
echo "STANDALONE_TEST_BUNDLE_PASS archive=$archive version=$version"
