/- Exact declaration-type and dependency-policy gate. Same Lean implementation.
   Does not replace independent external checking or human semantic review. -/
import Lean
import Lean.Util.FoldConsts

open Lean Elab Command Meta

private partial def visit (env : Environment) (n : Name) (seen : NameSet) :
    Except String NameSet := do
  if seen.contains n then return seen
  let some ci := env.find? n | throw s!"MISSING_DEPENDENCY: {n}"
  if ci.isUnsafe || ci.isPartial then throw s!"UNSAFE_DEPENDENCY: {n}"
  if let .axiomInfo _ := ci then
    unless n == ``propext || n == ``Classical.choice || n == ``Quot.sound do
      throw s!"UNAPPROVED_AXIOM: {n}"
  let mut seen := seen.insert n
  let mut ds := ci.getUsedConstantsAsSet
  if let .inductInfo v := ci then
    for d in v.all do ds := ds.insert d
    for d in v.ctors do ds := ds.insert d
  for d in ds do seen ← visit env d seen
  return seen

elab "audit_exact " actual:ident " against " expected:ident : command => do
  let env ← getEnv
  let aName := actual.getId
  let eName := expected.getId
  let some ci := env.find? aName | throwError "MISSING_THEOREM: {aName}"
  let .thmInfo info := ci | throwError "NOT_A_THEOREM: {aName}"
  unless info.levelParams.isEmpty do
    throwError "UNEXPECTED_UNIVERSE_PARAMETERS: {aName}"
  let some (.defnInfo spec) := env.find? eName
    | throwError "MISSING_SPECIFICATION: {eName}"
  liftTermElabM do
    unless ← withTransparency .all (isDefEq info.type spec.value) do
      throwError "TYPE_MISMATCH: {aName} does not match {eName}"
    if info.type.hasMVar || spec.value.hasMVar then
      throwError "UNRESOLVED_METAVARIABLE"
  match visit env aName {} with
  | .error msg => throwError "{msg}"
  | .ok _ => logInfo m!"EXACT_TYPE_AND_AXIOMS_PASS: {aName} against {eName}"
