Require Import Util LengthEq Get Drop Map CSet MoreList DecSolve AllInRel.
Require Import Var Val Exp Env IL OptionR.
Require Import Infra.PartialOrder Terminating Infra.Lattice Annotation.

Set Implicit Arguments.

Lemma option_map_mon T `{PartialOrder T}  U `{PartialOrder U} (a a':option T) (f f': T -> U)
  : a ⊑ a'
    -> (forall x y, x ⊑ y -> f x ⊑ f' y)
    -> option_map f a ⊑ option_map f' a'.
Proof.
  intros A; inv A; simpl;
    clear_trivial_eqs; simpl; eauto using fstNoneOrR.
Qed.


Definition joinTopAnn A `{JoinSemiLattice A} (a:ann A) (b:A) :=
  setTopAnn a (join (getAnn a) b).


Lemma PIR2_zip_setTopAnnO X `{PartialOrder X} (A A':list (ann X)) (B B':list X)
  : poLe A A'
    -> poLe B B'
    -> poLe ((@setTopAnn _) ⊜ A B) (@setTopAnn _ ⊜ A' B').
Proof.
  intros LE_A LE_B; simpl in *.
  general induction LE_A; inv LE_B; simpl; eauto using PIR2.
  - econstructor; eauto.
    eauto using ann_R_setTopAnn.
Qed.

Lemma ann_poLe_joinTopAnn A `{JoinSemiLattice A} (a:A) (b:A) an bn
  : poLe a b
    -> ann_R poLe an bn
    -> ann_R poLe (joinTopAnn an a) (joinTopAnn bn b).
Proof.
  intros.
  inv H2; simpl; econstructor; try eapply join_struct; eauto.
Qed.

Lemma ann_poEq_joinTopAnn A `{JoinSemiLattice A} (a:A) (b:A) an bn
  : poEq a b
    -> ann_R poEq an bn
    -> ann_R poEq (joinTopAnn an a) (joinTopAnn bn b).
Proof.
  intros.
  inv H2; simpl; econstructor; eauto;
    rewrite H1, H3; reflexivity.
Qed.


Lemma PIR2_zip_joinTopAnnO X `{JoinSemiLattice X} (A A':list (ann X)) (B B':list X)
  : poLe A A'
    -> poLe B B'
    -> poLe ((@joinTopAnn _ _ _) ⊜ A B) (@joinTopAnn _ _ _ ⊜ A' B').
Proof.
  intros LE_A LE_B; simpl in *.
  general induction LE_A; inv LE_B; simpl; eauto using PIR2.
  - econstructor; eauto.
    eauto using ann_poLe_joinTopAnn.
Qed.

Lemma PIR2_poEq_zip_setTopAnnO X `{PartialOrder X} (A A':list (ann X)) (B B':list X)
  : poEq A A'
    -> poEq B B'
    -> poEq ((@setTopAnn _) ⊜ A B) (@setTopAnn _ ⊜ A' B').
Proof.
  intros LE_A LE_B; simpl in *.
  general induction LE_A; inv LE_B; simpl; eauto using PIR2.
  - econstructor; eauto.
    eauto using ann_R_setTopAnn.
Qed.

Lemma PIR2_poEq_zip_joinTopAnnO X `{JoinSemiLattice X} (A A':list (ann X)) (B B':list X)
  : poEq A A'
    -> poEq B B'
    -> poEq ((@joinTopAnn _ _ _) ⊜ A B) (@joinTopAnn _ _ _ ⊜ A' B').
Proof.
  intros LE_A LE_B; simpl in *.
  general induction LE_A; inv LE_B; simpl; eauto using PIR2.
  - econstructor; eauto.
    eauto using ann_poEq_joinTopAnn.
Qed.


Instance LowerBounded_ann (s:stmt) A `{LowerBounded A}
  : LowerBounded ({ a : ann bool | annotation s a }) :=
  {
    bottom := exist _ (setAnn bottom s) _
  }.
Proof.
  - eapply setAnn_annotation.
  - intros []. simpl.
    general induction a; simpl; eauto using @ann_R.
    + econstructor; eauto with len.
      intros; inv_get. exploit H1; eauto.
Defined.




Lemma PIR2_setTopAnn_zip_left X (R:X->X->Prop) `{Reflexive _ R} (A:list (ann X)) B
  : PIR2 R (Take.take ❬A❭ B) (getAnn ⊝ A)
    -> PIR2 (ann_R R) (@setTopAnn _ ⊜ A B) A.
Proof.
  intros P. general induction P; destruct A, B; isabsurd; eauto using PIR2.
  simpl in *. clear_trivial_eqs.
  econstructor; eauto.
  eapply ann_R_setTopAnn_left; eauto.
Qed.

Lemma PIR2_joinTopAnn_zip_left X `{JoinSemiLattice X} (A:list (ann X)) B
  : PIR2 poLe (Take.take ❬A❭ B) (getAnn ⊝ A)
    -> PIR2 poEq (@joinTopAnn _ _ _ ⊜ A B) A.
Proof.
  intros P. general induction P; destruct A,B; isabsurd; eauto using PIR2.
  simpl in *. clear_trivial_eqs.
  econstructor; eauto.
  eapply ann_R_setTopAnn_left; eauto.
  eapply poLe_antisymmetric. rewrite pf.
  rewrite join_idempotent. eauto.
  eapply join_poLe.
Qed.

Lemma getAnn_joinTopAnn A `{JoinSemiLattice A} an (a:A)
  : (getAnn (joinTopAnn an a)) = (join (getAnn an) a).
Proof.
  destruct an; simpl; reflexivity.
Qed.

Lemma getAnn_map_joinTopAnn A `{JoinSemiLattice A} an a
  : getAnn ⊝ (@joinTopAnn A _ _ ⊜ an a) = join ⊜ (getAnn ⊝ an) a.
Proof.
  general induction an; simpl; eauto.
  destruct a0; simpl; eauto.
  rewrite IHan. rewrite getAnn_joinTopAnn. reflexivity.
Qed.

Lemma getAnn_map_setTopAnn A an a
  : getAnn ⊝ (@setTopAnn A ⊜ an a) = Take.take ❬an❭ a.
Proof.
  general induction an; simpl; eauto.
  destruct a0; simpl; eauto.
  rewrite getAnn_setTopAnn. f_equal.
  erewrite IHan; eauto.
Qed.

Lemma setTopAnn_map_inv X A B
  : setTopAnn (A:=X) ⊜ A B = A
    -> Take.take ❬A❭ B = getAnn ⊝ A.
Proof.
  intros. general induction A; destruct B; simpl; eauto.
  - exfalso. inv H.
  - simpl in *. inv H.
    rewrite <- ann_R_eq in H1.
    eapply setTopAnn_inv in H1. subst.
    rewrite getAnn_setTopAnn. f_equal.
    rewrite zip_length. rewrite min_l; try omega.
    erewrite IHA; eauto; try omega.
    erewrite getAnn_map_setTopAnn; eauto.
    erewrite IHA; eauto.
    rewrite <- H2. len_simpl.
    decide (length A <= length B).
    rewrite min_l; eauto.
    rewrite min_r; eauto. omega.
Qed.

Lemma joinTopAnn_inv (A : Type) `{JoinSemiLattice A} (an : ann A) (a : A)
  : poEq (joinTopAnn an a) an -> poLe a (getAnn an).
Proof.
  intros.
  rewrite <- H1. rewrite getAnn_joinTopAnn.
  rewrite join_commutative. eapply join_poLe.
Qed.

Lemma ann_R_joinTopAnn_inv (A : Type) `{JoinSemiLattice A} (an : ann A) (a : A)
  : ann_R poEq (joinTopAnn an a) an -> poLe a (getAnn an).
Proof.
  intros.
  eapply joinTopAnn_inv. eapply H1.
Qed.

Lemma joinTopAnn_map_inv X `{JoinSemiLattice X} A B
  : PIR2 poEq (joinTopAnn (A:=X) ⊜ A B) A
    -> PIR2 poLe (Take.take ❬A❭ B) (getAnn ⊝ A).
Proof.
  intros. general induction A; destruct B; simpl; eauto.
  - exfalso. inv H1.
  - simpl in *. inv H1.
    eapply joinTopAnn_inv in pf.
    econstructor; eauto.
Qed.