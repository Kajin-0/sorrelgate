#!/bin/bash
# Mac CI startup check for the compiled native application; NOT a Ventura test.
set -euo pipefail
app="${1:?Provide macOS Sorrelgate.app path}"
# LaunchServices resolves -a paths reliably only when absolute.
app="$(cd "$(dirname "$app")" && pwd -P)/$(basename "$app")"
test -f "$app/Contents/MacOS/Sorrelgate"
test "$(uname -s)" = "Darwin"
echo "MAC_LAUNCH_SMOKE_HOST=$(sw_vers -productVersion)"
echo "MAC_LAUNCH_SMOKE_START"
# Using open exercises LaunchServices + the native AppKit entrypoint.
# Do not disable Gatekeeper, modify quarantine state, or install elsewhere.
/usr/bin/open -n -a "$app"
pid=""
for i in $(seq 1 25); do
  candidate="$(pgrep -x Sorrelgate | head -n 1 || true)"
  if [[ -n "$candidate" ]] && kill -0 "$candidate" 2>/dev/null; then
    pid="$candidate"
    break
  fi
  sleep 1
done
if [[ -z "$pid" ]]; then
  echo "MAC_LAUNCH_SMOKE_FAIL: app process never became active" >&2
  exit 1
fi
# Check that it does not terminate immediately while loading its stores/UI.
sleep 5
if ! kill -0 "$pid" 2>/dev/null; then
  echo "MAC_LAUNCH_SMOKE_FAIL: app crashed or terminated on startup" >&2
  exit 1
fi
ps -p "$pid" -o pid=,comm=,etime=
echo "MAC_LAUNCH_SMOKE_PASS: app launched and stayed alive for 5s"
# Running on an ephemeral CI Mac; cleanup is safe.
kill "$pid" || true
