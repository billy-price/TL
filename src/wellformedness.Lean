import definitions

@[user_attribute]
meta def WF_rules : user_attribute :=
{ name := `WF_rules,
  descr := "lemmas usable to prove Well Formedness" }


meta def tactic.interactive.WF_prover : tactic unit:= do `[apply_rules WF_rules]

namespace TT

open list
local notation l₁ ++ l₂ := list.append l₁ l₂


variables {Γ Δ : list type}
variables {p q r φ a b α : term}
variables {A B Ω' : type}
-- Ω' is just a fake/variable version of Ω so we don't need to bother proving
-- that it must be Ω itself.'

attribute [WF_rules]
WF.star WF.top WF.bot WF.and WF.or WF.imp WF.elem WF.pair WF.var WF.comp WF.all WF.ex

meta def WF_cases : tactic unit := do `[intro h, cases h, assumption]

lemma WF.and_left   : WF Γ Ω' (p ⋀ q) → WF Γ Ω' p := by WF_cases
lemma WF.and_right  : WF Γ Ω' (p ⋀ q) → WF Γ Ω' q := by WF_cases
lemma WF.or_left    : WF Γ Ω' (p ⋁ q) → WF Γ Ω' p := by WF_cases
lemma WF.or_right   : WF Γ Ω' (p ⋁ q) → WF Γ Ω' q := by WF_cases
lemma WF.imp_left   : WF Γ Ω' (p ⟹ q) → WF Γ Ω' p := by WF_cases
lemma WF.imp_right  : WF Γ Ω' (p ⟹ q) → WF Γ Ω' q := by WF_cases
lemma WF.pair_left  : WF Γ (A 𝕏 B) ⟪a,b⟫ → WF Γ A a := by WF_cases
lemma WF.pair_right : WF Γ (A 𝕏 B) ⟪a,b⟫ → WF Γ B b := by WF_cases
lemma WF.comp_elim  : WF Γ (𝒫 A) ⟦A | φ⟧ → WF (A::Γ) Ω φ := by WF_cases
lemma WF.all_elim   : WF Γ Ω' (∀' A φ) → WF (A::Γ) Ω' φ := by WF_cases
lemma WF.ex_elim    : WF Γ Ω' (∃' A φ) → WF (A::Γ) Ω' φ := by WF_cases

@[WF_rules]
lemma WF.iff : WF Γ Ω p → WF Γ Ω q → WF Γ Ω (p ⇔ q) := by {intros, WF_prover}

lemma iff_elim : WF Γ Ω' (p ⇔ q) → WF Γ Ω' p ∧ WF Γ Ω' q :=
  by intro h; split; cases h; apply WF.imp_left; assumption

@[WF_rules]
lemma WF.lift (K Δ Γ : context) (A : type) (a : term) : WF (K ++ Γ) A a → WF (K ++ Δ ++ Γ) A (lift (length Δ) (length K) a) :=
begin
  intro wfa,
  generalize_hyp e : K ++ Γ = Γ' at wfa,
  induction wfa generalizing K,
  case WF.all  : Γ' A' ψ wfψ ih {subst e, constructor, refine ih (A' :: K) _, refl},
  case WF.ex   : Γ' A' ψ wfψ ih {subst e, constructor, refine ih (A' :: K) _, refl},
  case WF.comp : Γ' A' ψ wfψ ih {subst e, constructor, refine ih (A' :: K) _, refl},
  case WF.var  : Γ' A' n h₁ 
  {
    subst e,simp,
    split_ifs with h₂; sorry
  },
  repeat {sorry}
end

@[WF_rules]
lemma WF.lift_once {Γ A a B} : WF Γ A a → WF (B :: Γ) A (^a) :=
  by {intros, apply WF.lift [] [B] Γ, assumption}

@[WF_rules]
lemma WF.eq {Γ} {a₁ a₂} (A : type) : WF Γ A a₁ → WF Γ A a₂ → WF Γ Ω (a₁ ≃[A] a₂) :=
  by {intros, apply_rules [WF_rules];refl}

lemma WF.drop {Γ A a B} : WF (B :: Γ) A (^a) → WF Γ A a := sorry

@[simp]
lemma lift_zero_rfl {k} {a : term} : lift 0 k a = a :=
  by induction a generalizing k;simp *

@[simp]
lemma WF.lift_closed {A d} (a : term) : WF [] A a → lift d 0 a = a :=
begin
  suffices : ∀ G A a, WF G A a → lift d (list.length G) a = a,
  { exact this _ _ _ },
  introv wf,
  induction wf; simp * at *,
  exact if_neg (not_le_of_gt (list.nth_eq_some.1 wf_a).fst)
end

lemma WF.add_context {Γ Δ : list type} {A a}: WF Γ A a → WF (Γ ++ Δ) A a :=
begin
  intro wf,
  induction wf,
  case WF.var : Γ A n eq {
    apply WF.var, erw nth_append, assumption, exact (nth_eq_some.mp eq).fst 
  },
  all_goals {WF_prover}
end

lemma WF.closed_add_context {Γ a A} : WF [] A a → WF Γ A a :=
  by {intro wf, rw ←nil_append Γ, exact WF.add_context wf}

lemma WF.subst {Γ B b p} : WF Γ B b → WF (B :: Γ) Ω p → WF Γ Ω ⁅p // b⁆ := sorry

lemma WF.proof_terms {Γ} {p q} : entails Γ p q → WF Γ Ω p ∧ WF Γ Ω q :=
begin
  intro ent,
  induction ent,
  any_goals {split;WF_prover;refl},
  any_goals {split; simp * at *;WF_prover;refl},
  case entails.and_left   : _ _ _ _ _ ih {exact ⟨ih.1, WF.and_left ih.2⟩},
  case entails.and_right  : _ _ _ _ _ ih {exact ⟨ih.1, WF.and_right ih.2⟩},
  case entails.or_left    : _ _ _ _ _ ih {split, any_goals {simp * at *}, exact WF.or_left ih.1},
  case entails.or_right   : _ _ _ _ _ ih {split, any_goals {simp * at *}, exact WF.or_right ih.1},
  case entails.imp_to_and : _ _ _ _ _ ih {split, apply WF.and, exact ih.1, exact WF.imp_left ih.2, exact WF.imp_right ih.2},
  case entails.and_to_imp : _ _ _ _ _ ih {split, exact WF.and_left ih.1, apply WF.imp, exact WF.and_right ih.1, exact ih.2},
  case entails.weakening  : _ _ _ _ _ ih {split; apply WF.add_context, tidy},
  case entails.all_elim   : _ _ _ _ _ ih {exact ⟨WF.lift_once ih.1, WF.all_elim ih.2⟩},
  case entails.all_intro  : _ _ _ _ _ ih {exact ⟨WF.drop ih.1, WF.all ih.2⟩},
  case entails.ex_elim    : _ _ _ _ _ ih {exact ⟨WF.lift_once ih.1, WF.ex_elim ih.2⟩},
  case entails.ex_intro   : _ _ _ _ _ ih {exact ⟨WF.drop ih.1, WF.ex ih.2⟩},
  case entails.sub        : Γ B b p q wfb ent ih {
    suffices : ∀ p, WF (B :: Γ) Ω p → WF Γ Ω (⁅p // b⁆), from ⟨this p ih.1, this q ih.2⟩,
    intros _ wfp, exact WF.subst wfb wfp
  },
end

lemma WF.proof_left  {Γ p q} : entails Γ p q → WF Γ Ω p :=
  assume ent, (WF.proof_terms ent).left
lemma WF.proof_right {Γ p q} : entails Γ p q → WF Γ Ω q :=
  assume ent, (WF.proof_terms ent).right

end TT