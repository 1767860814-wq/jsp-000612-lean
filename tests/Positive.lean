import JSP000612
open JSP612
example : (0 : ℕ) = 0 := rfl
example : extremalDeletionNumber 4 0 = ⊤ := extremal_infinite_of_order_lt (by decide)
example : ¬ originalExtremalConjecture := originalExtremalConjecture_false
example (N : ℕ) : ∃ n ≥ N, ∃ m : ℕ,
    0 < m ∧ m ≤ 3 ∧ m ∈ attainableCounts 4 n ∧
    extremalDeletionNumber 4 n = (m : ℕ∞) := by
  simpa using bounded_attained_minima 4 (by decide) N
