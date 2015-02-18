Require Import CSet Le Arith.Compare_dec.

Require Import Plus Util Map CMap Status.
Require Import Val Var Env EnvTy IL Annotation Liveness Fresh Sim MoreList.
Require Import Coherence Allocation RenamedApart.

Set Implicit Arguments.


Fixpoint linear_scan (st:stmt) (an: ann (set var)) (ϱ:Map [var, var])
  : status (Map [var, var]) :=
 match st, an with
    | stmtExp x e s, ann1 lv ans =>
      let xv := least_fresh (SetConstructs.map (findt ϱ 0) (getAnn ans\{{x}})) in
        linear_scan s ans (ϱ[x<- xv])
    | stmtIf _ s t, ann2 lv ans ant =>
      sdo ϱ' <- linear_scan s ans ϱ;
        linear_scan t ant ϱ'
    | stmtApp _ _, ann0 _ => Success ϱ
    | stmtReturn _, ann0 _ => Success ϱ
    | stmtExtern x f Y s, ann1 lv ans =>
      let xv := least_fresh (SetConstructs.map (findt ϱ 0) (getAnn ans\{{x}})) in
      linear_scan s ans (ϱ[x<- xv])
    | stmtFun Z s t, ann2 _ ans ant =>
      let Z' := fresh_list least_fresh (SetConstructs.map (findt ϱ 0) (getAnn ans\of_list Z)) (length Z) in
      sdo ϱ' <- linear_scan s ans (ϱ[Z <-- Z']);
        linear_scan t ant ϱ'
    | _, _ => Error "linear_scan: Annotation mismatch"
 end.

Lemma linear_scan_renamedApart_agree' i s al ϱ ϱ' LV alv G
      (sd:renamedApart s al)
      (LS:live_sound i LV s alv)
      (allocOK:linear_scan s alv ϱ = Success ϱ')
: agree_on eq (G \ snd (getAnn al)) (findt ϱ 0) (findt ϱ' 0).
Proof.
  general induction LS; inv sd; simpl in * |- *; try monadS_inv allocOK; eauto.
  - exploit IHLS; eauto.
    rewrite <- map_update_update_agree in X.
    rewrite H8 in X; simpl in *.
    eapply agree_on_incl.
    eapply agree_on_update_inv.
    eapply X.
    instantiate (1:=G). rewrite H9.
    revert H4; clear_all; cset_tac; intuition; eauto.
  - exploit IHLS1; eauto.
    exploit IHLS2; eauto.
    rewrite H11 in X. rewrite H12 in X0. simpl in *.
    etransitivity; eapply agree_on_incl; eauto.
    instantiate (1:=G). rewrite <- H7. clear_all; intro; cset_tac; intuition.
    instantiate (1:=G). rewrite <- H7. clear_all; intro; cset_tac; intuition.
  - exploit IHLS; eauto.
    rewrite <- map_update_update_agree in X.
    rewrite H9 in X; simpl in *.
    eapply agree_on_incl.
    eapply agree_on_update_inv. eapply X.
    instantiate (1:=G).
    rewrite H10. simpl in *.
    revert H5; clear_all; cset_tac; intuition.
  - exploit IHLS1; eauto.
    exploit IHLS2; eauto.
    rewrite <- map_update_list_update_agree in X.
    rewrite H9 in X. rewrite H12 in X0. simpl in *.
    etransitivity; try eapply X0.
    eapply agree_on_incl. eapply update_with_list_agree_inv; try eapply X; eauto.
    rewrite fresh_list_length; eauto.
    instantiate (1:=G). rewrite <- H7.
    revert H5; clear_all; cset_tac; intuition; eauto.
    eapply agree_on_incl; eauto. instantiate (1:=G).
    rewrite <- H7. clear_all; cset_tac; intuition; eauto.
    rewrite fresh_list_length; eauto.
Qed.

Lemma renamedApart_disj s G
: renamedApart s G
  -> disj (fst (getAnn G)) (snd (getAnn G)).
Proof.
  intros. general induction H; simpl.
  - rewrite H3. rewrite H2 in *. simpl in *.
    revert IHrenamedApart H. unfold disj.
    clear_all; cset_tac; intuition; cset_tac; eauto.
  - rewrite H4 in *. rewrite H5 in *. simpl in *.
    rewrite <- H1. rewrite disj_app; eauto.
  - rewrite H0. eauto using disj_empty.
  - rewrite H0. eauto using disj_empty.
  - rewrite H3. rewrite H2 in *. simpl in *.
    revert IHrenamedApart H. unfold disj.
    clear_all; cset_tac; intuition; cset_tac; eauto.
  - rewrite <- H1. repeat rewrite disj_app.
    rewrite H3,H5 in *; simpl in *; eauto.
    split. split; eauto. rewrite incl_right; eauto.
    symmetry; eauto.
Qed.

Lemma linear_scan_renamedApart_agree i s al ϱ ϱ' LV alv
      (sd:renamedApart s al)
      (LS:live_sound i LV s alv)
      (allocOK:linear_scan s alv ϱ = Success ϱ')
: agree_on eq (fst (getAnn al)) (findt ϱ 0) (findt ϱ' 0).
Proof.
  eapply agree_on_incl.
  eapply linear_scan_renamedApart_agree'; eauto.
  instantiate (1:=fst (getAnn al)).
  exploit renamedApart_disj; eauto.
  revert X. unfold disj.
  clear_all; cset_tac; intuition; eauto.
Qed.

Lemma locally_inj_live_agree s ϱ ϱ' ara alv LV
      (LS:live_sound FunctionalAndImperative LV s alv)
      (sd: renamedApart s ara)
      (inj: locally_inj ϱ s alv)
      (agr: agree_on eq (fst (getAnn ara) ∪ snd (getAnn ara)) ϱ ϱ')
      (incl:getAnn alv ⊆ fst (getAnn ara))
: locally_inj ϱ' s alv.
Proof.
  intros.
  general induction inj; invt renamedApart; invt live_sound; simpl in *.
  - econstructor; eauto.
    + eapply IHinj; eauto.
      rewrite H9 in agr.
      rewrite H8; simpl. eapply agree_on_incl; eauto. cset_tac; intuition.
      rewrite H8; simpl.
      revert H14 incl; clear_all; cset_tac; intuition.
      specialize (H14 a). decide (x === a); cset_tac; intuition.
    + eapply injective_on_agree; eauto.
      eapply agree_on_incl; try eapply agr.
      rewrite H9. rewrite incl. eapply incl_left.
    + eapply injective_on_agree; eauto.
      eapply agree_on_incl; eauto.
      rewrite H9. rewrite <- incl. rewrite <- H14.
      clear_all; cset_tac; intuition.
      decide (x === a); eauto.
  - econstructor; eauto.
    eapply injective_on_agree; eauto.
    eapply agree_on_incl; eauto. rewrite incl. eapply incl_left.
    + eapply IHinj1; eauto.
      rewrite H9; simpl. eapply agree_on_incl; eauto. rewrite <- H5; cset_tac; intuition.
      rewrite H9; simpl. rewrite <- incl; eauto.
    + eapply IHinj2; eauto.
      rewrite H10; simpl. eapply agree_on_incl; eauto. rewrite <- H5; cset_tac; intuition.
      rewrite H10; simpl. rewrite <- incl; eauto.
  - econstructor; eauto.
    eapply injective_on_agree; eauto.
    eapply agree_on_incl; eauto.
    rewrite incl. eapply incl_left.
  - econstructor; eauto.
    eapply injective_on_agree; eauto.
    eapply agree_on_incl; eauto.
    rewrite incl. eapply incl_left.
  - econstructor; eauto.
    + eapply IHinj; eauto. rewrite H9; simpl; eauto.
      eapply agree_on_incl; eauto. rewrite H10.
      clear_all; cset_tac; intuition.
      rewrite H9. simpl. rewrite <- incl, <- H15.
      clear_all; cset_tac; intuition.
      decide (x === a); intuition.
    + eapply injective_on_agree; eauto.
      eapply agree_on_incl; eauto.
      rewrite incl. eapply incl_left.
    + eapply injective_on_agree; eauto.
      eapply agree_on_incl; eauto.
      rewrite H10. rewrite <- incl. rewrite <- H15.
      clear_all; cset_tac; intuition.
      decide (x === a); eauto.
  - econstructor; eauto.
    eapply IHinj1; eauto.
    eapply agree_on_incl; eauto.
    rewrite H8; simpl. rewrite <- H6. clear_all; cset_tac; intuition.
    rewrite H8; simpl. rewrite <- incl. rewrite <- H19.
    clear_all; cset_tac; intuition.
    eapply IHinj2; eauto.
    eapply agree_on_incl; eauto.
    rewrite H11. simpl. rewrite <- H6. cset_tac; intuition.
    rewrite H11; simpl. rewrite <- incl. rewrite <- H20. reflexivity.
    + eapply injective_on_agree; eauto.
      eapply agree_on_incl; eauto.
      rewrite incl. eapply incl_left.
    + eapply injective_on_agree; eauto.
      eapply agree_on_incl; eauto.
      rewrite <- incl. rewrite <- H6, <- H19.
      clear_all; cset_tac; intuition.
      decide (a ∈ of_list Z); eauto.
Qed.

Lemma linear_scan_correct (ϱ:Map [var,var]) LV s alv ϱ' al
      (LS:live_sound FunctionalAndImperative LV s alv)
      (inj:injective_on (getAnn alv) (findt ϱ 0))
      (allocOK:linear_scan s alv ϱ = Success ϱ')
      (incl:getAnn alv ⊆ fst (getAnn al))
      (sd:renamedApart s al)
: locally_inj (findt ϱ' 0) s alv.
Proof.
  intros.
  general induction LS; simpl in *; try monadS_inv allocOK; invt renamedApart;
    eauto 10 using locally_inj, injective_on_incl.
  - exploit IHLS; try eapply allocOK; eauto.
    + eapply injective_on_agree; [| eapply map_update_update_agree].
      eapply injective_on_incl.
      eapply injective_on_fresh; eauto using injective_on_incl, least_fresh_spec.
      eauto.
    + rewrite H8. simpl in *. rewrite <- incl, <- H0.
      clear_all; cset_tac; intuition.
      decide (x === a); eauto.
    + exploit linear_scan_renamedApart_agree; try eapply allocOK; simpl; eauto using live_sound.
      rewrite H8 in *.
      simpl in *.
      econstructor. eauto using injective_on_incl.
      eapply injective_on_agree; try eapply inj.
      eapply agree_on_incl.
      eapply agree_on_update_inv.
      etransitivity. eapply map_update_update_agree.
      eapply X0.
      revert H4 incl; clear_all; cset_tac; intuition. invc H0. eauto.
      exploit locally_injective; eauto.
      eapply injective_on_agree; try eapply X0.
      Focus 2.
      eapply agree_on_incl; eauto. rewrite <- incl, <- H0.
      clear_all; cset_tac; intuition.
      decide (x === a); intuition.
      eapply injective_on_incl.
      eapply injective_on_agree; [| eapply map_update_update_agree].
      eapply injective_on_fresh; eauto.
      Focus 2.
      eapply least_fresh_spec.
      eapply injective_on_incl; eauto.
      cset_tac; intuition.
  - exploit linear_scan_renamedApart_agree; try eapply EQ; simpl; eauto using live_sound.
    exploit linear_scan_renamedApart_agree; try eapply EQ0; simpl; eauto using live_sound.
    rewrite H11 in X. rewrite H12 in X0.
    simpl in *.
    exploit IHLS1; eauto using injective_on_incl.
    rewrite H11; simpl. rewrite <- incl; eauto.
    exploit IHLS2; try eapply EQ0; eauto using injective_on_incl.
    eapply injective_on_incl; eauto.
    eapply injective_on_agree; eauto using agree_on_incl.
    rewrite H12; simpl. rewrite <- incl; eauto.
    econstructor; eauto.
    assert (agree_on eq D (findt ϱ 0) (findt ϱ' 0)). etransitivity; eauto.
    eapply injective_on_agree; eauto. eauto using agree_on_incl.
    eapply locally_inj_live_agree. eauto. eauto. eauto.
    rewrite H11; simpl; eauto.
    exploit linear_scan_renamedApart_agree'; try eapply EQ0; simpl; eauto using live_sound.
    rewrite H12 in X3. simpl in *.
    eapply agree_on_incl. eapply X3. instantiate (1:=D ++ Ds).
    pose proof (renamedApart_disj H9). unfold disj in H2.
    rewrite H12 in H2. simpl in *.
    revert H6 H2; clear_all; cset_tac; intuition; eauto.
    rewrite H11; simpl. rewrite <- incl; eauto.
  - exploit IHLS; try eapply allocOK; eauto.
    + eapply injective_on_incl.
      eapply injective_on_agree; [| eapply map_update_update_agree].
      eapply injective_on_fresh; eauto using injective_on_incl, least_fresh_spec.
      eauto.
    + rewrite H9. simpl in *. rewrite <- incl.
      revert H0; clear_all; cset_tac; intuition.
      decide (x === a); eauto. right; eapply H0; cset_tac; intuition.
    + exploit linear_scan_renamedApart_agree; try eapply allocOK; simpl; eauto using live_sound.
      rewrite H9 in *.
      simpl in *.
      econstructor. eauto using injective_on_incl.
      eapply injective_on_agree; try eapply inj.
      eapply agree_on_incl.
      eapply agree_on_update_inv.
      etransitivity. eapply map_update_update_agree.
      eapply X0.
      revert H5 incl; clear_all; cset_tac; intuition. invc H0. eauto.
      exploit locally_injective; eauto.
      eapply injective_on_agree; try eapply X0.
      Focus 2.
      eapply agree_on_incl; eauto. rewrite <- incl.
      revert H0; clear_all; cset_tac; intuition.
      decide (x === a). intuition.
      right. eapply H0; eauto. cset_tac; intuition.
      eapply injective_on_incl.
      eapply injective_on_agree; [| eapply map_update_update_agree].
      eapply injective_on_fresh; eauto.
      Focus 2.
      eapply least_fresh_spec.
      eapply injective_on_incl; eauto.
      cset_tac; intuition.
  - simpl in *.
    exploit linear_scan_renamedApart_agree; try eapply EQ; simpl; eauto using live_sound.
    exploit linear_scan_renamedApart_agree; try eapply EQ0; simpl; eauto using live_sound.
    rewrite <- map_update_list_update_agree in X.
    exploit IHLS1; eauto.
    + eapply injective_on_agree; [| eapply map_update_list_update_agree].
      eapply injective_on_incl.
      instantiate (1:=getAnn als \ of_list Z ++ of_list Z).
      eapply injective_on_fresh_list; eauto.
      eapply injective_on_incl; eauto.
      rewrite fresh_list_length; eauto.
      eapply fresh_list_spec. eapply least_fresh_spec.
      eapply fresh_list_unique, least_fresh_spec.
      clear_all; cset_tac; intuition.
      decide (a ∈ of_list Z); intuition.
      rewrite fresh_list_length; eauto.
    + rewrite H9. simpl. rewrite <- incl.
      revert H0; clear_all; cset_tac; intuition.
      specialize (H0 a). cset_tac; intuition.
      decide (a ∈ of_list Z); intuition.
    + assert (injective_on lv (findt ϱ' 0)).
      eapply injective_on_incl.
      eapply injective_on_agree; try eapply inj; eauto.
      etransitivity.
      eapply agree_on_incl.
      eapply update_with_list_agree_inv; try eapply X; eauto.
      rewrite fresh_list_length; eauto.
      rewrite H9; simpl. rewrite incl.
      revert H5; clear_all; cset_tac; intuition; eauto.
      eapply agree_on_incl; eauto. rewrite H12; simpl; eauto. reflexivity.
      exploit IHLS2; try eapply EQ0; eauto using injective_on_incl.
      * eapply injective_on_incl.
        eapply injective_on_agree; try eapply inj; eauto.
        eapply agree_on_incl.
        eapply update_with_list_agree_inv; try eapply X; eauto.
        rewrite fresh_list_length; eauto.
        rewrite H9; simpl. rewrite incl.
        revert H5; clear_all; cset_tac; intuition; eauto. eauto.
      * rewrite H12. simpl. simpl in *. rewrite <- incl. eauto.
      * econstructor; eauto.
        eapply locally_inj_live_agree; eauto.
        rewrite H9. simpl.
        eapply agree_on_incl.
        eapply linear_scan_renamedApart_agree'; try eapply EQ0; eauto.
        rewrite H12; simpl. instantiate (1:=(of_list Z ++ D) ++ Ds).
        pose proof (renamedApart_disj sd). unfold disj in H3.
        simpl in *. rewrite <- H7 in H3.
        revert H5 H6 H3; clear_all; cset_tac; intuition eauto; eauto.
        rewrite H9. simpl. rewrite <- incl.
        revert H0; clear_all; cset_tac; intuition.
        specialize (H0 a). cset_tac; intuition.
        decide (a ∈ of_list Z); intuition.
        eapply injective_on_incl. instantiate (1:=(getAnn als \ of_list Z) ∪ of_list Z).
        eapply injective_on_agree with
        (ϱ:=MapUpdate.update_with_list Z
                             (fresh_list least_fresh
                                         (SetConstructs.map (findt ϱ 0) (getAnn als \ of_list Z))
                                         (length Z)) (findt ϱ 0)).
        eapply injective_on_fresh_list; eauto using injective_on_incl.
        rewrite fresh_list_length; eauto.
        eapply fresh_list_spec. eapply least_fresh_spec.
        eapply fresh_list_unique. eapply least_fresh_spec.
        etransitivity. eapply agree_on_incl; eauto.
        rewrite H9; simpl. rewrite H0, incl. cset_tac; intuition.
        eapply agree_on_incl.
        exploit linear_scan_renamedApart_agree'; try eapply EQ0; simpl; eauto using live_sound.
        rewrite H12; simpl. instantiate (1:=D ++ of_list Z).
        pose proof (renamedApart_disj H10). rewrite H12 in H3; simpl in *.
        unfold disj in H3. rewrite H0, incl.
        revert H3 H6; clear_all; cset_tac; intuition; eauto.
        clear_all; cset_tac; intuition. decide (a ∈ of_list Z); eauto.
    + rewrite fresh_list_length; eauto.
Qed.


Definition max_set {X} `{OrderedType X} (a:set X) (b:set X) :=
  if [SetInterface.cardinal a < SetInterface.cardinal b] then
    b
  else
    a.

Fixpoint largest_live_set (a:ann (set var)) : set var :=
  match a with
    | ann0 gamma => gamma
    | ann1 gamma a => max_set gamma (largest_live_set a)
    | ann2 gamma a b => max_set gamma (max_set (largest_live_set a) (largest_live_set b))
  end.

Fixpoint size_of_largest_live_set (a:ann (set var)) : nat :=
  match a with
    | ann0 gamma => SetInterface.cardinal gamma
    | ann1 gamma a => max (SetInterface.cardinal gamma) (size_of_largest_live_set a)
    | ann2 gamma a b => max (SetInterface.cardinal gamma)
                       (max (size_of_largest_live_set a) (size_of_largest_live_set b))
  end.

Lemma size_of_largest_live_set_live_set al
: SetInterface.cardinal (getAnn al) <= size_of_largest_live_set al.
Proof.
  destruct al; simpl; eauto using Max.le_max_l.
Qed.

Lemma cardinal_difference {X} `{OrderedType X} (s t: set X)
: SetInterface.cardinal (s \ t) <= SetInterface.cardinal s.
Proof.
  erewrite <- (diff_inter_cardinal s t).
  omega.
Qed.

Instance plus_le_morpism
: Proper (Peano.le ==> Peano.le ==> Peano.le) Peano.plus.
Proof.
  unfold Proper, respectful.
  intros. omega.
Qed.

Instance plus_S_morpism
: Proper (Peano.le ==> Peano.le) S.
Proof.
  unfold Proper, respectful.
  intros. omega.
Qed.

Instance cardinal_morph {X} `{OrderedType X}
: Proper (@Subset X _ _ ==> Peano.le)  SetInterface.cardinal.
Proof.
  unfold Proper, respectful; intros.
  eapply subset_cardinal; eauto.
Qed.

Lemma cardinal_of_list_unique {X} `{OrderedType X} (Z:list X)
: unique Z -> SetInterface.cardinal (of_list Z) = length Z.
Proof.
  general induction Z; simpl in * |- *.
  - eapply empty_cardinal.
  - dcr. erewrite cardinal_2. rewrite IHZ; eauto.
    intro. eapply H1. eapply InA_in; eauto.
    hnf; cset_tac; intuition.
Qed.

Lemma cardinal_map {X} `{OrderedType X} {Y} `{OrderedType Y} (s: set X) (f:X -> Y) `{Proper _ (_eq ==> _eq) f}
: SetInterface.cardinal (SetConstructs.map f s) <= SetInterface.cardinal s.
Proof.
  pattern s. eapply set_induction.
  - intros. repeat rewrite SetProperties.cardinal_1; eauto.
    hnf. intros; intro. eapply map_iff in H3. dcr.
    eapply H2; eauto. eauto.
  - intros.
    erewrite (SetProperties.cardinal_2 H3 H4); eauto.
    decide (f x ∈ SetConstructs.map f s0).
    + assert (SetConstructs.map f s0 [=] {f x; SetConstructs.map f s0}).
      cset_tac; intuition. rewrite <- H6; eauto.
      rewrite <- H2. rewrite H5.
      assert (SetConstructs.map f s' ⊆ {f x; SetConstructs.map f s0}).
      hnf; intros.
      eapply map_iff in H6.
      cset_tac; intuition; eauto.
      specialize (H4 x0). eapply H4 in H8. destruct H8.
      left. rewrite H6; eauto.
      right. eapply map_iff; eauto. eauto.
      rewrite <- H6. omega.
    + rewrite <- H2. erewrite <- cardinal_2; eauto.
      split; intros.
      decide (f x === y); eauto.
      eapply map_iff in H5; dcr.
      right. eapply map_iff; eauto.
      decide (x0 === x). exfalso. eapply n0. rewrite <- e. eauto.
      eexists x0. split; eauto. specialize (H4 x0).
      rewrite H4 in H7. destruct H7; eauto. exfalso. eapply n1; eauto.
      eauto. eapply map_iff; eauto.
      destruct H5.
      eexists x; split; eauto. eapply H4. eauto.
      eapply map_iff in H5; eauto. dcr.
      eexists x0; split; eauto.
      eapply H4. eauto.
Qed.

Lemma linear_scan_assignment_small (ϱ:Map [var,var]) LV s alv ϱ' al n
      (LS:live_sound Functional LV s alv)
      (allocOK:linear_scan s alv ϱ = Success ϱ')
      (incl:getAnn alv ⊆ fst (getAnn al))
      (sd:renamedApart s al)
      (up:lookup_set (findt ϱ' 0) (fst (getAnn al)) ⊆ vars_up_to n)
: lookup_set (findt ϱ' 0) (snd (getAnn al)) ⊆ vars_up_to (max (size_of_largest_live_set alv + 1) n).
Proof.
  general induction LS; invt renamedApart; simpl in * |- *.
  - assert ( singleton (findt ϱ' 0 x)
                       ⊆ vars_up_to (size_of_largest_live_set al + 1)). {
      eapply linear_scan_renamedApart_agree in allocOK; eauto.
      rewrite <- allocOK. unfold findt at 1.
      rewrite MapFacts.add_eq_o; eauto.
      cset_tac. invc H1. eapply in_vars_up_to'.
      etransitivity; [eapply least_fresh_small|].
      etransitivity; [eapply cardinal_map|]. unfold findt; intuition.
      etransitivity; [eapply cardinal_difference|].
      eapply size_of_largest_live_set_live_set.
      rewrite H8; simpl. cset_tac; intuition.
    }
    exploit IHLS; eauto.
    + rewrite H8. simpl.
      rewrite <- incl. revert H0. clear_all; cset_tac; intuition.
      specialize (H0 a). cset_tac; intuition. decide (x === a); intuition.
    + rewrite H8. simpl in *.
      instantiate (1:=(max (size_of_largest_live_set al + 1) n)).
      rewrite lookup_set_add; eauto.
      rewrite up.
      rewrite vars_up_to_max. cset_tac; intuition.
    + rewrite H8 in X. simpl in *. rewrite H9.
      rewrite lookup_set_add; eauto. rewrite X.
      rewrite <- NPeano.Nat.add_max_distr_r.
      repeat rewrite vars_up_to_max.
      cset_tac; intuition; eauto.
  - monadS_inv allocOK.
    exploit IHLS1; eauto.
    rewrite H11; eauto. simpl. rewrite <- incl; eauto.
    rewrite H11; simpl.
    rewrite lookup_set_agree; eauto.
    eapply agree_on_incl; try eapply linear_scan_renamedApart_agree;
    try eapply EQ0; eauto using live_sound.
    rewrite H12; simpl; eauto. reflexivity.
    exploit IHLS2; try eapply EQ0; eauto.
    rewrite H12; simpl. rewrite <- incl; eauto.
    rewrite H12. simpl. eauto.
    rewrite H11 in X; rewrite H12 in X0. simpl in *.
    rewrite <- H7.
    rewrite lookup_set_union; eauto.
    rewrite X0.
    rewrite lookup_set_agree; eauto. rewrite X.
    repeat (try rewrite <- NPeano.Nat.add_max_distr_r; rewrite vars_up_to_max).
    clear_all; cset_tac; intuition.
    unfold findt; intuition.
    unfold findt; intuition.
    eapply agree_on_incl.
    symmetry.
    eapply linear_scan_renamedApart_agree'; try eapply EQ0; eauto. rewrite H12; simpl.
    instantiate (1:=Ds). revert H6; clear_all; cset_tac; intuition; eauto.
  - rewrite H7. rewrite lookup_set_empty; cset_tac; intuition; eauto.
  - rewrite H2. rewrite lookup_set_empty; cset_tac; intuition; eauto.
  - assert (singleton (findt ϱ' 0 x) ⊆ vars_up_to (size_of_largest_live_set al + 1)). {
      eapply linear_scan_renamedApart_agree in allocOK; eauto.
      rewrite <- allocOK. unfold findt at 1.
      rewrite MapFacts.add_eq_o; eauto.
      cset_tac. invc H1. eapply in_vars_up_to'.
      etransitivity; [eapply least_fresh_small|].
      etransitivity; [eapply cardinal_map|]. unfold findt; intuition.
      etransitivity; [eapply cardinal_difference|].
      eapply size_of_largest_live_set_live_set.
      rewrite H9; simpl. cset_tac; intuition.
    }
    exploit IHLS; eauto.
    + rewrite H9. simpl.
      rewrite <- incl. revert H0. clear_all; cset_tac; intuition.
      specialize (H0 a). cset_tac; intuition. decide (x === a); intuition.
    + rewrite H9. simpl in *.
      instantiate (1:=(max (size_of_largest_live_set al + 1) n)).
      rewrite lookup_set_add; eauto.
      rewrite up.
      rewrite vars_up_to_max. cset_tac; intuition.
    + rewrite H9 in X. simpl in *.
      rewrite H10. rewrite lookup_set_add, X; eauto.
      rewrite <- NPeano.Nat.add_max_distr_r.
      repeat rewrite vars_up_to_max.
      cset_tac; intuition.
  - monadS_inv allocOK.
    simpl in *.
    exploit linear_scan_renamedApart_agree; try eapply EQ; simpl; eauto using live_sound.
    exploit linear_scan_renamedApart_agree; try eapply EQ0; simpl; eauto using live_sound.
    rewrite H9 in *. rewrite H12 in *. simpl in *.
    assert (D [=] (of_list Z ++ D) \ of_list Z). {
      revert H5. clear_all; cset_tac; intuition.
      specialize (H0 a). intuition.
    }
   assert (SetInterface.cardinal
             (SetConstructs.map (findt ϱ 0) (getAnn als \ of_list Z)) +
           length Z <= size_of_largest_live_set als + 1). {
      rewrite cardinal_map.
      rewrite <- size_of_largest_live_set_live_set.
      exploit (diff_inter_cardinal (getAnn als) (of_list Z)).
      assert (getAnn als ∩ of_list Z [=] of_list Z).
      revert H; clear_all; cset_tac; intuition.
      rewrite H3 in X1. simpl in *.
      rewrite <- X1.
      rewrite cardinal_of_list_unique. omega. eauto. eauto.
    }
    rewrite <- map_update_list_update_agree in X.
    assert (agree_on eq D (findt ϱ 0) (findt ϱ' 0)). etransitivity; eauto.
    eapply update_with_list_agree_inv in X; try eapply X; eauto.
    rewrite <- H2 in X; eauto. rewrite fresh_list_length; eauto.
    exploit IHLS1; eauto.
    + rewrite H9. simpl. rewrite <- incl.
      revert H0; clear_all; cset_tac; intuition.
      specialize (H0 a). cset_tac; intuition.
      decide (a ∈ of_list Z); intuition.
    + rewrite H9. simpl.
      instantiate (1:=(max (size_of_largest_live_set als + 1) n)).
      rewrite <- lookup_set_agree; try eapply X; eauto.
      rewrite lookup_set_update_with_list_in_union_length; eauto.
      rewrite <- H2.
      rewrite lookup_set_agree; try eapply H3; eauto.
      rewrite up.
      repeat (try rewrite <- NPeano.Nat.add_max_distr_r; rewrite vars_up_to_max).
      rewrite least_fresh_list_small_vars_up_to.
      intros.
      rewrite (vars_up_to_incl H3).
      cset_tac; intuition.
      rewrite fresh_list_length; eauto.
    + exploit IHLS2; eauto.
      * rewrite H12. simpl. simpl in *. rewrite <- incl. eauto.
      * instantiate (1:=(max (size_of_largest_live_set alb + 1) n)).
        rewrite H9 in X1. simpl in *.
        rewrite H12 in *. simpl in *.
        rewrite up.
        repeat (try rewrite <- NPeano.Nat.add_max_distr_r; rewrite vars_up_to_max).
        eauto.
      * rewrite H9 in X1. rewrite H12 in X2.
        simpl in *.
        rewrite <- H7. repeat rewrite lookup_set_union; eauto.
        rewrite X2. rewrite lookup_set_agree; eauto. rewrite X1.
        repeat (try rewrite <- NPeano.Nat.add_max_distr_r; rewrite vars_up_to_max).
        erewrite lookup_set_agree with (m':=
          MapUpdate.update_with_list Z (fresh_list least_fresh
                                       (SetConstructs.map (findt ϱ 0) (getAnn als \ of_list Z))
                                       (length Z))
                                     (findt ϱ 0)); eauto.
        rewrite update_with_list_lookup_set_incl; eauto.
        rewrite least_fresh_list_small_vars_up_to.
        rewrite (vars_up_to_incl H3).
        cset_tac; intuition.
        rewrite fresh_list_length; eauto.
        reflexivity.
        symmetry.
        etransitivity.
        eapply agree_on_incl.
        rewrite map_update_list_update_agree.
        eapply linear_scan_renamedApart_agree'; try eapply EQ; eauto.
        rewrite fresh_list_length; eauto.
        instantiate (1:=of_list Z). rewrite H9. simpl.
        generalize (renamedApart_disj H8).
        rewrite H9. simpl. unfold disj. clear_all; cset_tac; intuition; eauto.
        eapply agree_on_incl.
        eapply linear_scan_renamedApart_agree'; try eapply EQ0; eauto.
        instantiate (1:=of_list Z). rewrite H12. simpl.
        revert H6. clear_all; cset_tac; intuition; eauto.
        symmetry.
        eapply agree_on_incl.
        eapply linear_scan_renamedApart_agree'; try eapply EQ0; eauto.
        instantiate (1:=Ds). rewrite H12. simpl.
        revert H6; clear_all; cset_tac; intuition; eauto.
    + rewrite fresh_list_length; eauto.
Qed.


(*
*** Local Variables: ***
*** coq-load-path: ((".." "Lvc")) ***
*** End: ***
*)
