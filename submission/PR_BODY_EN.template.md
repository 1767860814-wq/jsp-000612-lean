## Related problem and requested action

JSP-000612, corresponding to the original chromatic-critical-graph divergence question in Erdős (1981), PDF page 15. Please review the attached **full disproof of that original quantified conjecture**, register the formalization contribution, and arrange the designated verification stage. This is an external-proof submission, not an announcement of eligibility or an award.

The proposed catalogue insertion links the evidence without changing `Current status`, `Lean proof`, or `Eligible to claim` to a stronger status. The proof project and logs are in the external repository, not copied into the awards repository.

## Public proof source

- Repository: PUBLIC_REPOSITORY_URL
- Branch: `PUBLIC_BRANCH`
- Pinned full Git commit: `PUBLIC_COMMIT_SHA`
- Proof at the pinned commit: [JSP000612.lean](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/JSP000612.lean)
- Main file SHA-256: `587ea5a73de02a7b8916c7ab79baa1755c027c011551330553bfbba076aaa368`
- Statement specification: [SubmissionChallenge.lean](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/SubmissionChallenge.lean)
- Scope and definitions: [SEMANTIC_REVIEW.md](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/submission/SEMANTIC_REVIEW.md)
- Current local audit: [FINAL_AUDIT_REPORT.json](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/evidence/current/FINAL_AUDIT_REPORT.json)
- Reproduction entry point: [verify_submission.sh](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/verify_submission.sh)

The source pin, not a moving branch head, identifies the reviewed proof.

## Exact result and source correspondence

For every k≥3 and every size threshold N, there exists a finite ordinary k-critical simple graph of order at least N and a set of at most binomial(k−1,2) **existing unordered edges** whose deletion makes it two-colorable. Criticality quantifies every proper subgraph, including both edge and vertex deletions.

A separate genuine extremal minimum is taken over actual graphs on `Fin n` and actual deletion certificates. Empty families have value infinity; nonempty minima are attained. The construction yields arbitrarily large admissible orders with bounded positive minima. It follows that no chromatic threshold k₀ can make the proposed divergence true for every fixed k>k₀.

Principal declarations (line ranges in the unchanged 800-line proof file):

- `JSP612.jsp000612`: lines 488–502.
- `JSP612.no_chromatic_threshold_for_extremal_divergence`: lines 687–691.
- `JSP612.no_divergence_on_admissible_orders`: lines 727–734.
- `JSP612.bounded_attained_minima`: lines 737–745.

The exact ranges are also recorded in `submission/DECLARATIONS.json`; use that machine-generated index if a displayed range differs.

Original source: https://www.renyi.hu/~p_erdos/1981-16.pdf, page 15. The original question allows an existential threshold k₀, which is explicitly refuted here. A bounded cofinal sequence of counterexamples suffices to refute divergence; witnesses at every exact sufficiently large order are not logically required for this negative answer.

**Scope limit:** this submission does not claim the later sharp universal lower bound or eventual exact formula at every sufficiently large order. It requests recognition of a complete disproof of the original conjecture, not recognition of those stronger refinements. Please decide the catalogue's intended scope explicitly.

## Reproduction

Toolchain: Lean 4.19.0. Mathlib: `c44e0c8ee63ca166450922a373c7409c5d26b00b`; all dependencies are pinned by `lake-manifest.json`.

With that Lean toolchain installed:

```bash
git clone --branch PUBLIC_BRANCH PUBLIC_REPOSITORY_URL jsp612-proof
cd jsp612-proof
git checkout --detach PUBLIC_COMMIT_SHA
lake exe cache get
bash verify_submission.sh
```

An existing restored offline package is supported by `bash verify_submission.sh /absolute/path/to/Lean419_Offline_linux_x86_64`. The local audit exercised restored dependency caches, not fresh internet acquisition of all dependencies. Reproduction writes `build/` and `reproduction/`, leaving the evidence unchanged.

## Executed local checks

The full proof was rebuilt from source with `--trust=0` and warnings-as-errors. All 42 explicit theorems were included in a fresh-environment replay covering 127 theorem roots and 8,000 dependency declarations. The allowable axioms were only `propext`, `Classical.choice`, and `Quot.sound`.

Six principal theorem types were checked against `SubmissionChallenge.lean`, written separately without importing the proposed proof. Nine deliberately invalid candidate variants were rejected (including extra hypotheses, a typeclass hypothesis, altered criticality, a hardcoded extremum, `sorry`, and an extra axiom). A valid proof still passed when unused bad declarations were present. The challenge and the gate are from the submitting project, **not an independent referee** and **not Comparator**.

See the current report for the fresh-checkout reproduction and its precise execution boundaries. The additional 16 finite-graph tests enumerate 115,600 cuts; they are sanity checks, not substitutes for a proof.

## Verification, attribution and priority status

- The local compiler, replay and statement gate use the **same Lean implementation**. Nanoda / Comparator / a second independent checker have **not** been run successfully for this submission. Please arrange the designated independent checks and safe-version review. No reviewer signature or certification is fabricated.
- This is an AI-assisted formalization submission. Historical mathematical credit remains with the established literature, particularly Rödl and Tuza (1985), not with this project as a new mathematical discovery.
- Proposed recipient: `RECIPIENT-JSP-000612-A`, pending written confirmation. No private identity or payment information is supplied.
- Cross-platform priority has not been adjudicated. No claim that nobody else has applied or formalized the result is made.
- Public posting, a repository CI pass, and this local evidence do not themselves certify formal eligibility or an award.

## Additional prize-focused local audit

The proof source is unchanged. Additional checks and their limitations are recorded in [PRIZE_RISK_REVIEW.md](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/submission/PRIZE_RISK_REVIEW.md) and [PRIZE_AUDIT_REPORT.json](PUBLIC_REPOSITORY_URL/blob/PUBLIC_COMMIT_SHA/evidence/prize_review/PRIZE_AUDIT_REPORT.json). Eighteen new release-gate tests supplement the nineteen existing submission-helper tests. The release gate checks full pinned file identity and branch ancestry, not just the proof file. The independent finite-domain C++ sanity check covers 33,868 labelled graphs and 1,065,510 cuts; it is not a Lean checker. Earlier reports retain their original timestamps and are not relabelled as new executions.

## Requested review outcome

Please review the pinned proof and the original-question correspondence; record any required additional checks or scope objections; and determine any later catalogue, candidate or eligibility changes through the official process. No stronger status is requested merely because this PR has been opened.
