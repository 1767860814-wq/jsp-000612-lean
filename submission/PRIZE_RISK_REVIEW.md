# Prize-focused review, 2026-09-17

This is the submitting project's review, not independent certification.

## Mathematical scope

The 800-line proof source is unchanged. The original Erdős question (1981, PDF page 15) permits an existential chromatic threshold. The theorem `no_chromatic_threshold_for_extremal_divergence` negates that quantified assertion. Criticality ranges over every proper subgraph, actual unordered existing edges are counted, and the extremal value comes from genuine attainable counts. The arbitrarily large bounded-deletion witnesses are enough to refute divergence; exact witnesses at every sufficiently large order are not needed for that logical conclusion. Official scope acceptance has not been adjudicated. The later sharp universal lower bound / eventual exact formula is not claimed.

Original source inspected: https://www.renyi.hu/~p_erdos/1981-16.pdf (PDF page 15).

## Submission-rule check

The current CONTRIBUTING instructions accept complete original-problem formalizations and require an external public proof repository, named branch, full commit, theorem, authorship and build evidence. The branch must contain the commit. Proof sources and archives stay in the external repository; the official PR contains references and catalogue text. No status is unilaterally changed here.

Source checked on 2026-09-17: https://github.com/TheJustinSunPrize/awards/blob/main/CONTRIBUTING.md

The selection rules describe submission before designated offline verification and award evaluation. Passing our local checks is not an award decision. The formalization role is distinct from historical mathematical discovery; the project does not claim new-mathematics credit, a specified award amount, or a first-public timestamp.

Source checked on 2026-09-17 (rules v1.0, effective 2026-09-16): https://www.hejustinsun.com/prize/rules

## Actual release-check improvement

The previous optional local Git check compared only `JSP000612.lean` at the selected commit. The new `--proof-checkout` path checks branch ancestry and the entire pinned file set against the trusted delivery manifest, including the manifest itself. It rejects changed support code even when the proof file is identical. Eighteen new offline unit tests exercise this behavior; the existing nineteen submission tests remain. Local branch records do not certify what is currently visible on GitHub.

## Reproduction caveat preserved

The first attempt to use the standard Lake path as UID 1000 could not create a lock in the freshly restored root-owned dependency cache. That attempt failed before a theorem error; the original log is retained. Ownership of generated `.lake` cache/lock paths was adjusted, without changing source-file bytes, before retrying. The isolated offline entry had already passed.

## Independent checks and priority

Nanoda / Comparator were investigated but NOT successfully run. Two paths through the same Lean kernel, our statement gate, and independent finite-domain C++ calculations are not separate Lean checker implementations. Safe-version certification and an independently signed semantic review remain pending.

References: https://lean-lang.org/doc/reference/latest/ValidatingProofs/ ; https://github.com/ammkrn/nanoda_lib ; https://github.com/leanprover/comparator

The catalogue still shows Lean proof No and Eligible to claim No. This does not establish the absence of competing work. Public issue/PR searches were incomplete; no cross-platform priority conclusion is made. Some filtered search endpoints were inaccessible. No public repository or issue/PR was created by this audit.

Catalogue inspected: https://github.com/TheJustinSunPrize/awards/blob/main/problems/catalog-0601-0700.md

## Additional finite-domain check

The new C++ program exhaustively checks every labelled simple graph on zero through six vertices. It computes chromatic numbers by independent-set subset dynamic programming, tests vertex and edge deletions for criticality, and enumerates every bipartition up to complement. The actual run covered 33,868 labelled graphs and 1,065,510 cuts. This is a finite sanity check, not a substitute for the general theorem. Source and numeric output are included.
