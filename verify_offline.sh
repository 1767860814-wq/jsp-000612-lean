#!/usr/bin/env bash
# Verify this single source against the user's restored offline package.
# No Lake invocation and no network access. Optional argument: package root.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-${LEAN419_ROOT:-/mnt/data/lean419/Lean419_Offline_linux_x86_64}}"
LEAN_BIN="${LEAN_BIN:-$ROOT/lean-4.19.0-linux/bin/lean}"
PKGS="${LEAN_PACKAGES_DIR:-$ROOT/project/JSP301/.lake/packages}"
TRUST=0
if [[ ! -x "$LEAN_BIN" || ! -d "$PKGS/mathlib/.lake/build/lib/lean" ]]; then
  echo 'Missing executable or Mathlib cache. Pass the restored offline-package root.' >&2
  exit 2
fi
case "$("$LEAN_BIN" --version)" in
  *'version 4.19.0,'*) ;;
  *) echo 'This proof was verified with Lean 4.19.0; version mismatch.' >&2; exit 3 ;;
esac
export PATH="$(dirname "$LEAN_BIN"):$PATH"
export LD_LIBRARY_PATH="$ROOT/lean-4.19.0-linux/lib:${LD_LIBRARY_PATH:-}"
export LEAN_PATH="$(find "$PKGS" -type d -path '*/.lake/build/lib/lean' | sort | paste -sd:)"
mkdir -p "$HERE/build"
rm -f "$HERE/build/JSP000612.olean" "$HERE/build/JSP000612.ilean"
ulimit -t 120
ulimit -v 8388608
printf 'EXECUTING_UID: '; id -u
printf 'SYSTEM: '; uname -sm
printf 'CPU_LIMIT_SECONDS: '; ulimit -t
printf 'VIRTUAL_MEMORY_LIMIT_KIB: '; ulimit -v
printf 'UTC_START: '; date -u +%Y-%m-%dT%H:%M:%SZ
"$LEAN_BIN" --version
printf 'TRUST_LEVEL: %s\n' "$TRUST"
printf 'SOURCE: %s\n' "$HERE/JSP000612.lean"
printf 'SOURCE_SHA256: '; sha256sum "$HERE/JSP000612.lean"
set +e
"$LEAN_BIN" --root="$HERE" --trust="$TRUST" -j 2 \
  -DwarningAsError=true -o "$HERE/build/JSP000612.olean" \
  -i "$HERE/build/JSP000612.ilean" "$HERE/JSP000612.lean"
STATUS=$?
set -e
printf 'EXIT_CODE: %s\n' "$STATUS"
printf 'UTC_END: '; date -u +%Y-%m-%dT%H:%M:%SZ
if [[ "$STATUS" -eq 0 ]]; then
  test -s "$HERE/build/JSP000612.olean"
  printf 'OUTPUT_SHA256: '; sha256sum "$HERE/build/JSP000612.olean"
fi
exit "$STATUS"
