/-
JSP-000612 / Erdős 744: genuine extremal-minimum nondivergence.
This file includes the full construction, ordinary subgraph criticality,
labelled-graph transport, actual deletion-count minimisation, attainment,
empty-family and positivity checks, and the original conjecture's negation.
It does NOT assert the sharp universal Rödl–Tuza lower bound or eventual
exact equality at every sufficiently large graph order.
No public-priority or prize-acceptance claim is made.
-/
import Mathlib.Combinatorics.SimpleGraph.Coloring
import Mathlib.Combinatorics.SimpleGraph.Subgraph
import Mathlib.Combinatorics.SimpleGraph.DeleteEdges
import Mathlib.Tactic
import Mathlib.Topology.Instances.ENat

/-
JSP-000612: a formal counterexample to the diverging-bipartization conjecture.
Prepared in this conversation on 2026-09-17. Lean 4.19.0 / Mathlib v4.19.0.

Scope: arbitrarily large k-critical graphs with at most choose(k-1,2)
bipartizing edge deletions, for every k >= 3; and the negation of every
order-diverging uniform deletion lower bound. NOT the separate optimality
lower-bound theorem of Rödl and Tuza. No claim of new mathematical priority,
first formalization, public acceptance, or prize entitlement is made.

Historical result: V. Rödl and Zs. Tuza, "On color critical graphs",
J. Combin. Theory Ser. B 38 (1985), 204-213,
DOI: 10.1016/0095-8956(85)90066-8.
See SOURCES.md and PROOF_EN.md for the statement-to-source crosswalk.
-/


/-!
JSP-000612 research: a palette-and-chain construction.
Parameter q is one less than the chromatic number; n controls chain length.
The mathematical target is the negation of the unbounded-bipartization
conjecture for color-critical graphs, not the sharp lower-bound theorem.
-/
namespace JSP612

inductive Vertex (q n : ℕ) where
  | palette : Fin q → Vertex q n
  | path : Fin (n + 1) → Vertex q n
  | link : Fin n → Vertex q n
  | blocker : Fin q → Vertex q n
  deriving DecidableEq, Fintype

open Vertex SimpleGraph

/-- The only edges within a bipartition class will be palette-clique edges. -/
def adjacent {q n : ℕ} : Vertex q n → Vertex q n → Prop
  | .palette i, .palette j => i ≠ j
  | .palette i, .blocker j => i ≠ j
  | .blocker j, .palette i => i ≠ j
  | .palette i, .link _ => 2 ≤ i.val
  | .link _, .palette i => 2 ≤ i.val
  | .path i, .link j => i.val = j.val ∨ i.val = j.val + 1
  | .link j, .path i => i.val = j.val ∨ i.val = j.val + 1
  | .path i, .blocker j =>
      (j.val = 0 ∧ i.val = 0) ∨ (j.val = 1 ∧ i.val = n) ∨ 2 ≤ j.val
  | .blocker j, .path i =>
      (j.val = 0 ∧ i.val = 0) ∨ (j.val = 1 ∧ i.val = n) ∨ 2 ≤ j.val
  | _, _ => False

instance {q n : ℕ} : DecidableRel (@adjacent q n) := by
  intro v w
  cases v <;> cases w <;> simp only [adjacent] <;> infer_instance

def graph (q n : ℕ) : SimpleGraph (Vertex q n) where
  Adj := adjacent
  symm := by
    intro v w
    cases v <;> cases w <;> simp [adjacent, ne_comm]
  loopless := by
    intro v
    cases v <;> simp [adjacent]

instance {q n : ℕ} : DecidableRel (graph q n).Adj :=
  inferInstanceAs (DecidableRel (@adjacent q n))

/-- Normalizing the colors on the palette clique loses no colorings. -/
theorem normalized_coloring {q n : ℕ} (C : (graph q n).Coloring (Fin q)) :
    ∃ D : (graph q n).Coloring (Fin q), ∀ i, D (palette i) = i := by
  have hi : Function.Injective (fun i : Fin q => C (palette i)) := by
    intro i j he
    by_contra hn
    exact C.valid (show (graph q n).Adj (palette i) (palette j) from hn) he
  let e : Fin q ≃ Fin q := Equiv.ofBijective _
    ⟨hi, Finite.surjective_of_injective hi⟩
  let D : (graph q n).Coloring (Fin q) :=
    Coloring.mk (fun v => e.symm (C v)) (by
      intro v w h
      exact fun he => C.valid h (e.symm.injective he))
  refine ⟨D, ?_⟩
  intro i
  change e.symm (e i) = i
  exact e.symm_apply_apply i

/-- Every blocker is forced to take its corresponding palette color. -/
theorem blocker_color {q n : ℕ} (C : (graph q n).Coloring (Fin q))
    (hp : ∀ i, C (palette i) = i) (j : Fin q) : C (blocker j) = j := by
  by_contra h
  have hc := C.valid
    (show (graph q n).Adj (palette (C (blocker j))) (blocker j) from h)
  exact hc (hp _)

/-- All path vertices are restricted to the first two palette colors. -/
theorem path_color_lt_two {q n : ℕ} (C : (graph q n).Coloring (Fin q))
    (hp : ∀ i, C (palette i) = i) (i : Fin (n + 1)) :
    (C (path i)).val < 2 := by
  by_contra h
  have hj : 2 ≤ (C (path i)).val := by omega
  have ha : (graph q n).Adj (path i) (blocker (C (path i))) :=
    Or.inr (Or.inr hj)
  exact C.valid ha (blocker_color C hp _).symm

/-- All chain-link vertices are also restricted to the first two colors. -/
theorem link_color_lt_two {q n : ℕ} (C : (graph q n).Coloring (Fin q))
    (hp : ∀ i, C (palette i) = i) (i : Fin n) :
    (C (link i)).val < 2 := by
  by_contra h
  have ha : (graph q n).Adj (palette (C (link i))) (link i) := by
    change 2 ≤ (C (link i)).val
    omega
  exact C.valid ha (hp _)

/-- A link forces the two neighboring path vertices to have equal colors. -/
theorem successive_path_colors {q n : ℕ} (C : (graph q n).Coloring (Fin q))
    (hp : ∀ i, C (palette i) = i) (i : Fin n) :
    C (path i.castSucc) = C (path i.succ) := by
  have h0 := path_color_lt_two C hp i.castSucc
  have h1 := path_color_lt_two C hp i.succ
  have h2 := link_color_lt_two C hp i
  have hn0 : (C (path i.castSucc)).val ≠ (C (link i)).val := by
    intro he
    exact C.valid (show (graph q n).Adj (path i.castSucc) (link i)
      from Or.inl rfl) (Fin.ext he)
  have hn1 : (C (path i.succ)).val ≠ (C (link i)).val := by
    intro he
    exact C.valid (show (graph q n).Adj (path i.succ) (link i)
      from Or.inr rfl) (Fin.ext he)
  apply Fin.ext
  omega

/-- The full graph cannot be colored with q colors. -/
theorem not_colorable {q n : ℕ} (hq : 2 ≤ q) : ¬ (graph q n).Colorable q := by
  rintro ⟨C⟩
  obtain ⟨D, hp⟩ := normalized_coloring C
  have hall : ∀ i : Fin (n + 1), D (path i) = D (path 0) := by
    intro i
    induction i using Fin.induction with
    | zero => rfl
    | succ i ih => exact (successive_path_colors D hp i).symm.trans ih
  let z : Fin q := ⟨0, by omega⟩
  let o : Fin q := ⟨1, by omega⟩
  have hleft : (D (path (0 : Fin (n + 1)))).val ≠ 0 := by
    intro he
    have ha : (graph q n).Adj (path 0) (blocker z) :=
      Or.inl ⟨rfl, rfl⟩
    apply D.valid ha
    rw [blocker_color D hp z]
    exact Fin.ext he
  have hright : (D (path (Fin.last n))).val ≠ 1 := by
    intro he
    have ha : (graph q n).Adj (path (Fin.last n)) (blocker o) :=
      Or.inr (Or.inl ⟨rfl, rfl⟩)
    apply D.valid ha
    rw [blocker_color D hp o]
    exact Fin.ext he
  have heq := congrArg Fin.val (hall (Fin.last n))
  have hsmall := path_color_lt_two D hp (0 : Fin (n + 1))
  omega

/-- An explicit (q+1)-coloring; color q is used on the path vertices. -/
def upperColor {q n : ℕ} : Vertex q n → Fin (q + 1)
  | .palette i => i.castSucc
  | .blocker i => i.castSucc
  | .path _ => Fin.last q
  | .link _ => 0

theorem upperColor_valid {q n : ℕ} (hq : 2 ≤ q) :
    ∀ {v w : Vertex q n}, (graph q n).Adj v w → upperColor v ≠ upperColor w := by
  intro v w ha he
  have he' := congrArg Fin.val he
  cases v <;> cases w <;>
    simp only [graph, adjacent, upperColor, Fin.coe_castSucc, Fin.val_last,
      Fin.val_zero] at ha he' <;>
    try contradiction
  all_goals try { apply ha; exact Fin.ext he' }
  all_goals omega

theorem colorable_succ {q n : ℕ} (hq : 2 ≤ q) : (graph q n).Colorable (q + 1) :=
  ⟨Coloring.mk upperColor (upperColor_valid hq)⟩

/-- If path vertex t is missing, the path can change color at t. -/
def puncturedColor {q n : ℕ} (hq : 2 ≤ q) (t : Fin (n + 1)) : Vertex q n → Fin q
  | .palette i => i
  | .blocker i => i
  | .path i => if i.val < t.val then ⟨1, by omega⟩ else ⟨0, by omega⟩
  | .link i => if i.val < t.val then ⟨0, by omega⟩ else ⟨1, by omega⟩

/-- This coloring is proper on every subgraph omitting path vertex t. -/
theorem puncturedColor_valid {q n : ℕ} (hq : 2 ≤ q) (t : Fin (n + 1))
    {v w : Vertex q n} (hv : v ≠ path t) (hw : w ≠ path t)
    (ha : (graph q n).Adj v w) : puncturedColor hq t v ≠ puncturedColor hq t w := by
  intro he
  have he' := congrArg Fin.val he
  cases v <;> cases w <;>
    simp_all only [graph, adjacent, puncturedColor, ne_eq,
      Vertex.path.injEq, Fin.ext_iff]
  all_goals split_ifs at * <;> simp_all <;>
    try simp only [Fin.ext_iff, Fin.val_zero] at *
  all_goals omega

/-- Any subgraph that is not q-colorable has to contain the entire path. -/
theorem path_mem_of_not_colorable {q n : ℕ} (hq : 2 ≤ q)
    (H : (graph q n).Subgraph) (hH : ¬ H.coe.Colorable q) (t : Fin (n + 1)) :
    path t ∈ H.verts := by
  by_contra ht
  apply hH
  refine ⟨Coloring.mk (fun v : H.verts => puncturedColor hq t v.val) ?_⟩
  intro v w ha
  apply puncturedColor_valid hq t
  · exact fun he => ht (he ▸ v.property)
  · exact fun he => ht (he ▸ w.property)
  · exact H.adj_sub ha

end JSP612


namespace JSP612
open SimpleGraph

/-- Ordinary subgraph-criticality, with chromatic number q+1.
Every proper subgraph, not just every vertex-deleted graph, is q-colorable. -/
def IsCriticalSuccessor {V : Type*} (G : SimpleGraph V) (q : ℕ) : Prop :=
  ¬ G.Colorable q ∧ G.Colorable (q + 1) ∧
    ∀ J : G.Subgraph, J ≠ ⊤ → J.coe.Colorable q

/-- Finite minimal-subgraph extraction, including both edge and vertex minimality. -/
theorem exists_critical_subgraph {V : Type*} [Finite V] (G : SimpleGraph V)
    (q : ℕ) (hnon : ¬ G.Colorable q) (hupper : G.Colorable (q + 1)) :
    ∃ H : G.Subgraph, IsCriticalSuccessor H.coe q := by
  classical
  let s : Set G.Subgraph := {H | ¬ H.coe.Colorable q}
  have htop : (⊤ : G.Subgraph) ∈ s := by
    intro hc
    obtain ⟨C⟩ := hc
    exact hnon ⟨C.comp (Subgraph.topIso (G := G)).symm.toHom⟩
  obtain ⟨H, _, hmin⟩ := s.toFinite.exists_minimal_le htop
  refine ⟨H, hmin.1, ?_, ?_⟩
  · obtain ⟨C⟩ := hupper
    exact ⟨C.comp H.hom⟩
  · intro J hJproper
    by_contra hJnon
    let K : G.Subgraph := J.map H.hom
    have hKH : K ≤ H := by
      constructor
      · rintro x ⟨y, hy, rfl⟩
        exact y.property
      · rintro x y ⟨u, v, huv, rfl, rfl⟩
        exact J.adj_sub huv
    have hKnon : ¬ K.coe.Colorable q := by
      rintro ⟨C⟩
      let f : J.coe →g K.coe :=
        { toFun := fun x => ⟨x.val.val, ⟨x.val, x.property, rfl⟩⟩
          map_rel' := by
            intro x y hxy
            exact ⟨x.val, y.val, hxy, rfl, rfl⟩ }
      exact hJnon ⟨C.comp f⟩
    have hHK : H ≤ K := hmin.2 hKnon hKH
    apply hJproper
    apply top_unique
    constructor
    · intro x hx
      obtain ⟨y, hy, hyx⟩ := hHK.1 x.property
      have he : y = x := Subtype.ext hyx
      simpa [he] using hy
    · intro x y hxy
      obtain ⟨a, b, hab, hax, hby⟩ := hHK.2 hxy
      have ha : a = x := Subtype.ext hax
      have hb : b = y := Subtype.ext hby
      simpa [ha, hb] using hab

/-- The critical subgraph cannot lose any of the n+1 path vertices. -/
theorem order_lower_bound {q n : ℕ} (hq : 2 ≤ q)
    (H : (graph q n).Subgraph) (hH : ¬ H.coe.Colorable q) :
    n + 1 ≤ Nat.card H.verts := by
  let f : Fin (n + 1) → H.verts :=
    fun i => ⟨Vertex.path i, path_mem_of_not_colorable hq H hH i⟩
  have hi : Function.Injective f := by
    intro i j he
    have hv := congrArg Subtype.val he
    exact Vertex.path.inj hv
  simpa using Nat.card_le_card_of_injective f hi

end JSP612


namespace JSP612
open Vertex SimpleGraph

/-- The palette clique is the only obstruction to the displayed bipartition. -/
noncomputable def paletteEdges (q n : ℕ) : Finset (Sym2 (Vertex q n)) := by
  classical
  exact (⊤ : SimpleGraph (Fin q)).edgeFinset.image (Sym2.map Vertex.palette)

theorem paletteEdges_card_le (q n : ℕ) : (paletteEdges q n).card ≤ q.choose 2 := by
  classical
  calc
    (paletteEdges q n).card ≤ (⊤ : SimpleGraph (Fin q)).edgeFinset.card :=
      Finset.card_image_le
    _ = q.choose 2 := by
      simpa only [Fintype.card_fin] using
        (card_edgeFinset_top_eq_card_choose_two (V := Fin q))

theorem palette_pair_mem {q n : ℕ} {i j : Fin q} (hij : i ≠ j) :
    s(palette i, palette j) ∈ paletteEdges q n := by
  classical
  apply Finset.mem_image.mpr
  refine ⟨s(i, j), ?_, rfl⟩
  simpa using hij

/-- Two displayed bipartition classes: palette/path and blocker/link. -/
def side {q n : ℕ} : Vertex q n → Bool
  | .palette _ => false
  | .path _ => false
  | .blocker _ => true
  | .link _ => true

/-- Every monochromatic edge is one of the bounded number of palette edges. -/
theorem same_side_edge {q n : ℕ} {v w : Vertex q n}
    (ha : (graph q n).Adj v w) (he : side v = side w) :
    s(v, w) ∈ paletteEdges q n := by
  cases v <;> cases w <;> simp only [side, Bool.false_eq_true, Bool.true_eq_false] at he
  all_goals try contradiction
  all_goals simp only [graph, adjacent] at ha
  exact palette_pair_mem ha

/-- The actual edges to delete in an arbitrary subgraph of the construction. -/
noncomputable def deletionEdges {q n : ℕ} (H : (graph q n).Subgraph) :
    Finset (Sym2 H.verts) := by
  classical
  exact H.coe.edgeFinset.filter
    (fun e => Sym2.map Subtype.val e ∈ paletteEdges q n)

theorem deletionEdges_card_le {q n : ℕ} (H : (graph q n).Subgraph) :
    (deletionEdges H).card ≤ q.choose 2 := by
  classical
  apply le_trans _ (paletteEdges_card_le q n)
  apply Finset.card_le_card_of_injOn (Sym2.map Subtype.val)
  · intro e he
    exact (Finset.mem_filter.mp he).2
  · exact (Sym2.map.injective Subtype.val_injective).injOn

/-- The deletion set consists of existing edges, not fictitious pairs. -/
theorem deletionEdges_subset {q n : ℕ} (H : (graph q n).Subgraph) :
    (deletionEdges H : Set (Sym2 H.verts)) ⊆ H.coe.edgeSet := by
  classical
  intro e he
  exact mem_edgeFinset.mp (Finset.mem_filter.mp he).1

/-- After deleting at most choose(q,2) edges, every such subgraph is bipartite. -/
theorem deletion_colorable_two {q n : ℕ} (H : (graph q n).Subgraph) :
    (H.coe.deleteEdges (deletionEdges H)).Colorable 2 := by
  classical
  let C : (H.coe.deleteEdges (deletionEdges H)).Coloring Bool :=
    Coloring.mk (fun v => side v.val) (by
      intro v w ha he
      obtain ⟨hH, hn⟩ := deleteEdges_adj.mp ha
      apply hn
      apply Finset.mem_filter.mpr
      constructor
      · exact mem_edgeFinset.mpr (H.coe.mem_edgeSet.mpr hH)
      · exact same_side_edge (H.adj_sub hH) he)
  simpa using C.colorable

end JSP612


/-!
A formal negative answer to the unbounded-bipartization conjecture described
by Erdős (1981), associated with JSP-000612. This file does not formalize
the separate Rödl–Tuza optimal lower bound for all sufficiently large
critical graphs. All proper subgraphs are quantified in criticality.
-/
namespace JSP612
open SimpleGraph

/-- The criticality predicate has exactly the claimed chromatic number. -/
theorem IsCriticalSuccessor.chromaticNumber {V : Type*} {G : SimpleGraph V}
    {q : ℕ} (hG : IsCriticalSuccessor G q) :
    G.chromaticNumber = ((q + 1 : ℕ) : ℕ∞) := by
  apply le_antisymm hG.2.1.chromaticNumber_le
  have hlt : (q : ℕ∞) < G.chromaticNumber :=
    lt_of_not_ge (fun h => hG.1 (chromaticNumber_le_iff_colorable.mp h))
  have hle := (ENat.add_one_le_iff (ENat.coe_ne_top q)).mpr hlt
  simpa only [Nat.cast_add, Nat.cast_one] using hle

/-- Main constructive existence theorem: for each q≥2 and every size target N,
there is a finite (q+1)-critical graph with at least N vertices that becomes
bipartite after deletion of at most choose(q,2) of its existing edges. -/
theorem arbitrarily_large_critical_bipartizable (q : ℕ) (hq : 2 ≤ q) (N : ℕ) :
    ∃ (V : Type) (G : SimpleGraph V) (E : Finset (Sym2 V)),
      Finite V ∧ N ≤ Nat.card V ∧ IsCriticalSuccessor G q ∧
      G.chromaticNumber = ((q + 1 : ℕ) : ℕ∞) ∧
      (E : Set (Sym2 V)) ⊆ G.edgeSet ∧
      E.card ≤ q.choose 2 ∧ (G.deleteEdges E).Colorable 2 := by
  classical
  obtain ⟨H, hH⟩ := exists_critical_subgraph (graph q N) q
    (not_colorable hq) (colorable_succ hq)
  refine ⟨H.verts, H.coe, deletionEdges H, inferInstance, ?_, hH,
    hH.chromaticNumber, deletionEdges_subset H, deletionEdges_card_le H,
    deletion_colorable_two H⟩
  exact le_trans (Nat.le_succ N) (order_lower_bound hq H hH.1)

/-- A lower bound required to hold for every finite (q+1)-critical graph.
This is deliberately weak (≤ rather than <), so refuting it also refutes
any stronger interpretation of the proposed diverging bound. -/
def IsUniformDeletionLowerBound (q : ℕ) (f : ℕ → ℕ) : Prop :=
  ∀ (V : Type) [Finite V] (G : SimpleGraph V), IsCriticalSuccessor G q →
    ∀ E : Finset (Sym2 V), (E : Set (Sym2 V)) ⊆ G.edgeSet →
      (G.deleteEdges E).Colorable 2 → f (Nat.card V) ≤ E.card

/-- For every fixed chromatic number at least three, no uniform lower
bound on the number of deleted edges can tend to infinity with graph order. -/
theorem no_diverging_uniform_lower_bound (q : ℕ) (hq : 2 ≤ q) :
    ¬ ∃ f : ℕ → ℕ, Filter.Tendsto f Filter.atTop Filter.atTop ∧
      IsUniformDeletionLowerBound q f := by
  rintro ⟨f, hf, hbound⟩
  obtain ⟨N, hN⟩ := Filter.tendsto_atTop_atTop.mp hf (q.choose 2 + 1)
  obtain ⟨V, G, E, hfinite, hsize, hcritical, _, hsubset, hcard, hbip⟩ :=
    arbitrarily_large_critical_bipartizable q hq N
  letI : Finite V := hfinite
  have hlo := hN (Nat.card V) hsize
  have hhi := hbound V G hcritical E hsubset hbip
  omega


/-- Even allowing a graph-order threshold does not rescue a diverging bound. -/
theorem no_eventually_diverging_uniform_lower_bound (q : ℕ) (hq : 2 ≤ q) :
    ¬ ∃ (f : ℕ → ℕ) (N₀ : ℕ),
      Filter.Tendsto f Filter.atTop Filter.atTop ∧
      (∀ (V : Type) [Finite V] (G : SimpleGraph V),
        N₀ ≤ Nat.card V → IsCriticalSuccessor G q →
        ∀ E : Finset (Sym2 V), (E : Set (Sym2 V)) ⊆ G.edgeSet →
          (G.deleteEdges E).Colorable 2 → f (Nat.card V) ≤ E.card) := by
  rintro ⟨f, N₀, hf, hbound⟩
  obtain ⟨N, hN⟩ := Filter.tendsto_atTop_atTop.mp hf (q.choose 2 + 1)
  obtain ⟨V, G, E, hfinite, hsize, hcritical, _, hsubset, hcard, hbip⟩ :=
    arbitrarily_large_critical_bipartizable q hq (max N N₀)
  letI : Finite V := hfinite
  have hsizeN : N ≤ Nat.card V := le_trans (le_max_left N N₀) hsize
  have hsizeN₀ : N₀ ≤ Nat.card V := le_trans (le_max_right N N₀) hsize
  have hlo := hN (Nat.card V) hsizeN
  have hhi := hbound V G hsizeN₀ hcritical E hsubset hbip
  omega

/-- The original question even allowed a threshold on the fixed chromatic
number. There is no such threshold at which the proposed assertion holds. -/
theorem no_eventual_chromatic_threshold :
    ¬ ∃ q₀ : ℕ, ∀ q : ℕ, q₀ < q →
      ∃ f : ℕ → ℕ, Filter.Tendsto f Filter.atTop Filter.atTop ∧
        IsUniformDeletionLowerBound q f := by
  rintro ⟨q₀, h⟩
  exact no_diverging_uniform_lower_bound (q₀ + 2) (by omega)
    (h (q₀ + 2) (by omega))

/-- A particularly transparent specialization: unbounded-size 4-critical
graphs exist that become bipartite after at most three edge deletions. -/
theorem four_critical_three_deletions (N : ℕ) :
    ∃ (V : Type) (G : SimpleGraph V) (E : Finset (Sym2 V)),
      Finite V ∧ N ≤ Nat.card V ∧ IsCriticalSuccessor G 3 ∧
      G.chromaticNumber = 4 ∧
      (E : Set (Sym2 V)) ⊆ G.edgeSet ∧
      E.card ≤ 3 ∧ (G.deleteEdges E).Colorable 2 := by
  simpa using arbitrarily_large_critical_bipartizable 3 (by decide) N

/-- Standard chromatic-criticality stated directly in terms of Mathlib's
chromatic number: every proper subgraph has a strictly smaller value. -/
def IsChromaticCritical {V : Type*} (G : SimpleGraph V) (k : ℕ) : Prop :=
  G.chromaticNumber = (k : ℕ∞) ∧
    ∀ J : G.Subgraph, J ≠ ⊤ → J.coe.chromaticNumber < (k : ℕ∞)

/-- JSP-000612, counterexample/existence part, with the conventional parameter k.
This is uniform in all k≥3 and all requested lower bounds on the vertex count.
It does not assert the optimal lower bound for arbitrary critical graphs. -/
theorem jsp000612 (k : ℕ) (hk : 3 ≤ k) (N : ℕ) :
    ∃ (V : Type) (G : SimpleGraph V) (E : Finset (Sym2 V)),
      Finite V ∧ N ≤ Nat.card V ∧ IsChromaticCritical G k ∧
      (E : Set (Sym2 V)) ⊆ G.edgeSet ∧
      E.card ≤ (k - 1).choose 2 ∧ (G.deleteEdges E).Colorable 2 := by
  obtain ⟨V, G, E, hfinite, hsize, hcritical, hchrom, hsubset, hcard, hbip⟩ :=
    arbitrarily_large_critical_bipartizable (k - 1) (by omega) N
  have hk' : k - 1 + 1 = k := by omega
  refine ⟨V, G, E, hfinite, hsize, ?_, hsubset, hcard, hbip⟩
  constructor
  · simpa only [hk'] using hchrom
  · intro J hJ
    have hle := (hcritical.2.2 J hJ).chromaticNumber_le
    apply lt_of_le_of_lt hle
    exact_mod_cast (show k - 1 < k by omega)

end JSP612



namespace JSP612
open SimpleGraph

/-- Ordinary criticality is invariant under graph isomorphism. -/
theorem critical_iso {V W : Type*} {G : SimpleGraph V} {H : SimpleGraph W}
    (e : G ≃g H) {q : ℕ} (hG : IsCriticalSuccessor G q) :
    IsCriticalSuccessor H q := by
  refine ⟨?_, ?_, ?_⟩
  · rintro ⟨C⟩
    exact hG.1 ⟨C.comp e.toHom⟩
  · obtain ⟨C⟩ := hG.2.1
    exact ⟨C.comp e.symm.toHom⟩
  · intro J hJ
    let K : G.Subgraph := J.map e.symm.toHom
    have hK : K ≠ ⊤ := by
      intro he
      apply hJ
      apply top_unique
      constructor
      · intro x _
        have hx : e.symm x ∈ K.verts := by rw [he]; trivial
        obtain ⟨y, hy, hyx⟩ := hx
        have hyx' : y = x := e.symm.injective hyx
        simpa [hyx'] using hy
      · intro x y hxy
        have ha : K.Adj (e.symm x) (e.symm y) := by
          rw [he]
          exact e.symm.map_rel_iff.mpr hxy
        obtain ⟨a, b, hab, hax, hby⟩ := ha
        have hax' : a = x := e.symm.injective hax
        have hby' : b = y := e.symm.injective hby
        simpa [hax', hby'] using hab
    obtain ⟨C⟩ := hG.2.2 K hK
    let f : J.coe →g K.coe :=
      { toFun := fun x => ⟨e.symm x.val, ⟨x.val, x.property, rfl⟩⟩
        map_rel' := by
          intro x y hxy
          exact ⟨x.val, y.val, hxy, rfl, rfl⟩ }
    exact ⟨C.comp f⟩

/-- Relabelling preserves actual deletion certificates, without duplicating edges. -/
theorem deletion_certificate_iso {V W : Type*} {G : SimpleGraph V} {H : SimpleGraph W}
    (e : G ≃g H) (E : Finset (Sym2 V))
    (hs : (E : Set (Sym2 V)) ⊆ G.edgeSet)
    (hb : (G.deleteEdges E).Colorable 2) :
    ∃ F : Finset (Sym2 W), (F : Set (Sym2 W)) ⊆ H.edgeSet ∧
      F.card = E.card ∧ (H.deleteEdges F).Colorable 2 := by
  classical
  let F := E.image (Sym2.map e)
  refine ⟨F, ?_, ?_, ?_⟩
  · intro z hz
    obtain ⟨a, ha, rfl⟩ := Finset.mem_image.mp hz
    have hag := hs ha
    induction a using Sym2.inductionOn with
    | _ v w =>
      apply H.mem_edgeSet.mpr
      exact e.map_rel_iff.mpr (G.mem_edgeSet.mp hag)
  · exact Finset.card_image_of_injective _ (Sym2.map.injective e.injective)
  · obtain ⟨C⟩ := hb
    refine ⟨Coloring.mk (fun w => C (e.symm w)) ?_⟩
    intro v w ha he
    apply C.valid (show (G.deleteEdges E).Adj (e.symm v) (e.symm w) from ?_) he
    obtain ⟨hH, hn⟩ := deleteEdges_adj.mp ha
    apply deleteEdges_adj.mpr
    refine ⟨e.symm.map_rel_iff.mpr hH, ?_⟩
    intro hm
    apply hn
    apply Finset.mem_image.mpr
    refine ⟨s(e.symm v, e.symm w), hm, ?_⟩
    simp

/-- The witnesses can be taken on the standard labelled vertex set Fin n. -/
theorem labelled_witness (q : ℕ) (hq : 2 ≤ q) (N : ℕ) :
    ∃ (n : ℕ) (G : SimpleGraph (Fin n)) (E : Finset (Sym2 (Fin n))),
      N ≤ n ∧ IsCriticalSuccessor G q ∧
      (E : Set (Sym2 (Fin n))) ⊆ G.edgeSet ∧
      E.card ≤ q.choose 2 ∧ (G.deleteEdges E).Colorable 2 := by
  classical
  obtain ⟨V, G, E, hfin, hN, hc, _, hs, hcard, hb⟩ :=
    arbitrarily_large_critical_bipartizable q hq N
  letI : Finite V := hfin
  letI : Fintype V := Fintype.ofFinite V
  let n := Fintype.card V
  let H := G.overFin (rfl : Fintype.card V = n)
  let e : G ≃g H := G.overFinIso rfl
  obtain ⟨F, hF, hFc, hFb⟩ := deletion_certificate_iso e E hs hb
  refine ⟨n, H, F, ?_, critical_iso e hc, hF, ?_, hFb⟩
  · simpa [n, Nat.card_eq_fintype_card] using hN
  · rw [hFc]
    exact hcard

end JSP612

namespace JSP612
open SimpleGraph Filter
open scoped Topology

/-- The two criticality presentations agree in the direction needed here. -/
theorem critical_standard {V : Type*} {G : SimpleGraph V} {q : ℕ}
    (hG : IsCriticalSuccessor G q) : IsChromaticCritical G (q + 1) := by
  refine ⟨hG.chromaticNumber, ?_⟩
  intro J hJ
  apply lt_of_le_of_lt (hG.2.2 J hJ).chromaticNumber_le
  exact_mod_cast Nat.lt_succ_self q

/-- Actual achievable deletion counts: genuine finite labelled graphs,
all proper subgraphs in criticality, and only existing edges deleted. -/
def attainableCounts (k n : ℕ) : Set ℕ :=
  {m | ∃ (G : SimpleGraph (Fin n)) (E : Finset (Sym2 (Fin n))),
    IsChromaticCritical G k ∧ (E : Set (Sym2 (Fin n))) ⊆ G.edgeSet ∧
    E.card = m ∧ (G.deleteEdges E).Colorable 2}

/-- The genuine extremal minimum, not the known-answer formula.
An empty family has value infinity, never an artificial zero. -/
noncomputable def extremalDeletionNumber (k n : ℕ) : ℕ∞ :=
  sInf ((fun m : ℕ => (m : ℕ∞)) '' attainableCounts k n)

/-- Every actual certificate is an upper bound on the genuine minimum. -/
theorem extremal_le_of_mem {k n m : ℕ} (hm : m ∈ attainableCounts k n) :
    extremalDeletionNumber k n ≤ (m : ℕ∞) :=
  sInf_le ⟨m, hm, rfl⟩

/-- Nonempty minimisation is attained at a genuine graph and deletion set. -/
theorem extremal_attained {k n : ℕ} (h : (attainableCounts k n).Nonempty) :
    ∃ m ∈ attainableCounts k n, extremalDeletionNumber k n = (m : ℕ∞) := by
  refine ⟨sInf (attainableCounts k n), Nat.sInf_mem h, ?_⟩
  apply le_antisymm (extremal_le_of_mem (Nat.sInf_mem h))
  apply le_sInf
  rintro b ⟨m, hm, rfl⟩
  change (↑(sInf (attainableCounts k n)) : ℕ∞) ≤ (m : ℕ∞)
  exact_mod_cast (Nat.sInf_le hm)

/-- The empty-family convention is explicitly checked. -/
theorem extremal_of_empty {k n : ℕ} (h : attainableCounts k n = ∅) :
    extremalDeletionNumber k n = ⊤ := by
  simp [extremalDeletionNumber, h]

/-- There are arbitrarily large actual admissible orders with bounded minimum. -/
theorem cofinally_bounded_extremal (k : ℕ) (hk : 3 ≤ k) (N : ℕ) :
    ∃ n ≥ N, (attainableCounts k n).Nonempty ∧
      extremalDeletionNumber k n ≤ (((k - 1).choose 2 : ℕ) : ℕ∞) := by
  obtain ⟨n, G, E, hN, hc, hs, hcard, hb⟩ :=
    labelled_witness (k - 1) (by omega) N
  have hk' : k - 1 + 1 = k := by omega
  have hcritical : IsChromaticCritical G k := by
    simpa only [hk'] using critical_standard hc
  have hm : E.card ∈ attainableCounts k n := ⟨G, E, hcritical, hs, rfl, hb⟩
  refine ⟨n, hN, ⟨E.card, hm⟩, le_trans (extremal_le_of_mem hm) ?_⟩
  exact_mod_cast hcard

/-- Negation of divergence, with natural thresholds. In particular, this is
NOT the inappropriate atTop filter on the bounded ordered type of extended naturals. -/
theorem no_extremal_divergence (k : ℕ) (hk : 3 ≤ k) :
    ¬ (∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N, (b : ℕ∞) < extremalDeletionNumber k n) := by
  intro h
  obtain ⟨N, hN⟩ := h ((k - 1).choose 2)
  obtain ⟨n, hn, _, hb⟩ := cofinally_bounded_extremal k hk N
  exact (not_lt_of_ge hb) (hN n hn)

/-- Topological formulation of the same genuine nondivergence assertion. -/
theorem extremal_not_tendsto_infinity (k : ℕ) (hk : 3 ≤ k) :
    ¬ Tendsto (extremalDeletionNumber k) atTop (𝓝 ⊤) := by
  intro h
  apply no_extremal_divergence k hk
  intro b
  have he := ENat.tendsto_nhds_top_iff_natCast_lt.mp h b
  exact eventually_atTop.mp he

/-- Original fixed-chromatic-number conjecture, with the genuine extremal function. -/
def originalExtremalConjecture : Prop :=
  ∀ k : ℕ, 4 ≤ k →
    ∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N, (b : ℕ∞) < extremalDeletionNumber k n

/-- JSP-000612 / Erdős 744: the original conjecture is false. -/
theorem originalExtremalConjecture_false : ¬ originalExtremalConjecture := by
  intro h
  exact no_extremal_divergence 4 (by decide) (h 4 (by decide))

/-- Even a threshold on the fixed chromatic number does not rescue it. -/
theorem no_chromatic_threshold_for_extremal_divergence :
    ¬ ∃ k₀ : ℕ, ∀ k > k₀,
      ∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N, (b : ℕ∞) < extremalDeletionNumber k n := by
  rintro ⟨k₀, h⟩
  exact no_extremal_divergence (k₀ + 3) (by omega) (h (k₀ + 3) (by omega))

end JSP612

namespace JSP612
open SimpleGraph

/-- An impossible order is not represented by an artificial zero minimum. -/
theorem attainable_empty_of_order_lt {k n : ℕ} (hkn : n < k) :
    attainableCounts k n = ∅ := by
  apply Set.eq_empty_iff_forall_not_mem.mpr
  rintro m ⟨G, E, hc, _, _, _⟩
  have hle := G.colorable_of_fintype.chromaticNumber_le
  rw [hc.1, Fintype.card_fin] at hle
  have hn : k ≤ n := by exact_mod_cast hle
  omega

theorem extremal_infinite_of_order_lt {k n : ℕ} (hkn : n < k) :
    extremalDeletionNumber k n = ⊤ :=
  extremal_of_empty (attainable_empty_of_order_lt hkn)

/-- Every certificate for chromatic number at least three deletes a real edge. -/
theorem attainable_count_positive {k n m : ℕ} (hk : 3 ≤ k)
    (hm : m ∈ attainableCounts k n) : 0 < m := by
  obtain ⟨G, E, hc, _, hcard, hb⟩ := hm
  by_contra hn
  have hz : m = 0 := by omega
  have hE : E = ∅ := Finset.card_eq_zero.mp (hcard.trans hz)
  have hG : G.Colorable 2 := by simpa [hE] using hb
  have hle := hG.chromaticNumber_le
  rw [hc.1] at hle
  have hk2 : k ≤ 2 := by exact_mod_cast hle
  omega

/-- No vacuity: even when considering only orders admitting a critical graph,
there is no diverging lower bound for the genuine minimum. -/
theorem no_divergence_on_admissible_orders (k : ℕ) (hk : 3 ≤ k) :
    ¬ (∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N,
      (attainableCounts k n).Nonempty →
      (b : ℕ∞) < extremalDeletionNumber k n) := by
  intro h
  obtain ⟨N, hN⟩ := h ((k - 1).choose 2)
  obtain ⟨n, hn, ha, hb⟩ := cofinally_bounded_extremal k hk N
  exact (not_lt_of_ge hb) (hN n hn ha)

/-- Direct nonempty extremal witnesses, including attainment and positivity. -/
theorem bounded_attained_minima (k : ℕ) (hk : 3 ≤ k) (N : ℕ) :
    ∃ n ≥ N, ∃ m : ℕ,
      0 < m ∧ m ≤ (k - 1).choose 2 ∧
      m ∈ attainableCounts k n ∧ extremalDeletionNumber k n = (m : ℕ∞) := by
  obtain ⟨n, hn, ha, hb⟩ := cofinally_bounded_extremal k hk N
  obtain ⟨m, hm, he⟩ := extremal_attained ha
  refine ⟨n, hn, m, attainable_count_positive hk hm, ?_, hm, he⟩
  rw [he] at hb
  exact_mod_cast hb

end JSP612

-- Audit every theorem in this file, not only the final statement.
#print axioms JSP612.normalized_coloring
#print axioms JSP612.blocker_color
#print axioms JSP612.path_color_lt_two
#print axioms JSP612.link_color_lt_two
#print axioms JSP612.successive_path_colors
#print axioms JSP612.not_colorable
#print axioms JSP612.upperColor_valid
#print axioms JSP612.colorable_succ
#print axioms JSP612.puncturedColor_valid
#print axioms JSP612.path_mem_of_not_colorable
#print axioms JSP612.exists_critical_subgraph
#print axioms JSP612.order_lower_bound
#print axioms JSP612.paletteEdges_card_le
#print axioms JSP612.palette_pair_mem
#print axioms JSP612.same_side_edge
#print axioms JSP612.deletionEdges_card_le
#print axioms JSP612.deletionEdges_subset
#print axioms JSP612.deletion_colorable_two
#print axioms JSP612.IsCriticalSuccessor.chromaticNumber
#print axioms JSP612.arbitrarily_large_critical_bipartizable
#print axioms JSP612.no_diverging_uniform_lower_bound
#print axioms JSP612.no_eventually_diverging_uniform_lower_bound
#print axioms JSP612.no_eventual_chromatic_threshold
#print axioms JSP612.four_critical_three_deletions
#print axioms JSP612.jsp000612
#print axioms JSP612.critical_iso
#print axioms JSP612.deletion_certificate_iso
#print axioms JSP612.labelled_witness
#print axioms JSP612.critical_standard
#print axioms JSP612.extremal_le_of_mem
#print axioms JSP612.extremal_attained
#print axioms JSP612.extremal_of_empty
#print axioms JSP612.cofinally_bounded_extremal
#print axioms JSP612.no_extremal_divergence
#print axioms JSP612.extremal_not_tendsto_infinity
#print axioms JSP612.originalExtremalConjecture_false
#print axioms JSP612.no_chromatic_threshold_for_extremal_divergence
#print axioms JSP612.attainable_empty_of_order_lt
#print axioms JSP612.extremal_infinite_of_order_lt
#print axioms JSP612.attainable_count_positive
#print axioms JSP612.no_divergence_on_admissible_orders
#print axioms JSP612.bounded_attained_minima
#print JSP612.IsChromaticCritical
#print JSP612.attainableCounts
#print JSP612.extremalDeletionNumber
#print JSP612.originalExtremalConjecture
#check JSP612.jsp000612
#check JSP612.bounded_attained_minima
#check JSP612.originalExtremalConjecture_false
#check JSP612.extremal_not_tendsto_infinity
#check JSP612.no_divergence_on_admissible_orders
