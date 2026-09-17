#!/usr/bin/env bash
# Standard Lake reproduction after the pinned dependencies have been acquired.
# Generates reproduction/ and build/; never modifies the submitted evidence/.
set -euo pipefail
cd "$(dirname "$0")"
command -v lake >/dev/null || { echo 'Install the pinned Lean toolchain through elan first.' >&2; exit 2; }
mkdir -p build reproduction
rm -f build/JSP000612.olean build/JSP000612.ilean
lake env bash -c '
  set -euo pipefail
  lean --version
  lean --trust=0 -j2 -DwarningAsError=true --root=. \
    -o build/JSP000612.olean -i build/JSP000612.ilean JSP000612.lean
' > reproduction/source_build.log 2>&1
lake env python3 tools/check_replay.py --output-dir reproduction
printf '%s\n' 'PROJECT_REPRODUCTION: PASS; see reproduction/'
