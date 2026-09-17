/-
Replay the complete declaration-dependency closure in a fresh, empty environment.
This is a same-kernel replay audit, NOT an independent kernel implementation.
Lean.Replay is shipped with Lean 4.19.0 (Kim Morrison, Apache-2.0).
The unsafe IO entry point reads olean files; it is not imported by the proof.
-/
import Lean
/-
Copyright (c) 2023 Kim Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/
import Lean.CoreM
import Lean.AddDecl
import Lean.Util.FoldConsts

/-!
# `Lean.Environment.replay`

`replay env constantMap` will "replay" all the constants in `constantMap : HashMap Name ConstantInfo` into `env`,
sending each declaration to the kernel for checking.

`replay` does not send constructors or recursors in `constantMap` to the kernel,
but rather checks that they are identical to constructors or recursors generated in the environment
after replaying any inductive definitions occurring in `constantMap`.

`replay` can be used either as:
* a verifier for an `Environment`, by sending everything to the kernel, or
* a mechanism to safely transfer constants from one `Environment` to another.

-/

namespace Lean.JSP612KernelReplay

namespace Replay

structure Context where
  newConstants : Std.HashMap Name ConstantInfo

structure State where
  env : Environment
  remaining : NameSet := {}
  pending : NameSet := {}
  postponedConstructors : NameSet := {}
  postponedRecursors : NameSet := {}

abbrev M := ReaderT Context <| StateRefT State IO

/-- Check if a `Name` still needs processing. If so, move it from `remaining` to `pending`. -/
def isTodo (name : Name) : M Bool := do
  let r := (← get).remaining
  if r.contains name then
    modify fun s => { s with remaining := s.remaining.erase name, pending := s.pending.insert name }
    return true
  else
    return false

/-- Use the current `Environment` to throw a `Kernel.Exception`. -/
def throwKernelException (ex : Kernel.Exception) : M Unit := do
  throw <| .userError <| (← ex.toMessageData {} |>.toString)

/-- Add a declaration, possibly throwing a `Kernel.Exception`. -/
def addDecl (d : Declaration) : M Unit := do
  match (← get).env.toKernelEnv.addDeclCore 0 d none with
  | .ok kenv => modify fun s => { s with env := Environment.ofKernelEnv kenv }
  | .error ex => throwKernelException ex

mutual
/--
Check if a `Name` still needs to be processed (i.e. is in `remaining`).

If so, recursively replay any constants it refers to,
to ensure we add declarations in the right order.

The construct the `Declaration` from its stored `ConstantInfo`,
and add it to the environment.
-/
partial def replayConstant (name : Name) : M Unit := do
  if ← isTodo name then
    let some ci := (← read).newConstants[name]? | unreachable!
    replayConstants ci.getUsedConstantsAsSet
    -- Check that this name is still pending: a mutual block may have taken care of it.
    if (← get).pending.contains name then
      match ci with
      | .defnInfo   info =>
        addDecl (Declaration.defnDecl   info)
      | .thmInfo    info =>
        addDecl (Declaration.thmDecl    info)
      | .axiomInfo  info =>
        addDecl (Declaration.axiomDecl  info)
      | .opaqueInfo info =>
        addDecl (Declaration.opaqueDecl info)
      | .inductInfo info =>
        let lparams := info.levelParams
        let nparams := info.numParams
        let all ← info.all.mapM fun n => do pure <| ((← read).newConstants[n]!)
        for o in all do
          modify fun s =>
            { s with remaining := s.remaining.erase o.name, pending := s.pending.erase o.name }
        let ctorInfo ← all.mapM fun ci => do
          pure (ci, ← ci.inductiveVal!.ctors.mapM fun n => do
            pure ((← read).newConstants[n]!))
        -- Make sure we are really finished with the constructors.
        for (_, ctors) in ctorInfo do
          for ctor in ctors do
            replayConstants ctor.getUsedConstantsAsSet
        let types : List InductiveType := ctorInfo.map fun ⟨ci, ctors⟩ =>
          { name := ci.name
            type := ci.type
            ctors := ctors.map fun ci => { name := ci.name, type := ci.type } }
        addDecl (Declaration.inductDecl lparams nparams types false)
      -- We postpone checking constructors,
      -- and at the end make sure they are identical
      -- to the constructors generated when we replay the inductives.
      | .ctorInfo info =>
        modify fun s => { s with postponedConstructors := s.postponedConstructors.insert info.name }
      -- Similarly we postpone checking recursors.
      | .recInfo info =>
        modify fun s => { s with postponedRecursors := s.postponedRecursors.insert info.name }
      | .quotInfo _ =>
        addDecl (Declaration.quotDecl)
      modify fun s => { s with pending := s.pending.erase name }

/-- Replay a set of constants one at a time. -/
partial def replayConstants (names : NameSet) : M Unit := do
  for n in names do replayConstant n

end

/--
Check that all postponed constructors are identical to those generated
when we replayed the inductives.
-/
def checkPostponedConstructors : M Unit := do
  for ctor in (← get).postponedConstructors do
    match (← get).env.find? ctor, (← read).newConstants[ctor]? with
    | some (.ctorInfo info), some (.ctorInfo info') =>
      if ! (info == info') then throw <| IO.userError s!"Invalid constructor {ctor}"
    | _, _ => throw <| IO.userError s!"No such constructor {ctor}"

/--
Check that all postponed recursors are identical to those generated
when we replayed the inductives.
-/
def checkPostponedRecursors : M Unit := do
  for ctor in (← get).postponedRecursors do
    match (← get).env.find? ctor, (← read).newConstants[ctor]? with
    | some (.recInfo info), some (.recInfo info') =>
      if ! (info == info') then throw <| IO.userError s!"Invalid recursor {ctor}"
    | _, _ => throw <| IO.userError s!"No such recursor {ctor}"

end Replay

open Replay

/--
"Replay" some constants into an `Environment`, sending them to the kernel for checking.

Throws a `IO.userError` if the kernel rejects a constant,
or if there are malformed recursors or constructors for inductive types.
-/
def replay (newConstants : Std.HashMap Name ConstantInfo) (env : Environment) : IO Environment := do
  let mut remaining : NameSet := ∅
  for (n, ci) in newConstants.toList do
    -- We skip unsafe constants, and also partial constants.
    -- Later we may want to handle partial constants.
    if !ci.isUnsafe && !ci.isPartial then
      remaining := remaining.insert n
  let (_, s) ← StateRefT'.run (s := { env, remaining }) do
    ReaderT.run (r := { newConstants }) do
      for n in remaining do
        replayConstant n
      checkPostponedConstructors
      checkPostponedRecursors
  return s.env

end Lean.JSP612KernelReplay
/-
Local adaptation of Lean 4.19.0 Lean/Replay.lean. The only checking-path change
is to call Kernel.Environment.addDeclCore directly, then reconstruct the
elaboration wrapper. This avoids collisions between private normalized names
from separate modules in the asynchronous elaborator environment; it does not
skip kernel typechecking. All constructors/recursors are compared exactly.
This uses the SAME Lean kernel, not an independent implementation.
-/


open Lean

private def allowedAxiom (n : Name) : Bool :=
  n == ``propext || n == ``Classical.choice || n == ``Quot.sound

private partial def collect (env : Environment) (n : Name)
    (acc : Std.HashMap Name ConstantInfo) : IO (Std.HashMap Name ConstantInfo) := do
  if acc.contains n then return acc
  let some ci := env.find? n | throw <| IO.userError s!"Missing dependency: {n}"
  if ci.isUnsafe || ci.isPartial then
    throw <| IO.userError s!"Unsafe or partial dependency: {n}"
  if let .axiomInfo _ := ci then
    unless allowedAxiom n do
      throw <| IO.userError s!"Unapproved axiom: {n}"
  let mut acc := acc.insert n ci
  let mut deps := ci.getUsedConstantsAsSet
  if let .inductInfo v := ci then
    for name in v.all do deps := deps.insert name
    for name in v.ctors do deps := deps.insert name
  for dep in deps do acc ← collect env dep acc
  return acc

unsafe def main (args : List String) : IO UInt32 := do
  unless args.length ≤ 3 do
    throw <| IO.userError "Usage: Recheck.lean [module] [namespace] [mutate-proof]"
  if let some opt := args[2]? then
    unless opt == "mutate-proof" do
      throw <| IO.userError s!"Unknown option: {opt}"
  initSearchPath (← findSysroot)
  let module := (args.headD "JSP000612").toName
  let nsPrefix := (args[1]?.getD "JSP612").toName
  withImportModules #[{module}] {} fun env => do
    let mut roots : Array Name := #[]
    for (n, ci) in env.constants.toList do
      if nsPrefix.isPrefixOf n then
        if let .thmInfo _ := ci then roots := roots.push n
    if roots.isEmpty then throw <| IO.userError "No theorem roots found"
    roots := roots.qsort Name.quickLt
    let mut closure : Std.HashMap Name ConstantInfo := {}
    for n in roots do closure ← collect env n closure
    IO.println s!"ROOT_THEOREMS: {roots.size}"
    IO.println s!"CLOSURE_DECLARATIONS: {closure.size}"
    let mut axes : Array String := #[]
    for (n, ci) in closure.toList do
      if let .axiomInfo _ := ci then axes := axes.push n.toString
    IO.println s!"AXIOMS: {axes.qsort (· < ·)}"
    -- Negative test only: deliberately substitute an ill-typed proof term.
    -- This flag does not alter JSP000612.lean or the stored olean.
    if args[2]? == some "mutate-proof" then
      let target := `JSP612.originalExtremalConjecture_false
      let some (.thmInfo ti) := closure[target]? |
        throw <| IO.userError "Mutation target theorem missing"
      closure := closure.insert target (.thmInfo { ti with value := mkConst ``True.intro })
      IO.println s!"INTENTIONAL_PROOF_MUTATION: {target} := True.intro"
    let replayed ← JSP612KernelReplay.replay closure (← mkEmptyEnvironment 0)
    for n in roots do
      let some before := closure[n]? | throw <| IO.userError s!"Root absent: {n}"
      let some after := replayed.find? n | throw <| IO.userError s!"Replay absent: {n}"
      unless before.type == after.type do throw <| IO.userError s!"Type mismatch: {n}"
      unless before.value? == after.value? do throw <| IO.userError s!"Value mismatch: {n}"
      IO.println s!"REPLAYED: {n}"
    IO.println "FRESH_KERNEL_REPLAY: PASS"
    return 0
