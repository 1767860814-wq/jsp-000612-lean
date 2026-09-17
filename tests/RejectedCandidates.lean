/- Deliberately unacceptable candidates. Never imported by the real proof.
   This file MUST NOT count as mathematical evidence. It is compiled only to
   confirm that the gate rejects wrong types and disallowed dependencies. -/
import SubmissionChallenge
import JSP000612
open SimpleGraph
namespace RejectedCandidates

theorem changedToTrue : True := True.intro

theorem explicitHypothesis (h : JSP612Challenge.WitnessStatement) :
    JSP612Challenge.WitnessStatement := h

class HoldsClaim : Prop where
  claim : JSP612Challenge.WitnessStatement

theorem typeclassHypothesis [h : HoldsClaim] :
    JSP612Challenge.WitnessStatement := h.claim

axiom inventedAxiom : JSP612Challenge.WitnessStatement

theorem axiomBased : JSP612Challenge.WitnessStatement := inventedAxiom

theorem sorryBased : JSP612Challenge.WitnessStatement := by sorry

def notATheorem : JSP612Challenge.WitnessStatement := JSP612.jsp000612

def WeakCritical {V : Type*} (_G : SimpleGraph V) (_k : ℕ) : Prop := True

theorem weakenedCritical (k : ℕ) (hk : 3 ≤ k) (N : ℕ) :
    ∃ (V : Type) (G : SimpleGraph V) (E : Finset (Sym2 V)),
      Finite V ∧ N ≤ Nat.card V ∧ WeakCritical G k ∧
      (E : Set (Sym2 V)) ⊆ G.edgeSet ∧
      E.card ≤ (k - 1).choose 2 ∧ (G.deleteEdges E).Colorable 2 := by
  obtain ⟨V, G, E, hfin, hN, _, hs, hc, hb⟩ := JSP612.jsp000612 k hk N
  exact ⟨V, G, E, hfin, hN, trivial, hs, hc, hb⟩

def HardcodedMinimum (_k _n : ℕ) : ℕ∞ := 0

theorem hardcodedAnswer :
    ¬ ∃ k₀ : ℕ, ∀ k > k₀,
      ∀ b : ℕ, ∃ N : ℕ, ∀ n ≥ N, (b : ℕ∞) < HardcodedMinimum k n := by
  rintro ⟨k₀, h⟩
  obtain ⟨N, hN⟩ := h (k₀ + 1) (Nat.lt_succ_self _) 0
  exact (lt_irrefl (0 : ℕ∞)) (hN N le_rfl)

end RejectedCandidates
