Require Import List Map Env AllInRel Exp MoreList.
Require Import IL Annotation.
Require Import Liveness.Liveness RenamedApart.
Require Import ExpVarsBounded SpillSound OneOrEmpty RegLive.
Require Import Take TakeSet SetUtil.



Set Implicit Arguments.


(* ATTENTION: you are killing L in spill_max_kill but you are not killing it in repair_spill !!! *)


Inductive spill_max_kill (k:nat) :
  (list params)
  -> (list (⦃var⦄ * ⦃var⦄))
  -> (⦃var⦄ * ⦃var⦄)
  -> stmt
  -> ann ⦃var⦄
  -> spilling
  -> Prop
  :=

  | SpillLet
      (ZL : list params)
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (R M Sp L Rlv : ⦃var⦄)
      (x : var)
      (e : exp)
      (s : stmt)
      (sl : spilling)
      (rlv : ann ⦃var⦄)
    : let K := (R \ (Exp.freeVars e ∪ getAnn rlv)) ∪ (R ∩ L) in
      let Kx:= ((R \ K ∪ L) \ getAnn rlv) in 
      Sp ⊆ R
      -> L ⊆ Sp ∪ M
      -> spill_max_kill k ZL Λ ({x; (R\K ∪ L) \ Kx}, Sp ∪ M) s rlv sl
      -> Exp.freeVars e ⊆ R\K ∪ L
      -> k > 0
      -> cardinal (R\K ∪ L) <= k
      -> cardinal {x; (R\K ∪ L) \ Kx} <= k
      -> spill_max_kill k ZL Λ (R,M) (stmtLet x e s) (ann1 Rlv rlv) (ann1 (Sp,L,nil) sl)
                       
  | SpillReturn
      (ZL : list (params))
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (R M Sp L Rlv: ⦃var⦄)
      (e : op)
    : let K := (R \ (Op.freeVars e)) ∪ (R ∩ L) in
      Sp ⊆ R
      -> L ⊆ Sp ∪ M
      -> Op.freeVars e ⊆ R\K ∪ L
      -> cardinal (R\K ∪ L) <= k
      -> spill_max_kill k ZL Λ (R,M) (stmtReturn e) (ann0 Rlv) (ann0 (Sp,L,nil))

  | SpillIf
      (ZL : list (params))
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (R M Sp L Rlv: ⦃var⦄)
      (e : op)
      (s t : stmt)
      (sl_s sl_t : spilling)
      (rlv1 rlv2 : ann ⦃var⦄)
    : let K := (R \ (Op.freeVars e ∪ getAnn rlv1 ∪ getAnn rlv2)) ∪ (R ∩ L) in
      Sp ⊆ R
      -> L ⊆ Sp ∪ M
      -> Op.freeVars e ⊆ R\K ∪ L
      -> cardinal (R\K ∪ L) <= k
      -> spill_max_kill k ZL Λ (R \ K ∪ L, Sp ∪ M) s rlv1 sl_s
      -> spill_max_kill k ZL Λ (R \ K ∪ L, Sp ∪ M) t rlv2 sl_t
      -> spill_max_kill k ZL Λ (R,M) (stmtIf e s t) (ann2 Rlv rlv1 rlv2) (ann2 (Sp,L,nil) sl_s sl_t)

  | SpillApp
      (ZL : list params)
      (Λ : list (⦃var⦄ * ⦃var⦄))
      (R M Sp L R_f M_f R' M' Rlv : ⦃var⦄)
      (f : lab)
      (Z : params)
      (Y : args)
    : let K := R \ (list_union (Op.freeVars ⊝ Y) \ M' ∪  (R_f \ of_list Z)) ∪ (R ∩ L) in
      Sp ⊆ R
      -> L ⊆ Sp ∪ M
      -> cardinal (R\K ∪ L) <= k
      -> get ZL (counted f) Z
      -> get Λ (counted f) (R_f,M_f)
      -> R_f \ of_list Z ⊆ R\K ∪ L
      -> M_f \ of_list Z ⊆ Sp ∪ M
      -> list_union (Op.freeVars ⊝ Y) ⊆ (R\K ∪ L) ∪ M'
      -> M' ⊆ Sp ∪ M
      -> spill_max_kill k ZL Λ (R,M) (stmtApp f Y) (ann0 Rlv) (ann0 (Sp,L, (R', M')::nil))

  | SpillFun
      (ZL : list params)
      (Λ rms : list (⦃var⦄ * ⦃var⦄))
      (R M Sp L Rlv : ⦃var⦄)
      (F : list (params * stmt))
      (t : stmt)
      (sl_F : list spilling)
      (sl_t : spilling)
      (rlv_t : ann ⦃var⦄)
      (rlv_F : list (ann ⦃var⦄))
    : let K := (R \ getAnn rlv_t) ∪ (R ∩ L) in
      Sp ⊆ R
      -> L ⊆ Sp ∪ M
      -> cardinal (R\K ∪ L) <= k
      -> length F = length sl_F
      -> length F = length rms
      -> (forall n rm, get rms n rm -> cardinal (fst rm) <= k)
      -> (forall n Zs rm rlv_s sl_s, get rms n rm
                         -> get F n Zs
                         -> get rlv_F n rlv_s
                         -> get sl_F n sl_s
                         -> spill_max_kill k ((fst ⊝ F) ++ ZL)
                                          (rms ++ Λ) rm (snd Zs) rlv_s sl_s
        )
      -> spill_max_kill k ((fst ⊝ F) ++ ZL) (rms ++ Λ) (R\K ∪ L, Sp ∪ M) t rlv_t sl_t
      -> spill_max_kill k ZL Λ (R,M) (stmtFun F t) (annF Rlv rlv_F rlv_t) (annF (Sp,L,rms) sl_F sl_t)
.

Lemma Sp_sub_rlv k ZL Λ R M s sl rlv :
  spill_sound k ZL Λ (R,M) s sl
  -> rlive_sound ZL (fst ⊝ Λ) s sl rlv
  -> getSp sl ⊆ getAnn rlv
.
Proof.
  intros spillSnd rlive. general induction spillSnd; invc rlive; simpl; eauto.
Qed.

Lemma card_diff (X:Type) `{OrderedType X} (s t : ⦃X⦄) :
  cardinal (s \ t) = cardinal s - cardinal (s ∩ t)
.
Proof.
  setoid_rewrite <-diff_inter_cardinal with (s':=t) at 2. omega.
Qed.

Lemma card_RKL (X:Type) `{OrderedType X} k (s t u : ⦃X⦄) :
  t ⊆ s
  -> cardinal u <= k
  -> cardinal t = cardinal s + cardinal u - k
  -> cardinal (s \ t ∪ u) <= k
.
Proof.
  intros sub ucard card.
  rewrite union_cardinal_inter. rewrite card_diff. rewrite meet_comm, inter_subset_equal; eauto.
  rewrite card. omega.
Qed.


Lemma rkl'_incl_rkl (X:Type) `{OrderedType X} (s s' t t1 t2 u v w : ⦃X⦄) (x : X) :
  let t' := s' \ (t1 ∪ t2) ∪ (s' ∩ v) in
  t1 ⊆ s \ t ∪ v
  -> t2 ⊆ {x; (s \ t ∪ v) \ w}
  -> s' ⊆ u
  -> x ∉ u
  -> s' \ t' ∪ v ⊆ s \ t ∪ v
.
Proof.
  intros t' t1_incl t2_incl s'_incl x_nin.
  subst t'.
  cset_tac.
Qed.



Lemma spill_sound_spill_max_kill k ZL Λ R R' M G s sl rlv ra :
  renamedApart s ra
  -> spill_sound k ZL Λ (R,M) s sl
  -> rlive_min k ZL Λ G s sl rlv
  -> rlive_sound ZL (fst ⊝ Λ) s sl rlv
  -> R' ∪ M ⊆ fst (getAnn ra)
  -> getAnn rlv ⊆ R'
  -> (forall Rf Mf n, get Λ n (Rf,Mf) -> cardinal Rf <= k)
  -> spill_max_kill k ZL Λ (R',M) s rlv sl
.
Proof.
  intros rena spillSnd rliveMin rlive R_sub rlv_sub' card_Rf.
  general induction spillSnd; invc rlive; invc rena; invc rliveMin; cbn in rlv_sub'.
  - set (K' := R' \ (Exp.freeVars e ∪ getAnn al) ∪ (R' ∩ L)).
    assert (R' \ K' ∪ L ⊆ R0 \ K ∪ L) as rkl'_in_rkl2.
    {
      eapply rkl'_incl_rkl; eauto.
      - eapply rlive_min_incl_R; eauto. clear; cset_tac.
      - cbn in R_sub. clear - R_sub; cset_tac.
    }
    subst K'.
    econstructor; eauto;
      set (K' := R' \ (Exp.freeVars e ∪ getAnn al) ∪ (R' ∩ L)) in *;
      set (Kx':= (R' \ K' ∪ L) \ getAnn al) in *.
    + rewrite H13. eauto.
    + eapply IHspillSnd; eauto.
      * rewrite H14.
        cbn in R_sub. apply union_incl_split.
        -- apply add_struct_incl. rewrite !minus_incl. rewrite H0, H13, rlv_sub'.
           clear - R_sub. cset_tac.
        -- rewrite H13, rlv_sub', R_sub. cbn. clear; cset_tac.
      * enough (getAnn al \ singleton x ⊆ (R' \ K' ∪ L) \ Kx') as Hypo.
        { rewrite <-Hypo. clear; cset_tac. }
        rewrite <-inter_subset_equal with (s':=getAnn al);[| clear; cset_tac]. rewrite H17.
        subst K'. rewrite <-minus_union, minus_minus.
        setoid_rewrite <-rlv_sub' at 1. apply not_incl_minus; [clear; cset_tac|].
        subst Kx'. clear; cset_tac.
    + subst K'. rewrite <-minus_union. rewrite incl_minus_union;[|clear;cset_tac].
      rewrite minus_minus, <-rlv_sub'.
      apply Exp.freeVars_live in H16. clear - H16; cset_tac.
    + rewrite subset_cardinal with (s':=R0 \ K ∪ L); eauto.
    + rewrite subset_cardinal with (s':={x; (R0 \ K ∪ L) \ Kx}); eauto.
      subst Kx'. rewrite minus_minus. apply incl_add_eq; split; [clear;cset_tac|].
      rewrite rkl'_in_rkl2. eapply rlive_min_incl_R in H20.
      * rewrite H20. clear; cset_tac.
      * clear; cset_tac.
      * eauto. 
  - econstructor; eauto.
    + rewrite H8; eauto.
    + rewrite <-minus_union.
      rewrite incl_minus_union;[|clear;cset_tac].
      rewrite minus_minus, <-rlv_sub'.
      apply Op.freeVars_live in H10. clear - H10. cset_tac.
    + rewrite <-minus_union. rewrite incl_minus_union;[|clear;cset_tac].
      rewrite minus_minus. rewrite H1. rewrite subset_cardinal with (s':=R0 \ K ∪ L); eauto.
      clear; cset_tac.
  - eapply rlive_min_incl_R with (G:=∅) in spillSnd1 as spillSnd1'; [|clear;cset_tac|eauto].
    eapply rlive_min_incl_R with (G:=∅) in spillSnd2 as spillSnd2'; [|clear;cset_tac|eauto].
    econstructor; eauto.
    + rewrite H12; eauto.
    + rewrite <-minus_union. rewrite incl_minus_union;[|clear;cset_tac].
      rewrite minus_minus, <-rlv_sub'.
      apply Op.freeVars_live in H16. clear - H16; cset_tac.
    + rewrite <-minus_union. rewrite incl_minus_union;[|clear;cset_tac].
      rewrite minus_minus. rewrite H1.
      rewrite spillSnd1'. cbn.
      rewrite spillSnd2'. cbn.
      rewrite subset_cardinal with (s':=R0 \ K ∪ L); eauto. 
      cbn in R_sub; clear - R_sub H9; cset_tac.
    + eapply IHspillSnd1; eauto.
      * cbn in R_sub.
        rewrite <-minus_union, minus_minus, H6, H17, H18, rlv_sub', H12.
        setoid_rewrite H0 at 4. rewrite H12, rlv_sub'.
        rewrite H13. clear - R_sub. cbn. cset_tac.
      * rewrite <-inter_subset_equal with (s':=getAnn al1); [|clear;cset_tac]. setoid_rewrite H17 at 1.
        rewrite <-minus_union, minus_minus. setoid_rewrite rlv_sub' at 1. clear; cset_tac.
    + eapply IHspillSnd2; eauto.      
      * cbn in R_sub.
        rewrite <-minus_union, minus_minus, H6, H17, H18, rlv_sub', H12.
        setoid_rewrite H0 at 4. rewrite H12, rlv_sub'.
        rewrite H19. clear - R_sub. cbn. cset_tac.
      * rewrite <-inter_subset_equal with (s':=getAnn al2); [|clear;cset_tac]. setoid_rewrite H18 at 1.
        rewrite <-minus_union, minus_minus. setoid_rewrite rlv_sub' at 1. clear; cset_tac.
  - inv_get. cbn in *.
    econstructor; eauto;
      set (K':= R'0 \ (list_union (Op.freeVars ⊝ Y) \ M' ∪ R_f) ∪ (R'0 ∩ of_list Z) ∪ (R'0 ∩ L)) in *.
    + rewrite H16; eauto.
    + rewrite subset_cardinal; eauto.
      subst K'. setoid_rewrite union_comm at 4. rewrite <-minus_union, minus_minus.
      rewrite H6. rewrite H4. clear - H4 H6. cset_tac.
    + subst K'. rewrite <-minus_union, minus_minus.
      setoid_rewrite <-rlv_sub' at 1.
      rewrite <-inter_subset_equal with (s':=R_f \ of_list Z);[|clear;cset_tac].
      setoid_rewrite H20 at 2. clear. cset_tac. 
    + subst K'. rewrite <-minus_union, minus_minus.
      rewrite incl_minus_union; [|clear; cset_tac].
      setoid_rewrite <-inter_subset_equal with (s':=list_union (Op.freeVars ⊝ Y)) at 1;
        [|clear;cset_tac].
      setoid_rewrite list_union_incl at 1; eauto.
      * instantiate(1:=R'0 ∪ L ∪ M').
        clear;cset_tac.
      * intros. inv_get. exploit H21; eauto. apply Op.freeVars_live in H9. rewrite H9, <-rlv_sub'.
        clear; cset_tac.
      * clear; cset_tac.
  - econstructor; eauto.
    + rewrite <-rlv_sub'. eauto.
    + rewrite <-minus_union, minus_minus. eapply rlive_min_incl_R in spillSnd; eauto;
                                           [|clear;cset_tac].
      rewrite spillSnd. rewrite subset_cardinal; eauto. clear; cset_tac.
    + intros. inv_get. destruct rm as [R M]. eapply H6; eauto.
      * rewrite List.map_app.
        assert (fst ⊝ rms = getAnn ⊝ als) as cheat by admit.
        rewrite cheat. eapply H20; eauto.
        (*we need ^ such a pir2 relation *)
      * exploit H11; eauto. unfold funConstr in H25. destruct H25 as [of_fst _]. rewrite of_fst.
        cbn in R_sub. admit.
      (* we need some invariant like "get rms n (R,M) -> ... -> R ∪ M [<=] of_list (fst Zs) ∪ D" *)
      * exploit H5; eauto. eapply rlive_min_incl_R in H25; eauto. cbn. clear; cset_tac.
      * intros; eauto. decide (n0 >= length rms).
        -- eapply card_Rf; eauto. eapply get_app_right_ge; eauto.
        -- replace Rf with (fst (Rf,Mf)); eauto. eapply H4; eauto.
           eapply get_app_lt_1; swap 1 2. eauto. omega.
    + eapply IHspillSnd; eauto.
      * rewrite List.map_app.
        assert (fst ⊝ rms = getAnn ⊝ als) as cheat by admit.
        rewrite cheat. eapply  H18. 
        (*we need such a pir2 relation *)
      * admit.
        (* we need some invariant like "R ∪ M [<=] of_list (fst Zs) ∪ D ? ?" *)
      * rewrite <-minus_union, minus_minus. setoid_rewrite <-rlv_sub' at 1. clear - H22; cset_tac.
      * intros; eauto. decide (n >= length rms).
        -- eapply card_Rf; eauto. eapply get_app_right_ge; eauto.
        -- replace Rf with (fst (Rf,Mf)); eauto. eapply H4; eauto.
           eapply get_app_lt_1; swap 1 2. eauto. omega.
Admitted.



