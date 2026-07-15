# Chapter 7 — *BEer: Certified Encoding of B into SMT-LIB* — Writing Plan

This document is the working plan for (re)writing Chapter 7. It is **not** compiled into the
thesis. It records: the design stance, the section-by-section content, the exact mathematics to
introduce, the encoding-rule catalogue, the soundness proof structure with per-case sketches, the
lemma dependency map, the macros to reuse or add, and the migration map from the old files.

---

## 0. Design principles

1. **Proofs are the subject; the implementation is a detail.** The chapter is organised around one
   theorem — soundness of the encoder — and the mathematics that makes it clean. The Lean/monadic
   realisation is confined to a single, explicitly subordinate section (§7.6).

2. **Abstract the monad away.** The Lean encoder runs in `Encoder = StateT EncoderState (Except
   String)` and its correctness is a weakest-precondition (Hoare) triple threading a state
   (typing context `Γ`, fresh-name supply, emitted script) and renaming contexts `Δ, Δ₀, Δ'`. In
   the manuscript the encoder is presented as a **partial function** on typed terms and its
   correctness as a **denotational equation**. The state and renaming bookkeeping never appear in
   the mathematical statements. The justification for this move — the encoder is *pure* (no `IO`),
   so it denotes a total function from a B environment to an SMT script — is stated once, in §7.6,
   and the weakest-precondition discharge of the state obligations is described there.

3. **One shared ZFC universe.** B and SMT both denote into the ZFSet universe of Chapter 3
   (ZFLean). Every correctness statement is therefore a genuine set-theoretic identity in that
   universe, not a cross-model transport. This is the single fact that makes the whole development
   clean and must be foregrounded.

4. **Reuse Chapter 6, do not re-derive it.** Type loosening — the order `⊑`, the paths `⇝`, the
   normal forms `α^⊥`/`α^⊤`, the Galois connection, the semantic casts `castZF`, and loosening
   correctness (fresh variable + spec pinning it to the cast image) — all belong to Chapter 6.
   Chapter 7 *uses* them. The canonical isomorphism `ζ`, the retraction `η`, and the agreement
   relation `≘ᶻ` are **not** used in Chapter 6 (verified: `\retr`/`\canon` occur only in the beer
   chapter), so Chapter 7 owns them.

5. **State every gap.** `min`, `max`, `card` are declared but the encoder `throw`s on them, so their
   induction cases are vacuous — no SMT term and no guarantee are produced. This is disclosed in
   §7.7, not hidden.

---

## 1. Section-by-section plan

### §7.1 Introduction — `introduction.tex`
Purpose: state the goal, the theorem informally, the running example, and the chapter's position.

- **7.1.1 What is proved.** The encoder maps a well-typed B proof obligation to an SMT-LIB script
  such that *unsatisfiability of the script entails validity of the proof obligation*. The kernel
  of this is a term-level statement: for a well-typed B term `t`, the emitted SMT term `t'`
  satisfies `η_α(⟦t'⟧ˢ) = ⟦t⟧ᴮ`.
- **7.1.2 The running example.** Introduce one small, real proof obligation (candidate: a POG with a
  set union or membership goal — pick from `benchmark/dataset-pog`, small enough to display). Show
  its B form now; it is encoded in §7.3, scripted in §7.5, and its soundness instance is pointed to
  in §7.4.
- **7.1.3 Reading map.** Dependencies: Chapter 3 (ZFSet, relational calculus, `≅ᶻ`), Chapter 4 (B
  syntax/typing/semantics `⟦·⟧ᴮ`, well-definedness), Chapter 5 (SMT syntax/typing/semantics
  `⟦·⟧ˢ`), Chapter 6 (loosening). One paragraph, prose.
- **7.1.4 Purity, stated once.** One sentence: the encoder is a pure state computation, hence
  denotes a function; this licenses the denotational style of the whole chapter. Forward-reference
  §7.6 for the discharge.

### §7.2 The B–SMT semantic bridge — `semantic-bridge.tex`
Purpose: introduce, cleanly and once, every canonical construction the soundness proof uses. This
is the conceptual heart and must be the most polished section.

- **7.2.1 Encoding B types into SMT types `·^SMT`.** `BType → SMTType`, recursive:
  `int ↦ int`, `bool ↦ bool`, `prod α β ↦ pair α^SMT β^SMT`,
  `set α ↦ α^SMT → bool` (a **characteristic predicate**). Note that the encoding always lands
  in the *most general* (relational) normal form `α^⊤` of Chapter 6.
- **7.2.2 The canonical isomorphism `ζ_α`.** `ζ_α : ⟦α⟧ᶻ → ⟦α^SMT⟧ᶻ`, defined by induction on `α`
  as an explicit ZF function that is provably `IsFunc` and `IsBijective`. Base cases are the
  identity; the product case is the componentwise product `ζ_α ⊗ ζ_β`; the set case conjugates a
  subset into a characteristic predicate on `⟦α^SMT⟧ᶻ`. State the theorem `⟦α⟧ᶻ ≅ᶻ ⟦α^SMT⟧ᶻ`
  (`BType_iso_SMTType`). Keep the set-case construction but relegate the ZF bookkeeping of its
  bijectivity proof to a citation of the formalization (`canonicalIsoSMTType`), it is the single
  most intricate proof and should not be reproduced in full.
- **7.2.3 The retraction `η_α`.** `η_α : ⟦α^SMT⟧ᶻ → ⟦α⟧ᶻ`, induction on `α`; identity on base
  types, componentwise on products, and on a set type the comprehension
  `η_{set β}(F) = { x ∈ ⟦β⟧ᶻ | F(ζ_β x) = ⊤ }`. (This is exactly the definition already drafted in
  the old *Union case* preamble.)
- **7.2.4 Round-trip laws.** The two triangle identities:
  `η_α ∘ ζ_α = id` on `⟦α⟧ᶻ` (`retract_of_canonical`) and `ζ_α ∘ η_α = id` on `⟦α^SMT⟧ᶻ`
  (`canonicalIso_composition_retract`). Corollary: `ζ_α` is a bijection with inverse `η_α`; hence
  `η_α` is surjective and `ζ_α` injective — the two facts the proof actually consumes.
- **7.2.5 The canonical image (set level).** `𝒟^! := ζ_α[𝒟] = { y ∈ ⟦α^SMT⟧ᶻ | η_α(y) ∈ 𝒟 }`
  (`canonicalImage`) with `mem_canonicalImage_iff`. Used to transport a B-side set through the
  bridge.
- **7.2.6 The agreement relation `≘ᶻ`.** `⟨X,α⟩ ≘ᶻ ⟨X',α'⟩  ⟺  α' = α^SMT ∧ η_α(X') = X` (`RDom`).
  Read: *an SMT value agrees with a B value iff it retracts onto it.* This is the correctness
  invariant of the whole chapter. Give the pointwise valuation-agreement `RValuation` too.
- **7.2.7 Valuations as a fully faithful functor.** `Δ ↦ Δ^SMT` sends a B renaming context to an SMT
  one variable-by-variable through `ζ`, so that `Δ v` and `Δ^SMT v` are `≘ᶻ`-related
  (`RenamingContext.toSMT`). This is the clean statement replacing the ad-hoc `Δ, Δ₀, Δ'` plumbing;
  present it as "the bridge extends functorially from types to valuations," and keep the concrete
  three-context machinery for §7.6.

### §7.3 Encoding rules — `encoding-rules.tex`
Purpose: define the encoder as a mathematical function and give every rule, monad-free.

- **7.3.1 The encoding judgement.** Present `⟦·⟧ : Term_B ⇀ Term_S × SMTType` as a partial function
  from typed B terms, with the invariant that a term of B-type `α` maps to an SMT term of type
  `α^SMT` (state the typing-preservation lemma here, prove it in §7.4). Explain the two things the
  monad hides — a typing context `Γ` and a fresh-name supply — and say they are treated as ambient
  (details §7.6).
- **7.3.2 Atoms, arithmetic, logic, pairs.** The homomorphic rules (see catalogue §3 below):
  variables, integer/boolean literals, `+,-,*,≤,∧,¬`, and the maplet `x ↦ y ↦ pair`.
- **7.3.3 Sets as characteristic predicates.** `ℤ`, `𝔹` (constant-true predicates), powerset `𝒫`,
  cartesian product `×`, partial functions `⇸`. Each emits a lambda whose body is the defining
  predicate.
- **7.3.4 Comprehension and lambda.** Set comprehension `{ vs ∈ D | P }` (two cases: `D` a set /
  `D` a function), and `λ vs ∈ D. P` encoded as the **graph** of the partial function.
- **7.3.5 The cast layer.** `castEq`, `castMembership`, `castUnion`, `castInter`, `castApp`. Motivate
  from the multi-representation problem: the same B relation type has several `⊑`-comparable SMT
  forms (functional `α→option β`, relational/graph `(α×β)→bool`, characteristic predicate). A binary
  operation first **loosens** both operands (Chapter 6) to a common representation — their join
  `⊔` — then combines them pointwise. Give each cast's emitted term and defer its spec to §7.4.
  Use the union rule as the worked instance (migrated from the old *Encoding algorithm*).
- **7.3.6 Binders and quantifier `∀`.** The universal `∀ vs ∈ D. P`: fresh binders, domain guard via
  `castMembership`, and the scoping of cast helpers generated while encoding the body as
  **guarded universals** `∀ helper. spec(helper) ⇒ body`. State the emitted shape; the soundness of
  the `∀`-vs-`∃` polarity choice is argued in §7.4.

### §7.4 Soundness of the encoding — `soundness.tex`
Purpose: the main theorem and its inductive proof, per family. This is the largest section.

- **7.4.1 The invariant and the theorem.** Correctness of a term encoding = agreement `≘ᶻ`, i.e.
  `η_α(⟦t'⟧ˢ) = ⟦t⟧ᴮ`, together with type preservation `⊢ˢ t' : α^SMT`. State the clean theorem
  (the monad-free projection of `encodeTerm_spec`): *for well-typed, well-defined `t : α`, the
  encoding `t'` is well-typed of type `α^SMT`, denotes, and `⟨⟦t⟧ᴮ,α⟩ ≘ᶻ ⟦t'⟧ˢ`.* Note the
  hidden hypotheses that survive abstraction (well-definedness `wd t`, valuation agreement) and
  those that vanish (used-var monotonicity, context extension, none-outside-used).
- **7.4.2 The proof spine.** One paragraph + a lemma list: the argument is one structural induction
  where each case rewrites `η` past the encoder. The reusable lemmas:
  round-trip `η∘ζ=id` and `ζ∘η=id`; the **bridge lemma** `η_{set β}(F)=X ⟹ (x∈X ⟺ F(ζ_β x)=⊤)`;
  loosening correctness (Chapter 6); denotation totality/determinism; substitution-under-binders.
- **7.4.3 Homomorphic cases.** var, literals, `+,-,*,≤,∧,¬`, maplet. `η` is the identity (base) or
  componentwise (pair), so it commutes past the operation. `var` is the only non-`rfl` one: it is
  exactly `η_α(ζ_α X)=X`.
- **7.4.4 Base-type sets.** `ℤ`, `𝔹`: `η` is a comprehension here; `η_{set int}(λz.⊤) = {z∈Int|⊤} =
  Int = ⟦ℤ⟧ᴮ`.
- **7.4.5 Pointwise set operations — the model case.** Union (fully written; migrate the existing
  theorem+proof), then intersection, membership, equality by the same pattern: after loosening to a
  common representation, a pointwise Boolean operation, discharged by the bridge lemma and a
  two-valued case split. Keep the note that four-way boolean case analysis is the Lean core but
  reduces mathematically to "`∨` on `𝔹` is disjunction."
- **7.4.6 Application.** `castApp`: the emitted `the (f!! x')` with `f!!` a fresh total
  `γ^SMT → option α^SMT`; the witness interprets `f!!` so that `⟦t'⟧ˢ = ζ_α T` with
  `T = ⟦f(x)⟧ᴮ`, then `η_α(ζ_α T)=T`.
- **7.4.7 Set formers.** Powerset and cartesian product (quantified predicates; `⊆` and pair
  decomposition via the bridge and `ζ`-injectivity), partial functions (two conjuncts:
  `R⊆A×B` and functionality, the latter using `ζ`-injectivity to turn SMT-equality into ZF-equality).
- **7.4.8 Comprehension and lambda-graph.** The `ite`/graph constructions; guard true exactly on
  `⟦D⟧ᴮ`; body value matches `⟦P⟧`; substitution lemma for the destructured binders.
- **7.4.9 The universal quantifier.** The hardest case. State the denotational goal
  (`⟦∀ vs∈D.P⟧ᴮ` is a ZF-boolean, vacuously `⊤` on empty domain). Explain the guarded-universal
  scoping and give the **soundness argument** for `∀ helper. spec ⇒ body` over
  `∃ helper. spec ∧ body`: helper values are functionally determined by the bound variables; under
  negation of the surrounding goal an existential lets the solver pick a spec-violating helper and
  trivially satisfy `¬(spec ∧ body)`, so the universal-implication polarity is the sound one. Flag
  the two witness hypotheses (existence + totality across admissible valuations) that the formal
  statement threads and the paper proof packages as "the quantified denotation exists and is
  determined."
- **7.4.10 Case/lemma dependency figure.** A small diagram mapping families to the shared lemmas
  (see §8).

### §7.5 Encoding proof obligations — `proof-obligations.tex`
Purpose: lift term soundness to whole proof obligations and state the end-to-end guarantee.

- **7.5.1 From terms to environments.** Encoding the typing context (`declare-const` per variable,
  flags handled specially), definitions (`define-fun`), distinct/finite constraints, and hypotheses.
- **7.5.2 Goals and refutation.** Each goal is negated and asserted; a `check-sat` per goal. Explain
  why per-PO local contexts are pushed/popped (name reuse across POs) — briefly, as it is
  semantically relevant (soundness of scoping), not as implementation trivia.
- **7.5.3 End-to-end soundness.** Assemble: if the emitted script is unsatisfiable then the proof
  obligation is valid. Derive it from term soundness (§7.4) plus the semantics of assert/negate.
  State precisely what "valid" means against `⟦·⟧ᴮ`. Close the running example here.

### §7.6 Implementation — `implementation.tex`
Purpose: the single, explicitly subordinate implementation section. Migrate the two existing files.

- **7.6.1 The two-pass pipeline and the encoder monad.** (Migrate `lean-implementation-architecture.tex`.)
  Decoder and encoder; `EncoderState`; purity; how purity licenses the denotational statements and
  how the state obligations are discharged in a Floyd–Hoare weakest-precondition calculus.
- **7.6.2 Binders, names, contexts.** (Migrate `binders-names-contexts.tex`.) Monotone fresh-name
  supply vs scoped typing context; `freshVar`, `addToContext`, `eraseFromContext`; erasing binder
  variables; the snapshot/rescope discipline in the `∀` case. Keep the "monotone counter is
  correctness, not convenience" note.
- **7.6.3 From rules to code.** One short subsection tying each mathematical rule of §7.3 to its
  monadic clause, so the reader can cross-check. Optional.

### §7.7 Discussion — `discussion.tex`
Purpose: trusted computing base, limitations, coverage.

- **7.7.1 Trusted computing base.** Lean kernel; the POG decoder/parser (unverified); the SMT solver
  (external oracle); the ZFC model axioms from Chapter 3; anything `axiom`-tagged (audit
  `SMT/Reasoning/Axioms.lean`).
- **7.7.2 Limitations.** `min`, `max`, `card` are unproven stubs (encoder throws; induction cases
  vacuous). Supported B fragment vs full B. Representation blow-up from loosening. Performance is
  out of scope (Chapter 9, evaluation).
- **7.7.3 Outlook.** One paragraph: closing the stubs, richer arithmetic, tighter representations.

---

## 2. The semantic bridge — precise statements to write (§7.2)

Let `α, β : BType`. All objects below live in the shared ZFSet universe.

- **Type image.** `int^SMT=int`, `bool^SMT=bool`, `(prod α β)^SMT = pair α^SMT β^SMT`,
  `(set α)^SMT = α^SMT → bool`.
- **Canonical iso** `ζ_α : ⟦α⟧ᶻ → ⟦α^SMT⟧ᶻ`:
  - `ζ_int = ζ_bool = id`;
  - `ζ_{prod α β} = ζ_α ⊗ ζ_β` (componentwise on pairs);
  - `ζ_{set α}(𝒟) = λ (w : ⟦α^SMT⟧ᶻ). ⊤ if η_α(w) ∈ 𝒟 else ⊥` — the characteristic predicate of the
    canonical image `𝒟^!`.
  - Theorem: `ζ_α` is a ZF bijection `⟦α⟧ᶻ ≅ᶻ ⟦α^SMT⟧ᶻ`.
- **Retraction** `η_α : ⟦α^SMT⟧ᶻ → ⟦α⟧ᶻ`:
  - `η_int=η_bool=id`; `η_{prod α β}=η_α ⊗ η_β`;
  - `η_{set β}(F) = { x ∈ ⟦β⟧ᶻ | F(ζ_β x) = ⊤ }`.
- **Triangle identities.** `η_α ∘ ζ_α = id_{⟦α⟧ᶻ}` and `ζ_α ∘ η_α = id_{⟦α^SMT⟧ᶻ}`.
- **Canonical image.** `𝒟^! = { y ∈ ⟦α^SMT⟧ᶻ | η_α(y) ∈ 𝒟 }`.
- **Bridge lemma (the workhorse).** If `η_{set β}(F) = X` then for all `x ∈ ⟦β⟧ᶻ`,
  `x ∈ X ⟺ F(ζ_β x) = ⊤`.
- **Agreement.** `⟨X,α⟩ ≘ᶻ ⟨X',α'⟩ ⟺ α' = α^SMT ∧ η_α(X') = X`; valuation agreement pointwise;
  the functor `Δ ↦ Δ^SMT`.

Macros already available: `\toSMT{α}`, `\canon{α}` (ζ), `\retr{α}` (η), `\interpZ`, `\interpB`,
`\interpS`, `\denval`, `\semrel` (≘), `\BDom`, `\SDom`. New macro likely needed: canonical image
`\cimg{α}{𝒟}` (set-level `𝒟^!`) — see §9.

---

## 3. Encoding-rule catalogue (§7.3), monad-free

Notation: `t ↦ (t', σ)` means B term `t` encodes to SMT term `t'` of SMT type `σ`. `Γ` is the
ambient SMT typing context; `x!` a loosened copy; `⊔` the representation join (Chapter 6).

**Atoms / literals**
- `var v ↦ (var v, Γ(v))`
- `int n ↦ (int n, int)`
- `bool b ↦ (bool b, bool)`

**Arithmetic / logic** (operands re-encoded to `int`/`bool`)
- `x + y ↦ (x' + y', int)`, similarly `-`, `*`
- `x ≤ y ↦ (x' ≤ y', bool)`
- `x ∧ y ↦ (x' ∧ y', bool)`, `¬x ↦ (¬x', bool)`

**Pairs**
- `x ↦ y ↦ (pair x' y', pair α β)` with `x ↦ (x',α)`, `y ↦ (y',β)`

**Base-type sets** (constant-true characteristic predicates)
- `ℤ ↦ (λ z:int. ⊤, int → bool)`
- `𝔹 ↦ (λ z:bool. ⊤, bool → bool)`

**Set formers**
- `𝒫(S)`: if `S' : α → bool` (a set), `↦ (λ E. ∀ x. E(x) ⇒ S'(x), (α→bool)→bool)`; if
  `S' : α → option β` (a function), `↦ (λ f. ∀ x y. f(x)=y ⇒ S'(x)=y, …)`.
- `A × B ↦ (λ p. ∃ a b. A'(a) ∧ B'(b) ∧ p = (a,b), (α×β)→bool)`
- `A ⇸ B ↦ (λ R. (∀ x y. R(x,y) ⇒ A'(x) ∧ B'(y)) ∧ (∀ x y y'. R(x,y) ∧ R(x,y') ⇒ y=y'), …)`

**Comprehension / lambda**
- `{ vs ∈ D | P }`: `D` a function `↦ λ xs. ite P (some D(xs)) none`; `D` a set
  `↦ λ z. ite (D'(z)) P[destr z] ⊥`.
- `λ vs ∈ D. P ↦ (λ z. D'(z.π₁) ∧ (z.π₂ = P[destr z.π₁]), (τ×γ)→bool)` — the graph.

**Cast layer** (bring operands to a common representation, then combine)
- `A = B ↦ castEq`: if same type `A'=B'`; else loosen the smaller up, assert equality ∧ loosen-spec.
- `x ∈ S ↦ castMembership`: apply the (possibly loosened) characteristic predicate to the
  (possibly loosened) element; relation case dispatches on `fst/snd`.
- `S ∪ T ↦ castUnion`: common type `γ→bool` ⟹ `λ z. S!(z) ∨ T!(z)`.
- `S ∩ T ↦ castInter`: `λ z. S!(z) ∧ T!(z)`.
- `f @ x ↦ castApp`: introduce fresh partial function `f!!`, return `the (f!! x')`.

**Quantifier**
- `∀ vs ∈ D. P ↦ (∀ zs. (⋀ᵢ specᵢ) ⇒ (zs ∈ D ⇒ P), bool)` with cast helpers bound universally and
  guarded by their specs.

Migrate the old *Encoding algorithm* (union) verbatim as the worked cast example.

---

## 4. Soundness — invariant, theorem, spine, cases (§7.4)

**Invariant.** `η_α(⟦t'⟧ˢ) = ⟦t⟧ᴮ` and `⊢ˢ t' : α^SMT`.

**Main theorem (clean form).** For `Γ_B ⊢ t : α` well-typed and well-defined, with a valuation `Δ`
agreeing with an SMT valuation `Δ^SMT` (`RValuation`), the encoding `t ↦ (t', α^SMT)` yields a
well-typed `t'` that denotes, with `⟨⟦t⟧ᴮ, α⟩ ≘ᶻ ⟦t'⟧ˢ`.

**Hypotheses kept after abstraction:** well-definedness `wd t`; valuation agreement; well-typedness.
**Hypotheses dropped:** used-vars monotonicity, `Λ ⊆ Γ'`, `Γ'.keys ⊆ usedVars`, none-outside-used,
the `Δ,Δ₀,Δ'` extension chain (all fold into "the bridge extends to valuations").

**Lemma spine (prove/import once, cite everywhere).**

| Lemma | Statement | Used by |
|---|---|---|
| round-trip-L | `η_α ∘ ζ_α = id` | every case |
| round-trip-R | `ζ_α ∘ η_α = id` on image | mem, eq, collect, lambda |
| bridge | `η_{set β}(F)=X ⟹ (x∈X ⟺ F(ζ_β x)=⊤)` | union, inter, mem, pow, cprod, pfun, collect, lambda |
| canon-image | `mem_canonicalImage_iff` | union/inter, set, pfun, lambda |
| loosening-corr | Chapter 6: `x!` is the cast image of `x`, value-preserving | union, inter, mem, app, all |
| subst-under-binder | denotation of `P[destr z]` | collect, lambda, all |
| totality/determinism | every well-typed encoded term denotes uniquely | every case |

**Per-family sketches:** see §7.4.3–7.4.9 above; full detail for union (migrated), sketch for the
rest. Hardest three: `all` (biggest, guarded-universal soundness), `pow`/`cprod` (largest single
file), `lambda` (graph + substitution + body totality). Note `min`/`max`/`card` vacuous.

---

## 5. Proof obligations (§7.5)

`encode` = `encodeTypeContext ⨾ encodeDefs ⨾ encodeDistinctFinite ⨾ encodeProofObligations ⨾
finalBulkDeclare`. Per PO: local context pushed, defs and hypotheses asserted, each goal negated and
`check-sat`. End-to-end statement: *script unsat ⟹ PO valid*, derived from §7.4 term soundness and
the semantics of assertion + negation. Close the running example.

---

## 6. Implementation (§7.6) — migrate, demote

Move `lean-implementation-architecture.tex` → §7.6.1 and `binders-names-contexts.tex` → §7.6.2
essentially as-is; reframe the opening so it reads as subordinate ("the mathematical rules above are
realised as follows"). Drop the `\inlremark{Decide if we keep this.}` — keep the `eraseFromContext`
example, it is illuminating. Optionally add §7.6.3 mapping rules to clauses.

---

## 7. Discussion (§7.7)

TCB (kernel, decoder, solver, ZF axioms, `SMT/Reasoning/Axioms.lean`); limitations (`min/max/card`
stubs, B-fragment coverage, loosening blow-up); one-paragraph outlook.

---

## 8. Lemma / case dependency map (figure to draw in §7.4.10)

```
                 round-trip-L (η∘ζ=id)
                   /   |    |    \        \
                var  arith  base  app   (everything)
                            sets
   bridge (η_set F = char-pred at ζ) ── union, inter, mem, pow, cprod, pfun, collect, lambda
   round-trip-R (ζ∘η=id) ───────────── mem, eq, collect, lambda
   loosening-corr (Ch.6) ───────────── union, inter, mem, app, all
   subst-under-binder ──────────────── collect, lambda, all
   witnesses (existence+totality) ──── all
```

---

## 9. Macros: reuse and additions

**Reuse (already in `macros.tex`):** `\toSMT`, `\canon`, `\retr`, `\interpB/S/Z`, `\denval`,
`\semrel`, `\castable`, `\castpath`, `\lgf`, `\mgf`, `\BDom`, `\SDom`, `\lvar`, `\spec`, all
`…S`/`…Z`/`…B` operator families, `\leancodeptr`/`\beerref` for doc links.

**Add to `macros.tex` (proposed):**
- `\cimg[2]{#1}{#2}` → canonical image `#2^{!}_{#1}` or `\canon{#1}[#2]`, for `𝒟^!`. Pick a form
  consistent with `\lvar` (which already uses the `!` superscript for the term-level loosened var).
- `\bridge`-free: none needed.
- Possibly `\denS`/`\denB` shorthands if `\interpS`/`\interpB` get heavy — optional.
- A `theorem`-style environment alias for "case lemmas" if we want the `[encodeTerm\_spec.union\_case]`
  tag style used already in `mechanised-correctness.tex` (that bracket-tag pattern is worth keeping).

---

## 10. Migration map (old file → new home)

| Old file | Disposition |
|---|---|
| `overview.tex` | → `introduction.tex` (renamed, expanded per §7.1) |
| `semantic-encoding-proof-obligations.tex` | → `proof-obligations.tex` (§7.5) |
| `translation-types-expressions-predicates.tex` | → folded into `encoding-rules.tex` (§7.3) |
| `smt-lib-script-generation.tex` | → folded into `proof-obligations.tex` (§7.5.2) |
| `lean-implementation-architecture.tex` | → `implementation.tex` §7.6.1 (migrated) |
| `binders-names-contexts.tex` | → `implementation.tex` §7.6.2 (migrated) |
| `mechanised-correctness.tex` | split: retract preamble → `semantic-bridge.tex` §7.2.3; encoding algorithm → `encoding-rules.tex` §7.3.5; union theorem+proof+note → `soundness.tex` §7.4.5 |
| `trusted-computing-base.tex` | → `discussion.tex` §7.7.1 |
| `limitations.tex` | → `discussion.tex` §7.7.2 |

New `beer.tex` input order: introduction, semantic-bridge, encoding-rules, soundness,
proof-obligations, implementation, discussion.

Nothing is lost: the substantive prose (implementation architecture, binders discipline, union case,
retraction definition) is carried into its new home; empty stubs are simply renamed. Git history
retains the originals regardless.

---

## 11. Key Lean sources (for writing each section)

- Bridge: `SMT/Reasoning/Defs.lean` (`toSMTType`, `canonicalIsoSMTType`, `retract`,
  `retract_of_canonical`, `canonicalIso_composition_retract`, `canonicalImage`, `RDom`,
  `RenamingContext.toSMT`).
- Rules: `Encoder/Encoder.lean` (`encodeTerm`, `encode…`), `Encoder/Loosening/Rules.lean`,
  `Encoder/Loosening/Castable.lean`, `Encoder/Loosening/Loosening.lean`.
- Soundness: `SMT/Reasoning/EncodeTermCorrect.lean` (induction skeleton),
  `SMT/Reasoning/Basic/EncodeTermCorrect*.lean` (per case),
  `SMT/Reasoning/Basic/AllCaseHelpers.lean`, `.../AbstractSubstDenote.lean`,
  `.../DenotationTotality.lean`, `.../CastMembershipSpec.lean`, `SMT/Reasoning/Lemmas.lean`,
  `SMT/Reasoning/SubstLemmas.lean`.
- POs: `Encoder/Encoder.lean` (`encodeProofObligation`, `encode`), `POGReader/*`.
- TCB: `SMT/Reasoning/Axioms.lean`, `CustomPrelude.lean`.

Use `/lean-proofs-math` per case when drafting §7.4, cross-referencing the actual proof file.

---

## 12. Open decisions (to confirm while writing)

1. Running-example PO: pick a concrete small POG (union or membership) from `benchmark/dataset-pog`.
2. How much of the `ζ_{set}` bijectivity proof to show vs cite (recommend: state, cite formalization).
3. Whether §7.6.3 (rules→code table) earns its place or is cut for concision.
4. Notation for the canonical image (`\cimg` form).
5. Whether to give `castApp`'s `f!!` construction in the rules (§7.3.5) or only in soundness (§7.4.6).
