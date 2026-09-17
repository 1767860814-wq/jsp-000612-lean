#!/usr/bin/env python3
"""Build the separately written challenge and test exact types/axiom dependencies.
Same Lean kernel, not Nanoda, Comparator, or an independent referee report.
Run under lake env, or use --offline-root. Never changes evidence by default.
"""
from __future__ import annotations
import argparse, datetime as dt, hashlib, json, os, re, shutil, subprocess, time
from pathlib import Path

def main() -> None:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--offline-root',type=Path)
    ap.add_argument('--output-dir',type=Path,default=Path('reproduction/statement_gate'))
    ap.add_argument('--timeout',type=int,default=180)
    args=ap.parse_args();root=Path(__file__).resolve().parents[1]
    out=args.output_dir.resolve();out.mkdir(parents=True,exist_ok=True)
    build=root/'build';build.mkdir(exist_ok=True)
    env=dict(os.environ)
    if args.offline_root:
        er=args.offline_root.resolve(); env['PATH']=str(er/'lean-4.19.0-linux/bin')+':'+env.get('PATH','')
        env['LD_LIBRARY_PATH']=str(er/'lean-4.19.0-linux/lib')+':'+env.get('LD_LIBRARY_PATH','')
        caches=sorted((er/'project/JSP301/.lake/packages').glob('*/.lake/build/lib/lean'))
        if not caches: ap.error('Offline Mathlib caches missing')
        env['LEAN_PATH']=':'.join(map(str,caches))
    env['LEAN_PATH']=str(build)+':'+env.get('LEAN_PATH','')
    lean=shutil.which('lean',path=env.get('PATH'))
    if lean is None or not (build/'JSP000612.olean').is_file():
        ap.error('A Lean executable and a fresh build/JSP000612.olean are required')
    ver=subprocess.check_output([lean,'--version'],text=True,env=env).strip()
    if 'version 4.19.0,' not in ver:ap.error('Adapter requires Lean 4.19.0')
    records=[]
    def run(name: str, file: Path, code: int, marker: str='', *, warnings: bool=True, emit: str|None=None):
        command=[lean,'--root='+str(root),'--trust=0','-DwarningAsError='+str(warnings).lower()]
        if emit: command += ['-o',str(build/(emit+'.olean'))]
        command.append(str(file));t=time.monotonic()
        p=subprocess.run(command,cwd=root,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=args.timeout)
        good=p.returncode==code and (not marker or marker in p.stdout)
        (out/(name+'.log')).write_text(f'UTC: {dt.datetime.now(dt.timezone.utc).isoformat()}\n{ver}\n'+p.stdout+f'\nEXIT_CODE: {p.returncode}\n')
        record=dict(case=name,exit_code=p.returncode,expected_exit_code=code,required_marker=marker,passed=good,seconds=round(time.monotonic()-t,3))
        records.append(record); print(f'{name}: {"PASS" if good else "FAIL"} (exit {p.returncode})',flush=True)
        if not good: raise RuntimeError(f'Unexpected result: {name}; inspect {out/(name+".log")}')
        return p.stdout
    try:
        run('build_challenge',root/'SubmissionChallenge.lean',0,emit='SubmissionChallenge')
        run('build_gate_support',root/'GateSupport.lean',0,emit='GateSupport')
        text=run('six_real_statements',root/'StatementGate.lean',0,'EXACT_TYPE_AND_AXIOMS_PASS')
        if len(re.findall(r'^EXACT_TYPE_AND_AXIOMS_PASS:',text,re.M))!=6:
            raise RuntimeError('Not all six statements were checked')
        run('compile_bad_candidates',root/'tests/RejectedCandidates.lean',0,warnings=False,emit='RejectedCandidates')
        cases=[
          ('changed_to_true','RejectedCandidates.changedToTrue','WitnessStatement','TYPE_MISMATCH'),
          ('explicit_assumption','RejectedCandidates.explicitHypothesis','WitnessStatement','TYPE_MISMATCH'),
          ('typeclass_assumption','RejectedCandidates.typeclassHypothesis','WitnessStatement','TYPE_MISMATCH'),
          ('invented_axiom','RejectedCandidates.axiomBased','WitnessStatement','UNAPPROVED_AXIOM'),
          ('sorry','RejectedCandidates.sorryBased','WitnessStatement','UNAPPROVED_AXIOM'),
          ('not_a_theorem','RejectedCandidates.notATheorem','WitnessStatement','NOT_A_THEOREM'),
          ('weakened_criticality','RejectedCandidates.weakenedCritical','WitnessStatement','TYPE_MISMATCH'),
          ('hardcoded_extremum','RejectedCandidates.hardcodedAnswer','NoThresholdStatement','TYPE_MISMATCH'),
          ('missing_declaration','RejectedCandidates.doesNotExist','WitnessStatement','MISSING_THEOREM'),
        ]
        for name,target,spec,marker in cases:
            p=build/(f'GateCase_{name}.lean')
            p.write_text('import SubmissionChallenge\nimport GateSupport\nimport RejectedCandidates\n'+f'audit_exact {target} against JSP612Challenge.{spec}\n')
            run(name,p,1,marker)
        p=build/'GateCase_unused_bad_declarations.lean'
        p.write_text('import SubmissionChallenge\nimport GateSupport\nimport RejectedCandidates\n'+'audit_exact JSP612.jsp000612 against JSP612Challenge.WitnessStatement\n')
        run('unused_bad_declarations_do_not_taint_good_proof',p,0,'EXACT_TYPE_AND_AXIOMS_PASS')
    finally:
        report={'checked_at_utc':dt.datetime.now(dt.timezone.utc).isoformat(),'source_sha256':hashlib.sha256((root/'JSP000612.lean').read_bytes()).hexdigest(),'challenge_sha256':hashlib.sha256((root/'SubmissionChallenge.lean').read_bytes()).hexdigest(),'independent_checker':False,'independent_human_review':False,'results':records}
        (out/'statement_gate_results.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
