#!/usr/bin/env python3
"""Run complete dependency replay and two deliberately invalid controls.

Invoke under `lake env python3 ...`, or provide --offline-root. This driver
is not a second checker implementation: it exercises the same Lean kernel.
"""
from __future__ import annotations
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time


def digest(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--offline-root', type=Path)
    p.add_argument('--output-dir', type=Path, default=Path('reproduction'))
    p.add_argument('--timeout', type=int, default=180)
    a = p.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = a.output_dir.resolve(); output.mkdir(parents=True, exist_ok=True)
    build = root/'build'; build.mkdir(exist_ok=True)
    env = dict(os.environ)
    if a.offline_root:
        r = a.offline_root.resolve()
        env['PATH'] = str(r/'lean-4.19.0-linux/bin') + ':' + env.get('PATH', '')
        env['LD_LIBRARY_PATH'] = str(r/'lean-4.19.0-linux/lib') + ':' + env.get('LD_LIBRARY_PATH','')
        paths = sorted((r/'project/JSP301/.lake/packages').glob('*/.lake/build/lib/lean'))
        if not paths:
            p.error('No offline package dependency caches found')
        env['LEAN_PATH'] = ':'.join(map(str, paths))
    lean = shutil.which('lean', path=env.get('PATH'))
    if not lean or not (build/'JSP000612.olean').is_file():
        p.error('Lean executable and freshly compiled build/JSP000612.olean are required')
    env['LEAN_PATH'] = str(build) + ':' + env.get('LEAN_PATH','')
    version = subprocess.check_output([lean, '--version'], env=env, text=True).strip()
    if 'version 4.19.0,' not in version:
        p.error('This replay adapter is pinned to Lean 4.19.0')
    control_compile = subprocess.run(
        [lean, '--trust=0', '-DwarningAsError=true', '-o', str(build/'AxiomControl.olean'),
         'tests/AxiomControl.lean'], cwd=root, env=env, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=a.timeout)
    (output/'axiom_control_compile.log').write_text(control_compile.stdout + f'\nEXIT_CODE: {control_compile.returncode}\n')
    if control_compile.returncode != 0:
        raise RuntimeError('The axiom control must compile before its axiom policy is tested')
    cases = [
        ('positive', ['JSP000612', 'JSP612'], 0, ['FRESH_KERNEL_REPLAY: PASS']),
        ('mutation', ['JSP000612', 'JSP612', 'mutate-proof'], 1,
         ['INTENTIONAL_PROOF_MUTATION:', '(kernel) declaration type mismatch']),
        ('axiom', ['AxiomControl', 'test_only_claim'], 1,
         ['Unapproved axiom: test_only_unproved']),
    ]
    results = []
    for name, args, expected, markers in cases:
        start = time.monotonic()
        stamp = dt.datetime.now(dt.timezone.utc).isoformat()
        cmd = [lean, '--run', 'tools/Recheck.lean', *args]
        result = subprocess.run(cmd, cwd=root, env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=a.timeout)
        log = (f'UTC_START: {stamp}\n{version}\n'
               'CHECK_TYPE: same-Lean-kernel dependency replay, not an independent implementation\n'
               f'SOURCE_SHA256: {digest(root/"JSP000612.lean")}\n'
               f'CHECKER_SHA256: {digest(root/"tools/Recheck.lean")}\n'
               + result.stdout + f'\nEXIT_CODE: {result.returncode}\n')
        path = output/f'replay_{name}.log'; path.write_text(log)
        passed = result.returncode == expected and all(m in result.stdout for m in markers)
        record = dict(case=name, exit_code=result.returncode, expected_exit_code=expected,
                      required_markers=markers, control_passed=passed,
                      seconds=round(time.monotonic()-start,3), log_sha256=digest(path))
        if name == 'positive' and passed:
            record['theorem_roots_including_generated'] = int(re.search(r'ROOT_THEOREMS: (\d+)', log).group(1))
            record['transitive_closure_declarations'] = int(re.search(r'CLOSURE_DECLARATIONS: (\d+)', log).group(1))
            replayed = set(re.findall(r'^REPLAYED: (\S+)', log, re.M))
            explicit = {'JSP612.'+n for n in re.findall(r'^theorem\s+([A-Za-z0-9_.]+)',
                        (root/'JSP000612.lean').read_text(), re.M)}
            if not explicit <= replayed:
                raise RuntimeError(f'Missing explicit theorem roots: {sorted(explicit-replayed)}')
            record['explicit_theorems_replayed'] = len(explicit)
        results.append(record)
        print(f'{name}: {"PASS" if passed else "FAIL"} (exit {result.returncode})', flush=True)
    report = dict(underlying_checker_implementations=1,
                  independent_external_checker_implementations_completed=0,
                  source_sha256=digest(root/'JSP000612.lean'),
                  checker_sha256=digest(root/'tools/Recheck.lean'), results=results)
    (output/'replay_results.json').write_text(json.dumps(report, indent=2)+'\n')
    if not all(r['control_passed'] for r in results):
        raise RuntimeError('Replay/control verification failed; inspect logs')

if __name__ == '__main__':
    main()
