# Test boundaries

The only proposed mathematical proof is `JSP000612.lean`. It does not import these tests.

`AxiomControl.lean` deliberately introduces an unproved axiom for the rejection test in `tools/check_replay.py`. `RejectedCandidates.lean` deliberately contains `sorry`, additional assumptions, a false specification and a definition in place of a theorem. Its compilation alone is not success: `tools/check_statement_gate.py` verifies that nine bad candidates are rejected by the exact-type/axiom audit and that an unaffected valid theorem remains accepted.

`python3 -m unittest discover -s tests -p 'test_*.py' -v` tests reference rendering and safe insertion into an existing catalogue. Test-only GitHub names/commits are examples, not public proof references.

The finite graph enumeration is an independent Python sanity calculation, not an independent implementation of Lean's kernel and not a replacement for the general proof. Historical unexecuted or superseded controls may be inspected inside `history/previous_submission.zip`; they are not counted in the current results.
