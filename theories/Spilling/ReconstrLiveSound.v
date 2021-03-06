Require Import List Map Envs AllInRel Exp AppExpFree RenamedApart.
Require Import IL Annotation AnnotationLattice.
Require Import AutoIndTac Liveness.Liveness LabelsDefined.
Require Import DoSpill DoSpillRm.
Require Import SpillSound SpillUtil ReconstrLive ReconstrLiveSmall.
Require Import InVD Slot.
Require Import SlotLiftArgs SlotLiftParams.
Require Import PartialOrder AnnotationLattice.

Set Implicit Arguments.

(** * ReconstrLiveSound *)

Lemma sla_extargs_slp_length
      (slot : var -> var)
      RM RMapp
      (ZL : list params)
      (Z : params)
      (l : lab)
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (Y : args)
  : length Y = length Z ->
    ❬slot_lift_args slot RM RMapp Y Z❭ = ❬slot_lift_params slot RM Z❭.
Proof.
  intros Len.
  general induction Len; simpl; eauto.
  repeat cases; simpl; eauto.
Qed.

Lemma reconstr_live_sound_s
      (slot : var -> var) o
      (ZL' ZL : list params)
      (G : ⦃var⦄)
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (Lv : list ⦃var⦄)
      (s : stmt)
      (sl : spilling)
  :
    (forall G',
        live_sound o ZL' Lv
                   (do_spill slot s (clear_SpL sl) ZL Λ)
                   (reconstr_live (slot_merge slot ⊝ Λ) ZL' G'
                                  (do_spill slot s (clear_SpL sl) ZL Λ)
                                  (do_spill_rm slot (clear_SpL sl))))
   -> live_sound o ZL' Lv
                (do_spill slot s sl ZL Λ)
                (reconstr_live (slot_merge slot ⊝ Λ) ZL' G
                               (do_spill slot s sl ZL Λ)
                               (do_spill_rm slot sl)).
Proof.
  intros sls.

  rewrite do_spill_extract_writes.
  rewrite do_spill_rm_s.


  unfold count.

  (* prepare induction *)
  remember (elements (getSp sl)) as elSp.
  symmetry in HeqelSp.
  remember (elements (getL  sl)) as elL.
  symmetry in HeqelL.
  do 2 rewrite <- elements_length.
  rewrite HeqelL.
  rewrite HeqelSp.
  clear HeqelSp.
  revert G.
  induction elSp;
    intros G;
    simpl.
  - (*apply elements_nil_eset in HeqelSp as empty_Sp.*)
    revert G.
    clear HeqelL.
    induction elL;
      intros G;
      simpl in *.
    + apply sls.

    + rewrite add_anns_S.

      constructor; eauto; fold reconstr_live.
      * simpl.
        apply live_exp_sound_incl with (lv':=singleton (slot a)).
        -- econstructor.
           econstructor.
           cset_tac.
        -- clear.
           cset_tac.
      * clear.
        cset_tac.
      * apply reconstr_live_G.
        cset_tac.
  - rewrite add_anns_S.
    econstructor; simpl; eauto.
    * simpl.
      apply live_exp_sound_incl with (lv':=singleton a).
      -- econstructor.
         econstructor.
         cset_tac.
      -- clear.
         cset_tac.
    * clear.
      cset_tac.
    * apply reconstr_live_G.
      cset_tac.
Qed.

Lemma reconstr_live_sound
      (k : nat) VD
      (slot : Slot VD)
      (ZL : list params)
      (G : ⦃var⦄)
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (R M : ⦃var⦄)
      (s : stmt)
      (Lv : list ⦃var⦄)
      (sl : spilling)
      (alv : ann ⦃var⦄)
      (ra : ann (⦃var⦄ * ⦃var⦄))
  : R ⊆ VD
    -> M ⊆ VD
    -> fst (getAnn ra) ∪ snd (getAnn ra) ⊆ VD
    -> app_expfree s
    -> renamedApart s ra
    -> spill_sound k ZL Λ (R,M) s sl
    -> spill_live VD sl alv
    -> PIR2 Equal (merge ⊝ Λ) Lv
    -> (forall (Z : params) n,
          get ZL n Z
          -> of_list Z ⊆ VD)
    -> live_sound Imperative ZL Lv s alv
    -> live_sound Imperative
                 ((slot_lift_params slot) ⊜ Λ ZL)
                 (slot_merge slot ⊝ Λ)
                 (do_spill slot s sl ZL Λ)
                 (reconstr_live (slot_merge slot ⊝ Λ)
                                ((slot_lift_params slot) ⊜ Λ ZL)
                                 G
                                 (do_spill slot s sl ZL Λ)
                                (do_spill_rm slot sl))
.
Proof.
  intros disj_VD R_VD M_VD aeFree renAp spillSnd spilli pir2_EQ Z_VD lvSnd.

  general induction lvSnd;
    invc aeFree;
    invc spillSnd;
    invc spilli;
    inv renAp;
    apply reconstr_live_sound_s;
    intros G'.

  - rename sl0 into sl.
    assert (x ∈ VD) as x_VD by (eapply x_VD; eauto).
    rewrite do_spill_empty by apply count_clear_zero.
    unfold do_spill_rec.
    rewrite do_spill_rm_empty by apply count_clear_zero.
    simpl.

    econstructor; eauto.
    + eapply IHlvSnd with (ra:=an) (R:={x; (R\K ∪ L) \Kx}) (M:=Sp ∪ M); eauto.
      * eapply Rx_VD with (R:=R) (M:=M); eauto.
      * eapply M'_VD with (R:=R) (M:=M); eauto.
      * eapply renamedApart_incl in renAp as rena.
        rewrite rena. eauto.
    + apply live_exp_sound_incl with (lv':=Exp.freeVars e).
      * apply live_freeVars.
      * clear; cset_tac.
    + clear; cset_tac.
    + apply reconstr_live_G.
      eauto with cset.

  - rewrite do_spill_empty by apply count_clear_zero.
    unfold do_spill_rec.
    rewrite do_spill_rm_empty by apply count_clear_zero.
    simpl.

    apply renamedApart_incl in renAp as [rena1 rena2].
    assert (R \ K ∪ L ⊆ VD) as R'_VD
        by (eapply R'_VD with (R:=R) (M:=M); eauto).
    assert (Sp ∪ M ⊆ VD) as M'_VD
        by (eapply M'_VD with (R:=R) (M:=M); eauto).
    econstructor.
    + eapply IHlvSnd1 with (ra:=ans) (R:=R\K ∪ L); eauto.
      rewrite rena1. eauto.
    + eapply IHlvSnd2 with (ra:=ant) (R:=R\K ∪ L); eauto.
      rewrite rena2; eauto.
    + apply live_op_sound_incl with (lv':=Ops.freeVars e).
      * apply Ops.live_freeVars.
      * clear; cset_tac.
    + clear; cset_tac.
    + clear; cset_tac.

  - rewrite do_spill_empty by apply count_clear_zero.
    unfold do_spill_rec.
    rewrite do_spill_rm_empty by apply count_clear_zero.
    simpl.
    eapply get_get_eq in H; eauto.
    subst Z0.

    econstructor.
    + eapply zip_get; eauto.
    + simpl.
      unfold slot_merge.
      eapply map_get_eq; eauto.
    + simpl.
      assert (nth (labN l) (slot_merge slot ⊝ Λ) ∅ [=] R_f ∪ map slot M_f)
        as nth_EQ.
      {
        unfold slot_merge.
        assert ((fun RM => fst RM ∪ map slot (snd RM)) (R_f,M_f) = R_f ∪ map slot M_f)
          by (simpl; reflexivity).
        eapply map_get_eq in H13; eauto.
        erewrite get_nth; eauto.
        reflexivity.
      }
      rewrite nth_EQ.
      assert (of_list (nth (labN l) (slot_lift_params slot ⊜ Λ ZL) nil)
              [=] of_list (slot_lift_params slot (R_f,M_f) Z))
        as nth_slp by (erewrite nth_zip; eauto; simpl; reflexivity).
      rewrite nth_slp.
      clear; cset_tac.
    + erewrite !get_nth; try eassumption.
      apply sla_extargs_slp_length; eauto.
    + intros; inv_get.
      erewrite !nth_zip; eauto.
      erewrite !get_nth in H; eauto.
      erewrite !get_nth; eauto using map_get_1. simpl.
      eapply live_op_sound_incl. eapply Ops.live_freeVars.
      eapply get_list_union_map with (f:=Ops.freeVars) in H.
      rewrite <- H. cset_tac.
  - rewrite do_spill_empty by apply count_clear_zero.
    unfold do_spill_rec.
    rewrite do_spill_rm_empty by apply count_clear_zero.
    simpl.

    econstructor; simpl; eauto.
    + apply live_op_sound_incl with (lv':=Ops.freeVars e).
      * apply Ops.live_freeVars.
      * clear; cset_tac.

  - rewrite do_spill_empty by apply count_clear_zero.
    unfold do_spill_rec.
    rewrite do_spill_rm_empty by apply count_clear_zero.
    simpl.

    apply renamedApart_incl in renAp as [renaF rena2].
    rewrite fst_zip_pair by eauto with len.
    econstructor; simpl; eauto.
    + rewrite fst_zip_pair by eauto with len.
      rewrite slot_lift_params_app; eauto with len.
      rewrite getAnn_map_setTopAnn.
      rewrite Take.take_eq_ge;
        [|len_simpl; rewrite <- H13, <- H16; omega].
      rewrite slot_merge_app.
      apply live_sound_monotone with (LV:= slot_merge slot ⊝ (rms ++ Λ)).
      * eapply IHlvSnd with (ra:=ant) (R:=R\K ∪ L) (M:=Sp ∪ M); eauto.
        -- eapply R'_VD with (R:=R) (M:=M); eauto.
        -- eapply M'_VD with (R:=R) (M:=M); eauto.
        -- rewrite rena2; eauto.
        -- eapply getAnn_als_EQ_merge_rms; eauto.
        -- eapply get_ofl_VD; eauto.
      * rewrite <- slot_merge_app.
        apply PIR2_app with (L2:=slot_merge slot ⊝ Λ);
          swap 1 2.
        {
          apply PIR2_refl; eauto.
        }
        apply PIR2_get.
        -- intros n x x' H4 H5.
           inv_get; simpl.
           rename x into Zs.
           rename x0 into rm.
           rename x5 into sl_s.
           rename x1 into a.
           rename x2 into al.
           rename H33 into get_al.
           rename H32 into get_a.
           rename H26 into get_sls.
           rename H30 into get_Zs.
           rename H5 into get_rm.

           rewrite slot_merge_app.

           exploit H19 as H24'; eauto. (*H31*)
           exploit H23 as H20'; eauto. (*H32*)
           exploit renaF as renaF'; eauto.
           exploit H14 as H15'; eauto. (*H33*)
           exploit H2 as H2'; eauto.
           destruct H2' as [H2' _].
           destruct H15' as [A [B [C E]]].
           assert (rm = (fst rm, snd rm)) as rm_eta by apply pair_eta.
           rewrite rm_eta in H24'.
           rewrite <- reconstr_live_setTopAnn.
           erewrite reconstr_live_small with (VD:=VD)
                                             (ra:=a)
                                             (R:=fst rm)
                                             (M:=snd rm); eauto.
           ++ (*clear - pir2_EQ pir3 renaF H24 H20 H15 H2 H16 H20 H8 H13 H14 H H9 H18 ra_VD.*)
             clear - rm_eta H2' get_al get_a get_sls get_rm get_Zs H15.
             rewrite rm_eta in get_rm.
             eapply al_sub_RfMf in get_rm; eauto.
             rewrite rm_eta. unfold slot_merge; simpl.
              repeat apply union_incl_split;
                [clear; cset_tac | clear; cset_tac
                 | eapply ofl_slp_sub_rm; eauto ].
           ++ rewrite renaF'; eauto.
           ++ eapply getAnn_als_EQ_merge_rms; eauto.
           ++ eapply get_ofl_VD; eauto.

        -- eauto with len.
    + symmetry.
      apply zip_length2.
      repeat rewrite length_map.
      rewrite zip_length2;
        eauto with len.
    + intros; inv_get.
      simpl.
      rewrite fst_zip_pair by eauto with len.
      rewrite getAnn_map_setTopAnn.
      rewrite Take.take_eq_ge;
        [|unfold slot_merge; len_simpl; rewrite <- H13, <- H16; omega].
      rewrite slot_merge_app.
      rewrite slot_lift_params_app; eauto with len.
      rewrite <- reconstr_live_setTopAnn.
      apply live_sound_monotone with (LV:= slot_merge slot ⊝ (rms ++ Λ)).
      * assert ((fst x3, snd x3) = x3)
          by (destruct x3; simpl; reflexivity).
        rewrite <- H4 in H31.
        exploit H23; eauto.
        eapply H1 with (ra:=x0) (R:=fst x3) (M:=snd x3); eauto.
        -- exploit renaF as renaF'; eauto.
           rewrite renaF'; eauto.
        -- eapply getAnn_als_EQ_merge_rms; eauto.
        -- eapply get_ofl_VD; eauto.
      * rewrite <- slot_merge_app.
        apply PIR2_app with (L2:=slot_merge slot ⊝ Λ);
          swap 1 2.
        {
          apply PIR2_refl; eauto.
        }
        apply PIR2_get.
        -- intros.
           unfold slot_merge in H5.
           inv_get; simpl.
           rewrite slot_merge_app.
           exploit H19; eauto.
           exploit H23; eauto.
           exploit H9; eauto.
           destruct x5 as [R_f M_f].
           rewrite <- reconstr_live_setTopAnn.
           erewrite reconstr_live_small with (ra:=x6)
                                             (VD:=VD)
                                             (R:=R_f)
                                             (M:=M_f); eauto.
           ++ exploit H2 as H2'; eauto; dcr; simpl in *.

             rewrite ofl_slp_sub_rm; eauto.
             poLe_set. clear; cset_tac.
             eapply al_sub_RfMf; eauto.
           ++ rewrite renaF; eauto.
           ++ eapply getAnn_als_EQ_merge_rms; eauto.
           ++ eapply get_ofl_VD; eauto.
        -- unfold slot_merge. eauto with len.
    + intros.
      inv_get.
      simpl.
      split; [ | auto].
      * apply reconstr_live_G.
      * split; eauto.
        -- exploit H2; eauto; dcr.
           eapply PIR2_nth in H15; eauto; dcr.
           destruct x3. eapply NoDupA_slot_lift_params; eauto.
           unfold merge in H33.
           exploit H23; eauto; dcr. eauto with cset.
           rewrite <- M_VD. simpl.
           rewrite <- H27.
           rewrite <- incl_list_union; eauto using zip_get; [|reflexivity].
           unfold defVars. clear; cset_tac.
Qed.
