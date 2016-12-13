Require Import Nat CSet Take.

Record StableFresh :=
  {
    stable_fresh :> set nat -> nat -> nat;
    stable_fresh_spec : forall G x, stable_fresh G x ∉ G;
    stable_fresh_ext : forall G G', G [=] G' -> forall x, stable_fresh G x = stable_fresh G' x
  }.

Hint Resolve stable_fresh_spec stable_fresh_ext.

Section FreshListStable.

  Variable fresh : StableFresh.

  Fixpoint fresh_list_stable (G:set nat) (xl:list nat) : list nat :=
    match xl with
      | nil => nil
      | x::xl => let y := fresh G x in y::fresh_list_stable {y;G} xl
    end.

  Lemma fresh_list_stable_length (G:set nat) xl
  : length (fresh_list_stable G xl) = length xl.
  Proof.
    general induction xl; eauto. simpl. f_equal; eauto.
  Qed.

  Definition fresh_set_stable (G:set nat) L : set nat :=
    of_list (fresh_list_stable G L).

  Lemma fresh_list_stable_spec
    : forall (G:set nat) L, disj (of_list (fresh_list_stable G L)) G.
  Proof.
    intros. general induction L; simpl; intros; eauto.
    - hnf; intros. cset_tac'.
      + eapply stable_fresh_spec in H0; eauto.
      + eapply IHL; eauto; cset_tac.
  Qed.

  Lemma fresh_set_stable_spec
  : forall (G:set nat) L, disj (fresh_set_stable G L) G.
  Proof.
    eapply fresh_list_stable_spec.
  Qed.

  Lemma fresh_list_stable_nodup (G: set nat) L
    : NoDupA eq (fresh_list_stable G L).
  Proof.
    general induction L; simpl; eauto.
    econstructor; eauto. intro.
    eapply fresh_list_stable_spec.
    eapply InA_in. eapply H.
    cset_tac; eauto.
  Qed.

End FreshListStable.

Lemma fresh_list_stable_ext n G G' (f:StableFresh)
  : (forall x G G', G [=] G' -> f G x = f G' x)
    -> G [=] G'
    -> fresh_list_stable f G n = fresh_list_stable f G' n.
Proof.
  intros EXT EQ. general induction n; simpl.
  - reflexivity.
  - f_equal; eauto.
    eapply IHn; eauto.
    erewrite EXT, EQ; eauto; reflexivity.
Qed.

Lemma fresh_list_stable_get (fresh : StableFresh) (G: set nat) L x n
  : get (fresh_list_stable fresh G L) n x
    -> exists y, get L n y /\
           x = fresh (of_list (take n (fresh_list_stable fresh G L)) ∪ G) y.
Proof.
  intros Get. general induction L; simpl in *.
  - isabsurd.
  - inv Get.
    + simpl. erewrite stable_fresh_ext; eauto.
      eexists; split; eauto with get. clear; cset_tac.
    + edestruct IHL; eauto; dcr; subst.
      eexists; split; eauto using get.
      simpl. eapply stable_fresh_ext. clear; cset_tac.
Qed.

Lemma fresh_list_stable_In (fresh : StableFresh) (G: set nat) L x
  : x ∈ of_list (fresh_list_stable fresh G L)
    -> exists y G', y ∈ of_list L /\
           x = fresh G' y /\ G ⊆ G'.
Proof.
  intros Get.
  eapply of_list_get_first in Get; eauto; dcr.
  eapply fresh_list_stable_get in H; dcr; subst.
  cset_tac'. do 2 eexists; split; eauto.
  eapply get_in_of_list; eauto.
Qed.

Hint Resolve fresh_list_stable_length : len.
