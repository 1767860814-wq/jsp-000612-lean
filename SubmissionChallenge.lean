/-
Frozen statement specification for JSP-000612's original divergence question.
This module imports only Mathlib, never the proposed proof or its definitions.
It was written separately in this submission audit, not by an independent referee.
No proof or assumed solution is included here.
-/
import Mathlib.Combinatorics.SimpleGraph.Coloring
import Mathlib.Combinatorics.SimpleGraph.Subgraph
import Mathlib.Combinatorics.SimpleGraph.DeleteEdges
import Mathlib.Topology.Instances.ENat

namespace JSP612Challenge
open SimpleGraph Filter
open scoped Topology

def Critical {V : Type*} (G : SimpleGraph V) (k : ℕ) : Prop :=
  G.chromaticNumber = (k : ℕ∞) ∧
    ∀ J : G.Subgraph, J ≠ ⊤ → J.coe.chromaticNumber < (k : ℕ∞)

def Counts (k n : ℕ) : Set ℕ :=
  {m | ∃ (G : SimpleGraph (Fin n)) (E : Finset (Sym2 (Fin n))),
    Critical G k ∧ (E : Set (Sym2 (Fin n))) ⊆ G.edgeSet ∧
    E.card = m ∧ (G.deleteEdges E).Colorable 2}

noncomputable def Minimum (k n : ℕ) : ℕ∞ :=
  sInf ((fun m : ℕ => (m : ℕ∞)) '' Counts k n)

def WitnessStatement : Prop :=
  ∀ (k : ℕ), 3 ≤ k → ∀ N : ℕ,
    ∃ (V : Type) (G : SimpleGraph V) (E : Finset (Sym2 V)),
      Finite V ∧ N ≤ Nat.card V ∧ Critical G k ∧
      (E : Set (Sym2 V)) ⊆ G.edgeSet ∧
      E.card ≤ (k - 1).choose 2 ∧ (G.deleteEdges E).Colorable 2

def AttainedStatement : Prop :=
  ∀ (k : ℕ), 3 ≤ k → ∀ N : ℕ,
    ∃ n ≥ N, ∃ m : ℕ,
      0 < m ∧ m ≤ (k - 1).choose 2 ∧
      m ∈ Counts k n ∧ Minimum k n = (m : ℕ∞)

def NoThresholdStatement : Prop :=
  ¬ ∃ k₀ : ℕ, ∀ k > k₀,
    ∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N, (b : ℕ∞) < Minimum k n

def AdmissibleStatement : Prop :=
  ∀ (k : ℕ), 3 ≤ k →
    ¬ (∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N,
      (Counts k n).Nonempty → (b : ℕ∞) < Minimum k n)

def OriginalStatement : Prop :=
  ¬ (∀ k : ℕ, 4 ≤ k →
    ∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N, (b : ℕ∞) < Minimum k n)

def TopologicalStatement : Prop :=
  ∀ (k : ℕ), 3 ≤ k → ¬ Tendsto (Minimum k) atTop (𝓝 ⊤)

end JSP612Challenge
