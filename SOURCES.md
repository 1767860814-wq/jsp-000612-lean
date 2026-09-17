# Sources, provenance and review limits

References checked on 2026-09-17; mutable URLs are not immutable proof pins.

## Mathematical statements

- Original divergence question: P. Erdős, On the combinatorial problems which
  I would most like to see solved (1981). The relevant question is on PDF
  page 15 (zero-based 14), inspected as a rendered page.
  https://www.renyi.hu/~p_erdos/1981-16.pdf
- Official JSP-000612 catalogue entry, section lines 160–173 at retrieval:
  https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/problems/catalog-0601-0700.md
  Recorded solved historically, Lean No, Eligible No at the check.
- Historical mathematical result: V. Rödl and Zs. Tuza, On color critical
  graphs, Journal of Combinatorial Theory B 38 (1985), 204–213.
  DOI 10.1016/0095-8956(85)90066-8. Bibliographic attribution follows the
  catalogue. No claim to have newly solved the mathematical problem is made.
- A. Kostochka and B. Reiniger (2015), The minimum number of edges in a
  4-critical graph that is bipartite plus 3 edges, author-hosted paper:
  https://kostochk.web.illinois.edu/docs/2016/ejc15-r.pdf
  The introduction records the stronger historical sharp bound. That full
  sharp theorem is not the formalization claimed here.

## Formalization and replay

- Lean 4.19.0, `Lean/Replay.lean`, copyright Kim Morrison (2023), Apache-2.0:
  https://github.com/leanprover/lean4/blob/v4.19.0/src/Lean/Replay.lean
- Exact Mathlib revision imported by the proof:
  https://github.com/leanprover-community/mathlib4/tree/c44e0c8ee63ca166450922a373c7409c5d26b00b
- The original stock replay was unsuitable for this multi-module environment
  because the asynchronous elaborator normalizes private names from different
  modules. The local adapter invokes `Kernel.Environment.addDeclCore 0`
  directly and wraps the resulting kernel environment. It does not disable
  typechecking. Constructors and recursors are compared to the kernel-generated
  ones. This is a local same-kernel utility, not a separately audited checker.
- The proof source is identical to the immediately preceding 800-line version;
  this submission-preparation round strengthens execution evidence and packaging.
  Source SHA-256 is recorded in README.md and the machine-readable manifest.

## Official intake and evidence

https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/CONTRIBUTING.md
https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/.github/ISSUE_TEMPLATE/recommend-recipient.yml
https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/docs/records.md
https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/docs/verification.md
https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/docs/attribution.md
https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/data/schema/verification-record.schema.json
https://raw.githubusercontent.com/TheJustinSunPrize/awards/main/data/schema/statement.schema.json

The issue form supports a recipient placeholder and evidence-based contribution
recommendation. Incomplete substantive verification may remain under review;
source compilation and repository CI do not announce an award. The local
status file is deliberately not an official verification record.

## Priority check boundary

Queries for `"JSP-000612" Lean`, the exact number scoped to official issues,
and the exact number scoped to official pull requests did not establish an
exhaustive application history. Filtered GitHub search pages failed to load.
No claim that nobody has applied or that the project is first is established.
A local archive date, local Git commit or source hash is not a public timestamp.
No public repository, issue, PR or award application was created in this turn.
