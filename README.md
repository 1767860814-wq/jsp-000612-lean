# JSP-000612 — original-conjecture disproof in Lean

**Prepared for an official review PR, not an accepted award claim.** This project gives a complete negative answer to the original quantified divergence question in Erdős (1981), PDF page 15. It does not assert the later sharp universal lower bound or an eventual exact formula at every sufficiently large order. The catalogue's scope and the contribution's eligibility are for the reviewers to decide.

Chinese submission instructions: [提交步骤_CN.md](提交步骤_CN.md).

## Proved statement

For every integer k ≥ 3 and every threshold N, there is a finite ordinary k-critical simple graph on at least N vertices which becomes two-colorable after deleting at most binomial(k−1, 2) of its existing unordered edges. Criticality covers **every proper subgraph**, not just induced vertex-deleted graphs. Taking a genuine extremal minimum over graphs on `Fin n` yields bounded positive attained minima at arbitrarily large admissible orders. Thus no threshold k₀ makes the original divergence assertion true for all fixed k > k₀.

The unchanged main source is `JSP000612.lean` (800 lines, 42 explicit theorems), SHA-256:

`587ea5a73de02a7b8916c7ab79baa1755c027c011551330553bfbba076aaa368`

Proof explanation: [PROOF_EN.md](PROOF_EN.md). Original-question correspondence and limits: [submission/SEMANTIC_REVIEW.md](submission/SEMANTIC_REVIEW.md). Theorem line index: [submission/DECLARATIONS.json](submission/DECLARATIONS.json).

## Reproduce

Use Lean 4.19.0 and the `lake-manifest.json` dependency pins (Mathlib `c44e0c8ee63ca166450922a373c7409c5d26b00b`). On a network-enabled computer with the pinned Lean toolchain installed:

```bash
lake exe cache get
bash verify_submission.sh
```

With the seven-part offline environment already restored:

```bash
bash verify_submission.sh /absolute/path/to/Lean419_Offline_linux_x86_64
```

The offline package is an optional dependency source and is **not** included in this submission. Do not upload that multi-gigabyte environment to the awards repository. This audit used restored caches; fresh acquisition of internet dependencies was not executed here. The current audit report distinguishes local checkout reproduction from a future public-repository checkout.

The verification entry point checks the delivery manifest, compiles the original proof from source with trust level zero and warnings-as-errors, replays the relevant transitive declarations in a fresh Lean environment, checks six theorem types against the separately written specification, runs nine rejecting controls and a positive contamination control, runs 16 finite graph checks and tests the PR preparation helper. Output goes to ignored `build/` and `reproduction/`, not into submitted evidence.

`SubmissionChallenge.lean` imports Mathlib but not the proposed proof. Its specification and `GateSupport.lean` are authored by the submitting project. This is exact-type/axiom checking with the same Lean implementation; it is **not Comparator, Nanoda, a second independent implementation, or an independent signed semantic review**. Files in `tests/` deliberately contain incorrect candidates, an extra axiom and `sorry` so that rejection is tested; none is imported by the main proof.

Current evidence: [evidence/current/FINAL_AUDIT_REPORT.json](evidence/current/FINAL_AUDIT_REPORT.json). Older supplied evidence is preserved separately in `history/previous_submission.zip` for provenance, not relabelled as a current execution.

## Prepare a public submission

1. Publish the project files in your own public proof repository. Keep source files at its root. Record its branch and the complete 40-character commit containing this project.
2. Generate the English PR body and the targeted catalogue paragraph:

```bash
python3 tools/prepare_submission.py \
  --repository https://github.com/YOUR-ACCOUNT/YOUR-PROOF-REPOSITORY \
  --branch main \
  --commit YOUR_40_CHARACTER_GIT_COMMIT
```

These are placeholders; use actual public values. The generated files are under `reproduction/submission/`. The helper validates syntax, does not post, and does not assert that the public repository exists. Optional `--proof-checkout PATH` verifies the proof hash at that commit in a local checkout. Optional `--catalogue PATH` reads an existing official catalogue and produces a patch without changing its status fields or modifying the input file.

3. In a fork of the official awards repository, add the rendered evidence paragraph inside the existing JSP-000612 entry of `problems/catalog-0601-0700.md`, before the next problem. Open a PR using the rendered title and body, adapting them to any required default template fields shown by GitHub. The public proof and execution logs stay in the external proof repository. Do not declare `Lean proof: Yes`, eligibility or a recipient's confirmed identity merely because local tests pass. A recipient-recommendation Issue is not a substitute for the rules' PR workflow.

The official rules describe online submission followed by designated offline verification and PR finalization. Independent checking, safe-version review, signed semantic correspondence, public-priority adjudication and identity/award decisions remain pending. Publishing source or opening a PR does not itself resolve them.

Sources consulted on 2026-09-17:
- https://www.hejustinsun.com/prize/rules
- https://github.com/TheJustinSunPrize/awards/blob/main/CONTRIBUTING.md
- https://github.com/TheJustinSunPrize/awards/blob/main/docs/records.md
- https://github.com/TheJustinSunPrize/awards/blob/main/docs/verification.md
- https://lean-lang.org/doc/reference/latest/ValidatingProofs/

Historical mathematical credit remains with the established literature, particularly Rödl and Tuza (1985). This is an AI-assisted formalization, not a claim to a new mathematical solution, first-public priority or an approved prize.

## Pinned release gate (additional local safeguard)

From the unmodified delivered project, `python3 tools/prepare_submission.py --repository PUBLIC_REPOSITORY_URL --branch PUBLIC_BRANCH --commit PUBLIC_COMMIT_SHA --proof-checkout /absolute/path/to/checkout` compares the **entire pinned Git snapshot**, including its manifest, against this delivery. It also checks that the named local branch (or locally recorded `origin` tracking branch) contains the selected commit. Missing or extra files, changed support code, symbolic links, and Git replacement-object tricks are rejected. Public availability, public timestamp, independent proof checking and prize recognition are not established by this local check.

The original proof file is unchanged. Additional release-gate unit tests are run by `verify_submission.sh`.
