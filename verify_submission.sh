#!/usr/bin/env bash
# Complete local reproduction. Evidence and source files are not modified.
# Optional argument: restored Lean419_Offline_linux_x86_64 package root.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="${1:-}"
mkdir -p build reproduction
python3 tools/verify_manifest.py
if [[ -n "$ROOT" ]]; then
  ROOT="$(cd "$ROOT" && pwd)"
  bash verify_offline.sh "$ROOT" > reproduction/source_build.log 2>&1
  python3 tools/check_replay.py --offline-root "$ROOT" --output-dir reproduction/replay
  python3 tools/check_statement_gate.py --offline-root "$ROOT" --output-dir reproduction/statement_gate
else
  bash verify.sh
  lake env python3 tools/check_statement_gate.py --output-dir reproduction/statement_gate
fi
python3 tools/small_graph_check.py --output-dir reproduction/finite
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/verify_manifest.py
printf '%s\n' 'SUBMISSION_LOCAL_REPRODUCTION: PASS' \
  'This is not an independent-checker result, official acceptance or an award decision.'
