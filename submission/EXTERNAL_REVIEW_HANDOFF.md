# Handoff for designated external verification

No external checker success is claimed in this package. The official workflow in the published rules (section 6) places designated offline verification after online submission.

The standalone challenge is `SubmissionChallenge.lean`. It imports only pinned Mathlib modules; it does not import `JSP000612`, assert a solution, or contain `sorry`. Its author is the submitting project, not a disinterested reviewer. Review its six statements and all definitions independently before adopting it as a trusted challenge.

Suggested higher-assurance route: the Lean reference manual's Comparator + external-checker procedure. The manual identifies Nanoda as an independently developed Rust checker. A version-compatible exporter, checker build, frozen challenge, axiom policy, and complete proof-dependency coverage must actually be exercised; merely placing their names or config options in this package is not evidence that they ran.

For external axiom policy permit only `propext`, `Classical.choice`, and `Quot.sound`. Do not permit `sorryAx`, `Lean.trustCompiler`, or an assumed result. Do not use an unchecked or hardcoded stand-in for the extremal minimum. Preserve all chromatic-number and graph-size quantifiers. Both a valid input and deliberately corrupted proof/statement inputs should be tested.

Local limitations in this preparation session: the execution environment was restored and local tests ran, but network/DNS access did not permit acquiring and building the missing checker toolchain. No safe-version certification, independent reviewer signature, or public-repository verification is invented.

Sources:
- https://www.hejustinsun.com/prize/rules (sections 4.2 and 6)
- https://github.com/TheJustinSunPrize/awards/blob/main/docs/records.md
- https://lean-lang.org/doc/reference/latest/ValidatingProofs/
- https://github.com/leanprover/comparator
- https://github.com/ammkrn/nanoda_lib
