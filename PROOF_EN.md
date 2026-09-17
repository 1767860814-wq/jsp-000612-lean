# JSP-000612: formal counterexamples to an order-diverging bipartization bound

## 1. Exact scope

This package supplies a Lean 4.19.0 proof of the following statement:

> For every integer k ≥ 3 and every integer N ≥ 0, there exist a finite simple graph G and a set E of existing edges of G such that G has at least N vertices, G is k-chromatic-critical, |E| ≤ binomial(k−1,2), and G−E is 2-colorable.

Here **k-chromatic-critical** means χ(G)=k and **every proper subgraph**, including subgraphs obtained by deleting edges or vertices, has chromatic number strictly below k. It does not mean only vertex-critical or only edge-critical.

The primary Lean declaration is `JSP612.jsp000612`. It uses Mathlib's `SimpleGraph`, `Subgraph`, `chromaticNumber`, `deleteEdges`, and `Colorable`. The locally defined criticality predicate is printed in the build log so that its meaning is directly inspectable.

This answers negatively the proposed existence of a uniform bipartizing-edge lower bound tending to infinity with vertex count at a fixed chromatic number. A separate theorem formalizes that negative conclusion using `Filter.Tendsto f Filter.atTop Filter.atTop`; a strengthened theorem allows the proposed bound to start only beyond an arbitrary graph-order threshold.

This package **does not prove the matching optimal lower bound** for all sufficiently large critical graphs. It also does not prove that an example exists at **every exact sufficiently large order**. Arbitrarily large orders suffice to refute a bound tending to infinity. The mathematical negative answer is historically due to Rödl and Tuza; no new mathematical priority or first-public-formalization claim is made here.

## 2. Construction

Write q=k−1, so q≥2. Let n≥0 be a length parameter. Define four disjoint vertex families:

* Palette vertices A_i, for 0≤i<q.
* Path vertices X_i, for 0≤i≤n.
* Link vertices Y_j, for 0≤j<n.
* Blocker vertices B_i, for 0≤i<q.

The Lean inductive type `Vertex q n` makes these families disjoint by construction. The edges are exactly:

1. A_i A_j whenever i≠j.
2. A_i B_j whenever i≠j.
3. A_i Y_j whenever i≥2.
4. X_j Y_j and X_(j+1) Y_j, for 0≤j<n.
5. X_0 B_0 and X_n B_1.
6. X_i B_j for every i and every j≥2.

Edges are undirected; there are no loops and no additional edges. The raw graph is denoted `graph q n` in Lean. We do **not** assume that this raw graph is already critical.

## 3. It is not q-colorable

Assume a proper q-coloring. Because the palette is a clique of order q, its q colors are distinct. Relabeling the colors by a permutation, assume that A_i has color i.

Each B_j is adjacent to every palette vertex except A_j. Hence B_j is forced to have color j.

Every X_i is adjacent to all B_j with j≥2, and every Y_j is adjacent to all A_i with i≥2. Consequently all path and link vertices use only colors 0 and 1.

Since Y_j is adjacent to both X_j and X_(j+1), those two path vertices must have the same color. Induction along the chain shows that all X_i have the same color. But X_0 is adjacent to B_0 and must avoid color 0, whereas X_n is adjacent to B_1 and must avoid color 1. This contradicts the two-color restriction. The argument includes n=0.

Lean lemmas: `normalized_coloring`, `blocker_color`, `path_color_lt_two`, `link_color_lt_two`, `successive_path_colors`, `not_colorable`.

An explicit (q+1)-coloring also exists: color A_i and B_i by i, all X_i by the additional color q, and all Y_j by 0. Thus the raw graph has exactly q+1 as its chromatic number, although we use a critical subgraph in the final theorem.

Lean lemmas: `upperColor_valid`, `colorable_succ`.

## 4. Every non-q-colorable subgraph contains the whole path

Fix a path vertex X_t. On the remaining vertices, use this q-coloring:

* A_i and B_i receive color i.
* X_i receives color 1 for i<t and color 0 for i>t.
* Y_j receives color 0 for j<t and color 1 for j≥t.

The total Lean coloring function also assigns a value to X_t, but its validity theorem explicitly excludes that vertex from both endpoints of an edge. The only potential color transition occurs at the deleted X_t, so every remaining edge is properly colored. Endpoint blocker constraints are satisfied as well: X_0, when present, has color 1; X_n, when present, has color 0.

Therefore any subgraph omitting X_t is q-colorable. By contraposition, every non-q-colorable subgraph contains every X_t. It consequently has at least n+1 vertices.

Lean lemmas: `puncturedColor_valid`, `path_mem_of_not_colorable`, `order_lower_bound`.

## 5. Extract a genuine critical subgraph without losing the size bound

The finite set of subgraphs of the raw graph contains a non-q-colorable member, namely the whole graph. Choose a minimal such subgraph H under ordinary subgraph inclusion.

The (q+1)-coloring of the raw graph restricts to H. H is not q-colorable by its choice. Every proper subgraph of H is q-colorable by minimality. The Lean proof explicitly maps a subgraph of H back to a subgraph of the original graph and proves that a non-q-colorable proper subgraph would contradict minimality. Both edge and vertex inclusion are handled.

Thus H is (q+1)-critical. Section 4 ensures that H still contains all n+1 path vertices. Minimal-subgraph selection is classical and noncomputable; the existence proof does not claim to execute an efficient algorithm producing a critical core for arbitrary huge input n.

Lean lemmas: `exists_critical_subgraph`, `IsCriticalSuccessor.chromaticNumber`, and the criticality part of `jsp000612`.

## 6. A bounded deletion set makes H bipartite

Partition the vertices of the raw graph into:

* one side: all palette and path vertices;
* the other side: all blocker and link vertices.

Inspection of the explicitly defined adjacency relation shows that the only edges within a side are palette-clique edges. There are at most binomial(q,2) such edges. Delete those palette edges that actually occur in H.

The Lean deletion set is a `Finset (Sym2 H.verts)`, so its elements are unordered pairs. It is filtered from H's actual edge set. The proof separately verifies that the deletion set is a subset of existing edges and bounds its cardinality by an injection into the palette-clique edge set; it does not count directed edges twice or count nonedges.

The displayed two-side function then supplies a `Coloring Bool` of the graph after edge deletion. Mathlib converts that coloring to `Colorable 2`.

Lean lemmas: `paletteEdges_card_le`, `same_side_edge`, `deletionEdges_subset`, `deletionEdges_card_le`, `deletion_colorable_two`.

## 7. Arbitrary order and the negated asymptotic statement

For a requested lower bound N on the number of vertices, choose the raw construction with n=N and then take its critical subgraph H. H has at least N+1 vertices, hence at least N. The edge-deletion bound depends on q alone, not on n or N. This proves the displayed theorem in Section 1.

Suppose a function f on vertex counts tends to infinity and is a lower bound on every bipartizing deletion set in every finite (q+1)-critical graph. Then, for all sufficiently large m, f(m)≥binomial(q,2)+1. Choose a member H of the constructed family whose order m is beyond that threshold. Its displayed deletion set has size at most binomial(q,2), a contradiction.

The strengthened Lean theorem takes the maximum of this threshold and any additional graph-order threshold allowed for the proposed lower bound. A further theorem rules out rescuing the original conjecture by requiring the fixed chromatic number to exceed some threshold.

## 8. Verification and remaining review questions

`JSP000612.lean` is a single source file: it imports only the stated Mathlib modules, not any local precompiled proof module. `verify_offline.sh` rebuilds it after deleting its previous local `.olean` and `.ilean`. The recorded final run uses Lean's `--trust=0` and treats warnings as errors. The script does not invoke Lake or access the network.

The principal theorems' printed axiom dependencies are the standard `propext`, `Classical.choice`, and `Quot.sound`. In particular, there is no `sorryAx` or custom assumption asserting the sought graph-theoretic result.

Kernel checking validates the formal declarations relative to the stated foundations and definitions. It does not itself decide the prize committee's intended scope, public priority, authorship allocation, or payment. The correspondence between the original divergence conjecture and this theorem should be reviewed by a human reader. If the prize requires the full sharp extremal theorem rather than the negative answer to the original conjecture, the missing optimal lower bound remains additional work.


## Extension: a faithful extremal function

Let S(k,n) be the set of natural numbers m for which there are a graph G on
Fin n and a finite set E of its existing edges such that G is k-critical,
|E|=m, and G minus E is two-colorable. Criticality is exactly the Mathlib
chromatic-number condition on every proper subgraph, including vertex deletion.
Define f(k,n)=inf { (m : extended natural) : m in S(k,n) }. The infimum of the
empty family is infinity. No numerical answer is built into this definition.

Graph isomorphism preserves ordinary criticality. The transport proof pulls
proper subgraphs back across the isomorphism, proves they remain proper, and
transports their colorings. It also transports a deletion certificate by an
injective Sym2 map, preserving its cardinality and the resulting two-coloring.
Thus the constructed finite graphs can be relabelled on Fin n without changing
criticality or deletion counts.

If S(k,n) is nonempty, well-ordering of the naturals gives a least m in S(k,n).
Its cast is exactly f(k,n), by the lower-bound and upper-bound properties of an
infimum. This proves attainment by an actual graph and actual deletion set.
For k >= 3 any such m is positive: zero deletions would make G two-colorable,
in contradiction with chromatic number k. If n < k the family is empty,
since every graph on n vertices is n-colorable. These facts check that the
minimisation does not exploit a zero default or a fictitious graph.

For each k >= 3 and N, the construction and relabelling give an admissible
n >= N with f(k,n) <= choose(k-1,2). The minimum is attained there and positive.
If f(k,n) tended to infinity, it would eventually exceed choose(k-1,2), a
contradiction. The proof still works when the asserted limit only quantifies
orders that actually admit a k-critical graph.

The topological theorem uses the neighbourhood filter of infinity in the
extended naturals, NOT the atTop filter on that bounded ordered type. The
latter would mean eventual equality to infinity and would be the wrong limit.
ENat.tendsto_nhds_top_iff_natCast_lt connects the selected topology to the
usual natural-number threshold formulation.

### Why a cofinal sequence is sufficient

A limit at infinity asserts a bound at every sufficiently large relevant
order. Exhibiting a bounded witness beyond each proposed threshold disproves
that assertion. Neither a matching universal lower bound nor examples at
every exact large order are necessary for this negative answer. Those are
separate, stronger historical results and are not claimed in this package.
