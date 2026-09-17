# Proposed statement correspondence for independent review

This is a review aid, not an officially signed statement record.

## 1. Original target

Erdős (1981), author-hosted PDF page 15 (zero-based page 14), proposes a
chromatic threshold k₀ such that for every fixed k>k₀ a uniform edge-deletion
lower bound f(n;k) tends to infinity as the vertex count n increases.
The graphs are k-chromatic-critical and the deletion aims at two-colorability.
Source: https://www.renyi.hu/~p_erdos/1981-16.pdf . The page image was inspected.

The JSP catalogue's short title does not itself specify whether the desired
formalization includes later sharp refinements. The submitter requests review
of the original negative answer and does not represent that this scope has
already been approved.

## 2. Explicit formal objects

| Mathematical object | Lean representation | Relevant safeguard |
| --- | --- | --- |
| Finite simple graph | `SimpleGraph V`, `Finite V`; transported to `Fin n` | No infinite or multi-graph substitute |
| Critical chromatic number k | `IsChromaticCritical G k` | Quantifies all proper `G.Subgraph`, not only induced/vertex-deleted ones |
| Existing unordered edges | `Finset (Sym2 V)` and `↑E ⊆ G.edgeSet` | No duplicate orientations or fictitious deleted edges |
| Bipartite after deletion | `(G.deleteEdges E).Colorable 2` | Actual two-coloring predicate from Mathlib |
| Admissible deletion counts | `attainableCounts k n` | Quantifies actual graphs and actual certificates |
| Extremal minimum | `extremalDeletionNumber k n` | `sInf` of actual counts; empty family = infinity |
| Attained minimum | `extremal_attained`, `bounded_attained_minima` | Minimum is witnessed by an actual certificate |
| Divergence | Natural thresholds; `𝓝 ⊤` on extended naturals | Not `atTop` on the bounded type `ℕ∞` |

The predicates and principal theorem signatures are printed in the source
build log. No numerical answer is hardcoded into the extremal definition.

## 3. Quantifier correspondence

The construction proves

    for every k≥3, for every N, there exists n≥N
    admitting a k-critical graph and a bipartizing deletion set
    of size at most binomial(k−1,2).

Thus for each fixed k≥3 there is a bound depending only on k that is met
beyond every proposed order threshold. This contradicts a lower bound that
must eventually exceed every natural number. It is unnecessary to exhibit a
witness at every single large order to negate an eventual universal bound.

The direct theorem `no_chromatic_threshold_for_extremal_divergence` rules out
an existential threshold k₀. The k≥4 form is also separately refuted in
`originalExtremalConjecture_false`. The result is not merely one counterexample
at k=3 or a single finite value of n.

`no_eventually_diverging_uniform_lower_bound` allows the candidate lower
bound to apply only after an arbitrary order threshold.
`no_divergence_on_admissible_orders` restricts the proposed bound to graph
orders at which an actual certificate exists. Hence the negative result is
not caused by empty minima or nonexistence at exceptional small orders.

## 4. Why critical-subgraph extraction preserves unbounded order

The raw graph is non-q-colorable but (q+1)-colorable, where q=k−1.
Removing any path vertex admits a q-coloring. Therefore every non-q-colorable
subgraph contains all n+1 designated path vertices. Choosing a minimal
non-q-colorable subgraph cannot shrink away the growing path. The extraction
is minimal under both edge and vertex inclusion.

After extraction, delete only its actual palette edges. The remaining graph
has a displayed bipartition. The deletion bound is binomial(q,2), independent
of the path length. The proof is an existence proof; efficient constructive
extraction for large parameters is not asserted.

## 5. Scope boundaries and requested decision

Not formalized here: the sharp lower bound for every sufficiently large
critical graph, or the eventual exact extremal formula at every large order.
These are stronger historical results than negating the original conjecture.
See Rödl–Tuza (1985) as cited by the catalogue and the introduction of
Kostochka–Reiniger (2015):
https://kostochk.web.illinois.edu/docs/2016/ejc15-r.pdf .

Please independently assess (a) the source-to-statement match and all local
definitions, and (b) whether a full formal disproof of the original divergence
assertion satisfies JSP-000612's formalization scope. Do not mark the stronger
sharp equality theorem as completed on the basis of this submission.

No independent reviewer names, signatures, safe-version certifications,
first-public-priority conclusions, or award decisions are supplied here.


## Current submission-stage clarification (2026-09-17)

The original 1981 paper's PDF page 15 was inspected again. The existential chromatic threshold k₀ is covered by `no_chromatic_threshold_for_extremal_divergence`; the proof is not relying solely on the k=4 specialization. A cofinal bounded family disproves a limit to infinity, even though it does not determine the extremal function at every large order.

`SubmissionChallenge.lean` separately states the relevant predicates and complete theorem types without importing `JSP000612.lean`. Six actual theorem types are compared definitionally and their dependency axioms audited. This addresses accidental extra hypotheses or altered definitions at the code-interface level. Both this document and the challenge are produced by the submitting project; they are not an independently signed human review and do not determine the official catalogue's scope.
