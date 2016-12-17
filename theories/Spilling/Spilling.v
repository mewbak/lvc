Require Import Util CSet MapDefined AllInRel.
Require Import Var MapInjectivity IL Annotation AnnP Sim.
Require Import SimplSpill SpillSound SpillSim DoSpill DoSpillRm Take Drop.
Require Import ExpVarsBounded ReconstrLive ReconstrLiveSmall ReconstrLiveSound.
Require Import Liveness RenamedApart RenameApart_Liveness AddParams Slot.

Set Implicit Arguments.

Arguments sim S {H} S' {H0} r t _ _.

Smpl Add
    match goal with
    | [ |- @Equivalence.equiv
            _
            (@_eq _ (@SOT_as_OT _ (@eq nat) nat_OrderedType))
            (@OT_Equivalence _ (@SOT_as_OT _ (@eq nat) nat_OrderedType))
            ?x ?y ] => hnf
    | [ H : @Equivalence.equiv
              _
              (@_eq _ (@SOT_as_OT _ (@eq nat) nat_OrderedType))
              (@OT_Equivalence _ (@SOT_as_OT _ (@eq nat) nat_OrderedType))
              ?x ?y |- _ ] => hnf in H; clear_trivial_eqs
    end : cset.


Definition Slot_p (VD:set var) n (EQ:n = S (fold max VD 0)): Slot VD.
  refine (@Build_Slot VD (fun x => x + n) _ _).
  - hnf; intros. cset_tac'.
    exploit Fresh.fresh_spec'; try eapply H; eauto.
    unfold max in H1. omega.
  - hnf; intros. cset_tac'. omega.
Qed.

Definition spill (k:nat) (slot:var -> var)
           (s:stmt) (lv:ann (set var)) : stmt * ann (set var) :=
  let fvl := to_list (getAnn lv) in
  let (R,M) := (of_list (take k fvl), of_list (drop k fvl)) in
  let spl := @simplSpill k nil nil R M s lv in
  let s_spilled := do_spill slot s spl nil in
  let lv_spilled := reconstr_live nil nil ∅ s_spilled (do_spill_rm slot spl) in
  let s_fun := addParams s_spilled lv_spilled in
  (s_fun, lv_spilled).

Lemma of_list_drop_incl X `{OrderedType X} (n : nat) (L:list X)
  : of_list (drop n L) ⊆ of_list L.
Proof.
  general induction L; destruct n; simpl; eauto with cset.
  rewrite drop_nil; eauto.
Qed.

Lemma of_list_drop_elements_incl X `{OrderedType X} (n : nat) (s : set X)
  : of_list (drop n (elements s)) ⊆ s.
Proof.
  rewrite of_list_drop_incl.
  rewrite of_list_elements; eauto.
Qed.

Lemma agree_on_update_list_slot X `{OrderedType X} Y (L:list X) (L':list Y) (V:X->Y)
      `{Proper _ (_eq ==> eq) V} f `{Proper _ (_eq ==> _eq) f} V' D (Len:❬L❭= ❬L'❭)
  :  agree_on eq (D \ of_list L) V (fun x => V' (f x))
     -> lookup_list V L = L'
     -> injective_on (D ∪ of_list L) f
     -> agree_on eq D V (fun x => V'[f ⊝ L <-- L'] (f x)).
Proof.
  intros. hnf; intros.
  decide (x ∈ of_list L).
  - assert (In:f x ∈ of_list (f ⊝ L)).
    rewrite of_list_map; eauto. cset_tac.
    subst.
    edestruct update_with_list_lookup_in_list; try eapply In; dcr.
    Focus 2. rewrite H8. rewrite lookup_list_map in H7. inv_get.
    eapply H4 in H10; eauto with cset.
    eapply get_in_of_list in H7. cset_tac. eauto with len.
  - rewrite lookup_set_update_not_in_Z; eauto.
    eapply H2; cset_tac. rewrite of_list_map; eauto.
    cset_tac'. eapply H4 in H8; eauto; cset_tac.
Qed.

Lemma spill_correct b k (kGT:k > 0) (s:stmt) lv ra E
      (PM:LabelsDefined.paramsMatch s nil)
      (LV:Liveness.live_sound Liveness.Imperative nil nil s lv)
      (AEF:AppExpFree.app_expfree s)
      (RA:RenamedApart.renamedApart s ra)
      (Def:defined_on (getAnn lv) E)
      (Bnd:exp_vars_bounded k s)
      (Incl:getAnn lv ⊆ fst (getAnn ra))
      (NUC:LabelsDefined.noUnreachableCode (LabelsDefined.isCalled b) s)
      (slt:Slot (fst (getAnn ra) ∪ snd (getAnn ra)))
      (aIncl:ann_R (fun (x : ⦃var⦄) (y : ⦃var⦄ * ⦃var⦄) => x ⊆ fst y) lv ra)
  : sim I.state F.state bot3 Sim
        (nil, E, s)
        (nil, E [slt ⊝ drop k (to_list (getAnn lv)) <-- lookup_list E (drop k (to_list (getAnn lv)))], fst (spill k slt s lv )).
Proof.
  unfold spill.
  set (R:=of_list (take k (to_list (getAnn lv)))).
  set (M:=of_list (drop k (to_list (getAnn lv)))).
  set (spl:=(simplSpill k nil nil R M s lv)).
  set (VD:=fst (getAnn ra) ∪ snd (getAnn ra)).
  assert (lvRM:getAnn lv [=] R ∪ M). {
    subst R M. rewrite <- of_list_app. rewrite <- take_eta.
    rewrite of_list_3. eauto.
  }
  assert (SPS:spill_sound k nil nil (R, M) s spl). {
    eapply simplSpill_sat_spillSound; eauto using PIR2.
    subst R. rewrite TakeSet.take_of_list_cardinal; eauto.
    rewrite lvRM; eauto.
  }
  assert (Disj: disj R M). {
    subst R M. clear. hnf; intros.
    eapply of_list_get_first in H; dcr. cset_tac'.
    eapply of_list_get_first in H0; dcr; cset_tac'.
    inv_get.
    refine (NoDupA_get_neq' _ _ H0 H _); eauto.
    eapply (elements_3w (getAnn lv)).
    omega.
  }
  assert (InclR: R ⊆ VD). {
    subst R VD. unfold to_list.
    rewrite TakeSet.take_set_incl. eauto with cset.
  }
  assert (InclM: M ⊆ VD). {
    subst M VD. unfold to_list.
    rewrite of_list_drop_elements_incl. eauto with cset.
  }
  assert (DefRM:defined_on (R ∪ map slt M)
                           (E [slt ⊝ drop k (elements (getAnn lv)) <--
                                   lookup_list E (drop k (elements (getAnn lv)))])).   {
    subst R M.
    eapply defined_on_union.
    - eapply defined_on_update_list_disj; eauto with len.
      eapply defined_on_incl; eauto.
      eapply TakeSet.take_set_incl.
      unfold to_list. rewrite TakeSet.take_set_incl.
      rewrite of_list_map; eauto. symmetry.
      eapply disj_incl; [ eapply (@Slot_Disj _ slt); eauto | |]; eauto with cset.
    - eapply defined_on_update_list'; eauto with len.
      rewrite of_list_map; eauto. clear; hnf; intros. exfalso; cset_tac.
      rewrite lookup_list_map; eauto.
      rewrite <- defined_on_defined.
      eapply defined_on_incl; eauto.
      rewrite of_list_drop_elements_incl; eauto.
      clear; intuition.
  }
  assert (spl_lv:spill_live VD spl lv). {
    eapply simplSpill_spill_live; eauto using lv_ra_lv_bnd.
  }
  eapply sim_trans with (S2:=I.state).
  - eapply sim_I with (slot:=slt) (k:=k) (R:=R) (M:=M) (sl:=spl) (Λ:=nil)
      (VD:=VD)
      (V':=E [slt ⊝ drop k (elements (getAnn lv)) <-- lookup_list E (drop k (elements (getAnn lv)))]);
      eauto.
    + eapply agree_on_update_list_dead; eauto.
      rewrite of_list_map. symmetry.
      eapply disj_incl; [ eapply (@Slot_Disj _ slt); eauto | subst R |].
      * unfold to_list.
        rewrite TakeSet.take_set_incl. eauto with cset.
      * rewrite of_list_drop_elements_incl, Incl.
        eauto with cset.
      * eauto.
    + subst M.
      eapply agree_on_update_list_slot; try eassumption.
      clear; intuition. clear; intuition.
      eauto with len.
      eapply agree_on_empty; clear; cset_tac.
      reflexivity.
      eapply injective_on_incl; eauto.
      unfold to_list.
      rewrite of_list_drop_elements_incl. cset_tac.
    + rewrite <- Incl, lvRM; eauto.
    + eapply SimI.labenv_sim_nil.
    + eauto.
  - eapply addParams_correct; eauto.
    + rewrite (@ReconstrLiveSmall.reconstr_live_small Imperative nil nil nil s _ R M VD); eauto.
      * rewrite union_comm, empty_neutral_union. eauto.
      * reflexivity.
      * isabsurd.
    + eapply (@reconstr_live_sound k VD slt nil _ nil R M); eauto using PIR2.
      ** reflexivity.
      ** isabsurd.
    + eapply (@do_spill_no_unreachable_code _ _ _ _ nil nil); eauto.
Qed.

Lemma spill_live b k (kGT:k > 0) (s:stmt) lv ra
      (PM:LabelsDefined.paramsMatch s nil)
      (LV:Liveness.live_sound Liveness.Imperative nil nil s lv)
      (AEF:AppExpFree.app_expfree s)
      (RA:RenamedApart.renamedApart s ra)
      (Bnd:exp_vars_bounded k s)
      (Incl:getAnn lv ⊆ fst (getAnn ra))
      (NUC:LabelsDefined.noUnreachableCode (LabelsDefined.isCalled b) s)
      (slt:Slot (fst (getAnn ra) ∪ snd (getAnn ra)))
      (aIncl:ann_R (fun (x : ⦃var⦄) (y : ⦃var⦄ * ⦃var⦄) => x ⊆ fst y) lv ra)
  : live_sound FunctionalAndImperative
               nil
               nil
               (fst (spill k slt s lv)) (snd (spill k slt s lv)).
Proof.
    unfold spill.
  set (R:=of_list (take k (to_list (getAnn lv)))).
  set (M:=of_list (drop k (to_list (getAnn lv)))).
  set (spl:=(simplSpill k nil nil R M s lv)).
  set (VD:=fst (getAnn ra) ∪ snd (getAnn ra)).
  assert (lvRM:getAnn lv [=] R ∪ M). {
    subst R M. rewrite <- of_list_app. rewrite <- take_eta.
    rewrite of_list_3. eauto.
  }
  assert (SPS:spill_sound k nil nil (R, M) s spl). {
    eapply simplSpill_sat_spillSound; eauto using PIR2.
    subst R. rewrite TakeSet.take_of_list_cardinal; eauto.
    rewrite lvRM; eauto.
  }
  assert (Disj: disj R M). {
    subst R M. clear. hnf; intros.
    eapply of_list_get_first in H; dcr. cset_tac'.
    eapply of_list_get_first in H0; dcr; cset_tac'.
    inv_get.
    refine (NoDupA_get_neq' _ _ H0 H _); eauto.
    eapply (elements_3w (getAnn lv)).
    omega.
  }
  assert (InclR: R ⊆ VD). {
    subst R VD. unfold to_list.
    rewrite TakeSet.take_set_incl. eauto with cset.
  }
  assert (InclM: M ⊆ VD). {
    subst M VD. unfold to_list.
    rewrite of_list_drop_elements_incl. eauto with cset.
  }
  assert (spl_lv:spill_live VD spl lv). {
    eapply simplSpill_spill_live; eauto using lv_ra_lv_bnd.
  }
  eapply addParams_live.
  - eapply (@reconstr_live_sound k VD slt nil _ nil R M); eauto using PIR2.
    ** reflexivity.
    ** isabsurd.
  - eapply (@do_spill_no_unreachable_code _ _ _ _ nil nil); eauto.
Qed.
