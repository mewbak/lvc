Require Export Setoid Coq.Classes.Morphisms.
Require Export Sets SetInterface SetConstructs SetProperties CSetComputable.
Require Import EqDec CSetNotation Util CSetTac.

Section theorems.
  Variable X : Type.
  Context `{OrderedType X}.

  Lemma single_spec_neq (x y:X)
    : x ∈ {{ y }} -> x === y.
  Proof.
    cset_tac.
  Qed.

  Lemma neq_not_in_single (x y:X)
    :  x =/= y -> ~x ∈ {{y}}.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_empty (s:set X)
    : s \ ∅ [=] s.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_in_in s t (x:X)
    : x ∈ (s \ t) -> x ∈ s /\ ~x ∈ t.
  Proof.
    cset_tac.
  Qed.

  Lemma in_in_minus s t (x:X)
    : x ∈ s -> ~x ∈ t -> x ∈ (s \ t).
  Proof.
    cset_tac.
  Qed.

  Lemma union_comm (s t:set X)
    : s ∪ t [=] t ∪ s .
  Proof.
    cset_tac.
  Qed.

  Lemma minus_inane_set (s t:set X)
    : s ∩ t [=] ∅ -> (s \ t) [=] s.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_union_set (s t:set X)
    : s ∩ t [=] ∅ -> ((s ∪ t) \ t) [=] s.
  Proof.
    cset_tac.
  Qed.


  Lemma in_minus_neq s (x y:X)
    : x =/= y -> x ∈ s
    -> x ∈ (s\{{y}}).
  Proof.
    cset_tac.
  Qed.

  Lemma add_inane s (x:X)
    : x ∈ s
    -> s [=] ({{x}} ∪ s).
  Proof.
    cset_tac.
  Qed.

  Lemma in_single_union s (y:X)
    : y ∈ {{y}} ∪ s.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_union (s t u:set X)
    : (s \ t \ u) [=] s \ (t ∪ u).
  Proof.
    cset_tac.
  Qed.

  Lemma incl_empty (s:set X)
    : ∅ ⊆ s.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_singleton (x:X) (s:set X)
    : x ∈ s -> singleton x ⊆ s.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_incl (s t:set X)
    : (s\t) ⊆ s.
  Proof.
    cset_tac.
  Qed.

  Lemma empty_neutral_union (s:set X)
    : ∅ ∪ s [=] s.
  Proof.
    cset_tac.
  Qed.


  Lemma incl_add s (x:X)
    :  s ⊆ ({{x}} ∪ s).
  Proof.
    cset_tac.
  Qed.

  Lemma incl_refl (s:set X)
  : s ⊆ s.
  Proof.
    reflexivity.
  Qed.

  Lemma incl_right (s t:set X)
    :  s ⊆ (t ∪ s).
  Proof.
    cset_tac.
  Qed.

  Lemma incl_add' (s:set X) x
    :  s ⊆ {x; s}.
  Proof.
    cset_tac.
  Qed.

  Lemma in_add' (s:set X) x
    :  x ∈ {x; s}.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_minus (s t : set X)
    :  (s \ t) ⊆ s.
  Proof.
    cset_tac.
  Qed.


  Lemma union_assoc (s t u : set X)
    : s ∪ t ∪ u [=] s ∪ (t ∪ u).
  Proof.
    cset_tac.
  Qed.

  Lemma union_minus_incl (s t:set X)
    : ((t ∪ s) \ t) ⊆ s.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_minus_lr (s s' t t':set X)
    : s ⊆ s' -> t ⊆ t' -> s \ t' ⊆ s' \ t.
  Proof.
    cset_tac.
  Qed.


  Lemma union_idem (s:set X)
    : s ∪ s [=] s.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_in s t (x:X)
    : x ∉ s -> x ∉ t -> x ∉ (s ∪ t).
  Proof.
    cset_tac.
  Qed.

  Lemma union_cases s t (x:X)
    : x ∈ (s ∪ t) -> x ∈ s \/ x ∈ t.
  Proof.
    cset_tac.
  Qed.

  Lemma not_in_union_comp  (s t : set X) x :
    ~x ∈ s /\ ~x ∈ t -> ~x ∈ (s ∪ t).
  Proof.
    cset_tac.
  Qed.

  Lemma not_in_union_decomp s t (x:X)
    : x ∉ (s ∪ t) -> x ∉ s /\ x ∉ t.
  Proof.
    cset_tac.
  Qed.

  Lemma union_left s t (x:X)
    : x ∈ s -> x ∈ (s ∪ t).
  Proof.
    cset_tac.
  Qed.

  Lemma union_right s t (x:X)
    : x ∈ t -> x ∈ (s ∪ t).
  Proof.
    cset_tac.
  Qed.

  Lemma set_fact_2 s t (x:X)
    : (s \ ({{x}} ∪ t)) \ {{x}} [=] s \ ({{x}} ∪ t).
  Proof.
    cset_tac.
  Qed.


  Lemma incl_union_absorption (s t:set X)
    : s ⊆ t -> s ∪ t [=] t.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_union_lr (s s' t t':set X)
    : s ⊆ s' -> t ⊆ t' -> s ∪ t ⊆ s' ∪ t'.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_left (s t:set X)
    : s ⊆ (s ∪ t).
  Proof.
    cset_tac.
  Qed.

  Lemma in_meet (s t:set X) (x:X)
    : x ∈ s -> x ∈ t -> x ∈ s ∩ t.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_in (s t:set X) (x:X)
    : x ∈ s ∩ t -> x ∈ s /\ x ∈ t.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_incl (s t u:set X)
    : s ⊆ u -> s ∩ t ⊆ u.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_comm (s t:set X)
    : s ∩ t [=] t ∩ s.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_meet (s t:set X)
    : s ⊆ t -> s [=] s ∩ t.
  Proof.
    cset_tac.
  Qed.


  Lemma minus_meet (s t u:set X)
    : (s \ t) ∩ u [=] s ∩ u \ t.
  Proof.
    cset_tac.
  Qed.

  Lemma set_incl (s t: set X)
    : s ⊆ t -> t ⊆ s -> t [=] s.
  Proof.
    cset_tac.
  Qed.


  Lemma elements_nil_eset (s : set X) :
    s [=] ∅ <-> elements s = nil.
  Proof.
    rewrite <- elements_Empty. cset_tac.
  Qed.

  Lemma union_meet_distr_r (s t u : set X) :
    (s ∪ t) ∩ u [=] (s ∩ u) ∪ (t ∩ u).
  Proof.
    cset_tac.
  Qed.

  Lemma union_is_empty (s t : set X) :
    s ∪ t [=] ∅ -> (s [=] ∅ /\ t [=] ∅).
  Proof.
    cset_tac.
  Qed.

  Lemma smaller_meet_empty (s t u : set X) :
    (s ∪ t) ∩ u [=] ∅ -> t ∩ u [=] ∅.
  Proof.
    cset_tac.
  Qed.

  Lemma empty_intersection_in_one_not_other (s t : set X) x :
    s ∩ t [=] ∅ -> x ∈ s -> ~ x ∈ t.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_assoc (s t u : set X)
    : s ∩ t ∩ u [=] s ∩ (t ∩ u).
  Proof.
    cset_tac.
  Qed.

  Lemma incl_meet_lr (s s' t t':set X)
    : s ⊆ s' -> t ⊆ t' -> s ∩ t ⊆ s' ∩ t'.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_in_union (s t : set X)
    : s ∩ t ⊆ s ∪ t.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_dist_union (s t u:set X)
    : (s ∪ t) \ u [=] (s \ u) ∪ (t \ u).
  Proof.
    cset_tac.
  Qed.

  Lemma minus_dist_intersection (s t u:set X)
    : (s ∩ t) \ u [=] (s \ u) ∩ (t \ u).
  Proof.
    cset_tac.
  Qed.


  Lemma incl_not_member (s t:set X) x
    : s ⊆ t -> ~x ∈ t -> ~x ∈ s.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_meet_empty (s t u:set X)
    : s ⊆ t -> u ∩ t [=] empty -> u ∩ s [=] empty.
  Proof.
    cset_tac.
  Qed.

  Lemma union_incl_split (s t u : set X)
    : s ⊆ u -> t ⊆ u -> s ∪ t ⊆ u.
  Proof.
    cset_tac.
  Qed.

  Lemma union_minus_remove (a b : set X)
        : (a ∪ b) \ a [=] b \ a.
  Proof.
    cset_tac.
  Qed.

  Lemma minus_incl_meet_special2 (c c' d : set X)
    : c ⊆ d
    -> c ⊆ c'
    -> c ∩ (c' \ (c \ d)) [=] c.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_minus (s t : set X)
    : s ∩ (t \ s) [=] ∅.
  Proof.
    cset_tac.
  Qed.

  Lemma meet_in_left (s t : set X)
    : s ∩ t ⊆ s.
  Proof.
    cset_tac.
  Qed.

  Lemma not_in_meet_empty (D:set X) x
    : ~ x ∈ D
    -> D ∩ {{x}} [=] ∅.
  Proof.
    cset_tac.
  Qed.

  Lemma incl_eq (s t:set X)
    : s ⊆ t -> t ⊆ s -> t [=] s.
  Proof.
    cset_tac.
  Qed.

  End theorems.

  Section moretheorems.

  Require Import List.
  Variable X : Type.
  Context `{OrderedType X}.

  Hypothesis equiv_is_eq : _eq = eq.


End moretheorems.

Definition addf {X} `{OrderedType X} {Y} `{OrderedType Y} (f:X->Y) :=
  (fun x t => add (f x) t).

Add Parametric Morphism {X} `{OrderedType X} {Y} `{OrderedType Y} (f:X->Y)
  `{Proper _ (_eq ==> _eq) f}
  : (addf f)
  with signature
    _eq ==> Equal ==> Equal as addf_morphism.
Proof.
  intros. unfold addf. rewrite H2. rewrite H3. reflexivity.
Qed.

Add Parametric Morphism {X} `{OrderedType X} {Y} `{OrderedType Y} (f:X->Y)
  : (addf f)
  with signature
    eq ==> Equal ==> Equal as addf_morphism2.
Proof.
  intros. unfold addf. rewrite H1. reflexivity.
Qed.

Lemma addf_transpose {X} `{OrderedType X} {Y} `{OrderedType Y} (f:X->Y)
 : transpose Equal (addf f).
Proof.
  hnf; intros.
  unfold addf. hnf. intros. rewrite add_add. split; eauto.
Qed.


Lemma minus_union_both X `{OrderedType X} (s t: set X) x
  : x ∉ s -> s \ t [=] (s ∪ {{x}}) \ (t ∪ {{x}}).
Proof.
  cset_tac; firstorder.
Qed.

Lemma list_eq_eq {X} {L L':list X}
  : list_eq eq L L' <-> L = L'.
Proof.
  split; intros. eapply list_eq_ind; intros; subst; f_equal; eauto.
  general induction L; econstructor; eauto.
Qed.

Lemma minus_idem X `{OrderedType X} (s t:set X)
: s \ t [=] (s \ t) \ t.
Proof.
  cset_tac; intuition.
Qed.

Lemma meet_incl_eq {X} `{OrderedType X} (s s' t t':set X)
: t' ⊆ t -> s ∩ t [=] s' ∩ t -> s ∩ t' [=] s' ∩ t'.
Proof.
  cset_tac.
Qed.

Lemma InA_in {X} `{OrderedType X} x L
 : InA _eq x L <-> x ∈ of_list L.
Proof.
  split; intros.
  general induction L; cset_tac.
  general induction L; cset_tac.
Qed.

Smpl Add 50
     match goal with
      | [ H : @SetInterface.In _ (@SOT_as_OT _ _ _ ) _ ?x (of_list ?l), I : InA eq ?x ?l -> False |- _ ]
        => exfalso; eapply InA_in in H; simpl in H; eapply I; eapply H
     end : cset.


Lemma minus_minus_eq {X} `{OrderedType X} (s t : set X)
  : s [=] s \ (t \ s).
Proof.
  cset_tac.
Qed.


Lemma union_incl_left {X} `{OrderedType X} (s t u: set X)
: s ⊆ t -> s ⊆ t ∪ u.
Proof.
  cset_tac.
Qed.

Lemma incl_set_left X `{OrderedType X} (s t : set X)
: s [=] t -> s [<=] t.
Proof.
  cset_tac.
Qed.

Lemma minus_inter_empty X `{OrderedType X} s t u
: s ∩ t [=] s ∩ u
  -> s \ t [=] s \ u.
Proof.
  cset_tac.
Qed.

Lemma union_eq_decomp X `{OrderedType X} s s' t t'
: s [=] s' -> t [=] t' -> s ∪ t [=] s' ∪ t'.
Proof.
  intros A B; rewrite A, B; eauto.
Qed.

Lemma add_struct_incl X `{OrderedType X} x s t
: s ⊆ t
  -> {x; s} ⊆ {x; t}.
Proof.
  cset_tac.
Qed.

Lemma add_struct_incl' X `{OrderedType X} x y s t
  : x === y
    -> s ⊆ t
    -> {x; s} ⊆ {y; t}.
Proof.
  cset_tac.
Qed.

Hint Resolve add_struct_incl add_struct_incl' : cset.

Lemma add_struct_eq X `{OrderedType X} x s t
: s [=] t
  -> {x; s} [=] {x; t}.
Proof.
  cset_tac.
Qed.

Lemma add_struct_eq' X `{OrderedType X} x y s t
  : x === y
     -> s [=] t
  -> {x; s} [=] {y; t}.
Proof.
  cset_tac.
Qed.

Hint Resolve add_struct_eq add_struct_eq' : cset.

Lemma union_struct_eq_1 X `{OrderedType X} s t u
: s [=] t
  ->  s ∪ u [=] t ∪ u.
Proof.
  cset_tac.
Qed.

Lemma union_struct_eq_2 X `{OrderedType X} s t u
: s [=] t
  ->  u ∪ s [=] u ∪ t.
Proof.
  cset_tac.
Qed.

Lemma not_in_minus X `{OrderedType X} (s t: set X) x
: x ∉ s
  -> x ∉ s \ t.
Proof.
  cset_tac.
Qed.

Lemma equal_minus_empty X `{OrderedType X} s t
  : s [=] t
    -> s [=] t \ {}.
Proof.
  cset_tac.
Qed.

Lemma incl_minus_empty X `{OrderedType X} s t
  : s ⊆ t
    -> s ⊆ t \ {}.
Proof.
  cset_tac.
Qed.

Lemma incl_minus_change X `{OrderedType X} s t x
  : (s \ t) \ {x; {}}[<=]s \ {x; t}.
Proof.
  cset_tac.
Qed.

Lemma incl_minus_union X `{OrderedType X} s t u
  :  (s \ t) \ u [<=] s \ (u ∪ t).
Proof.
  cset_tac.
Qed.

Lemma incl_union_incl_minus X `{OrderedType X} s t u
  : s \ t ⊆ u
    -> s ⊆ t ∪ u.
Proof.
  cset_tac.
Qed.

Lemma incl_meet_split X `{OrderedType X} s t u
  : s ⊆ t -> s ⊆ u -> s ⊆ t ∩ u.
Proof.
  cset_tac.
Qed.

Lemma equiv_minus_union X `{OrderedType X} s t
  : s ⊆ t -> t [=] t \ s ∪ s.
Proof.
  cset_tac'.
Qed.


Lemma diff_subset_equal' X `{OrderedType X} s s'
  : s \ s' [=] {} -> s ⊆ s'.
Proof.
  intros. hnf; intros. exploit (H0 a).
  cset_tac.
Qed.

Smpl Add
     match goal with
     | [ H : Empty ?s |- _ ] => apply empty_is_empty_1 in H
     end : cset.

Lemma not_incl_exists X `{OrderedType X} s t
  :  (s ⊆ t -> False)
     -> exists x, x ∈ s /\ x ∉ t.
Proof.
  pattern s. eapply set_induction; intros.
  - exfalso. eapply H1. cset_tac.
  - rewrite Add_Equal in H2. rewrite H2 in H3.
    decide (x ∈ t).
    + edestruct H0; eauto.
      * intros. eapply H3. cset_tac.
      * cset_tac.
    + eexists x; cset_tac.
Qed.

Smpl Add
     match goal with
     | [ H : ?s ⊆ ?t -> False |- _ ] => eapply not_incl_exists in H
     end : cset.


Lemma not_incl_element X `{OrderedType X} s
  : forall s', ~ s ⊆ s' -> exists x, x ∈ s /\ x ∉ s'.
Proof.
  pattern s. eapply set_induction; intros.
  - cset_tac.
  - rewrite Add_Equal in H2. cset_tac.
Qed.

Lemma minus_minus X `{OrderedType X} (s t : set X) : s \ (s \ t) [=] s ∩ t.
Proof.
cset_tac.
Qed.

Lemma incl_minus_incl X `{OrderedType X} (s t u : set X) : s ⊆ t -> u \ t ⊆ u \ s.
cset_tac.
Qed.

Lemma incl_add_eq X `{OrderedType X}(s t : set X ) (a : X) : {a; t} ⊆ s <-> a ∈ s /\ t ⊆ s.
Proof.
split; intros H0.
- split.
  + eapply H0. cset_tac.
  + rewrite <- H0. cset_tac.
- destruct H as [ain yx]. decide (a ∈ t); cset_tac.
Qed.

Lemma of_list_elements X `{OrderedType X} (s : set X)
 : of_list (elements s) [=] s.
Proof.
  cset_tac'.
  - apply of_list_1 in H0; rewrite <- elements_iff in H0; eauto.
  - rewrite of_list_1; rewrite <- elements_iff; eauto.
Qed.

Lemma incl_union_incl X `{OrderedType X} s t u w
  : t ∪ u ⊆ w -> s ⊆ t -> s ⊆ w.
  cset_tac.
Qed.

Lemma incl_union_right X `{OrderedType X} s t u
: s ⊆ t -> s ⊆ u ∪ t.
Proof.
  cset_tac.
Qed.

Arguments incl_union_right X [H] s t u _ _ _ .

Lemma incl_union_left X `{OrderedType X} s t u
: s ⊆ t -> s ⊆ t ∪ u.
Proof.
  cset_tac.
Qed.

Arguments incl_union_left X [H] s t u _ _ _ .

Lemma incl_add_right X `{OrderedType X} s t x
: s ⊆ t -> s ⊆ {x; t}.
Proof.
  cset_tac.
Qed.


Lemma in_add_left X `{OrderedType X} s x
: x ∈ {x; s}.
Proof.
  cset_tac.
Qed.

Lemma to_list_nil {X} `{OrderedType X}
  : to_list ∅ = nil.
Proof.
  cset_tac.
Qed.


Lemma add_minus_single_eq X `{OrderedType X} x s
  : x ∈ s
    -> {x; s \ singleton x} [=] s.
Proof.
  cset_tac.
Qed.

Hint Resolve add_minus_single_eq : cset.

Lemma add_union X `{OrderedType X} x s
  : {x; s} [=] singleton x ∪ s.
Proof.
  cset_tac.
Qed.

Lemma minus_incl_incl_union X `{OrderedType X} s t u
  : s \ t ⊆ u
    -> s ⊆ t ∪ u.
Proof.
  intros H1. rewrite <- H1. clear H1.
  cset_tac.
Qed.


Lemma empty_neutral_union_r (X : Type) `{OrderedType X} (s : ⦃X⦄)
  : s ∪ ∅ [=] s.
Proof.
  cset_tac.
Qed.

Lemma union_meet_distr_l (X : Type) `{OrderedType X} (s t u : ⦃X⦄)
  : s ∩ (t ∪ u) [=] (s ∩ t) ∪ (s ∩ u).
Proof.
  cset_tac.
Qed.

Lemma meet_union_distr_r (X : Type) `{OrderedType X} (s t u : ⦃X⦄)
  : (s ∩ t) ∪ u [=] (s ∪ u) ∩ (t ∪ u).
Proof.
  cset_tac.
Qed.

Lemma meet_union_distr_l (X : Type) `{OrderedType X} (s t u : ⦃X⦄)
  : s ∪ (t ∩ u) [=] (s ∪ t) ∩ (s ∪ u).
Proof.
  cset_tac.
Qed.

Lemma minus_minus_add X `{OrderedType X} (s t:set X) x
  : s \ {x;t} [=] s \ t \ singleton x.
Proof.
  cset_tac.
Qed.

Lemma add_incl (X : Type) `{OrderedType X} (x : X) (s t : ⦃X⦄)
  : {x; s} ⊆ t -> x ∈ t /\ s ⊆ t.
Proof.
  cset_tac.
Qed.

Lemma of_list_empty (X : Type) `{OrderedType X} (L : list X)
  : of_list L [=] ∅ <-> L = nil.
Proof.
  destruct L; simpl; eauto.
  - split; eauto.
  - split; intros; isabsurd.
    exfalso. cset_tac.
Qed.

Lemma in_singleton (X : Type) `{OrderedType X} (x : X) (s : ⦃X⦄)
  : singleton x ⊆ s -> x ∈ s.
Proof.
  cset_tac.
Qed.

Lemma union_incl_split2 (X : Type) `{OrderedType X} (s t u : ⦃X⦄)
  : s ∪ t ⊆ u -> s ⊆ u /\ t ⊆ u.
Proof.
  cset_tac.
Qed.

Lemma incl_minus_union' (X:Type) `{OrderedType X} (s t u : ⦃X⦄)
  : t ⊆ u -> s \ t ∪ u [=] s ∪ u.
Proof.
  cset_tac.
Qed.

Lemma cap_special_in X `{OrderedType X} G
  : forall x D, x ∈ D -> {x; G} ∩ D [=] {x; G ∩ D}.
Proof.
  cset_tac.
Qed.

Lemma cap_special_notin X `{OrderedType X} G
  : forall x D, x ∉ D -> {x; G} ∩ D [=] G ∩ D.
Proof.
  cset_tac.
Qed.

Lemma For_all_union X `{OrderedType X} (P:X -> Prop) s t
  : For_all P (s ∪ t) <-> For_all P s /\ For_all P t.
Proof.
  unfold For_all. cset_tac.
Qed.
