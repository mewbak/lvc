Require Import CSet Le Var.

Require Import Plus Util AllInRel Map CSet OptionR.
Require Import Val Var Env EnvTy IL Annotation Lattice DecSolve Analysis Filter Terminating.
Require Import Analysis AnalysisForward UnreachableCodeAnalysis UnreachableCode Subterm.

Set Implicit Arguments.

Local Arguments proj1_sig {A} {P} e.
Local Arguments length {A} e.
Local Arguments forward {sT} {Dom} {H} {H0} ftransform ZL st ST a.

Ltac simpl_forward_setTopAnn :=
  repeat match goal with
         | [H : ann_R eq (fst (forward ?unreachable_code_transform ?ZL ?s ?ST (setTopAnn ?sa ?a))) ?sa |- _ ] =>
           let X := fresh "H" in
           match goal with
           | [ H' : getAnn sa = a |- _ ] => fail 1
           | _ => exploit (forward_getAnn _ _ _ _ _ H) as X
           end
         end; rewrite setTopAnn_eta in *; try eassumption.

Lemma PIR2_fstNoneOrR_inv_left A B C
  : PIR2 (fstNoneOrR impb) (ojoin bool orb ⊜ A B) C
    -> length A = length B
    -> PIR2 (fstNoneOrR impb) A C.
Proof.
  intros. length_equify.
  general induction H; inv H0; simpl in *; eauto using PIR2; try solve [ congruence ].
  - inv Heql; econstructor; eauto.
    + inv Heql.
      destruct x0, y0; simpl in *; inv pf; econstructor; eauto.
      destruct b, b0, y0; simpl in *; eauto.
Qed.

Lemma PIR2_fstNoneOrR_inv_right A B C
  : PIR2 (fstNoneOrR impb) (ojoin bool orb ⊜ A B) C
    -> length A = length B
    -> PIR2 (fstNoneOrR impb) B C.
Proof.
  intros. length_equify.
  general induction H; inv H0; simpl in *; eauto using PIR2; try solve [ congruence ].
  - inv Heql; econstructor; eauto.
    + inv Heql.
      destruct x0, y0; simpl in *; inv pf; econstructor; eauto.
      destruct b, b0, y0; simpl in *; eauto.
Qed.

Instance impb_trans : Transitive impb.
Proof.
  hnf; intros [] [] []; simpl; intros; eauto.
Qed.

Lemma PIR2_fold_ojoin_inv A B C
  : PIR2 (fstNoneOrR impb) (fold_left (zip (ojoin _ join)) A B) C
    -> (forall n a, get A n a -> length a = length B)
    -> PIR2 (fstNoneOrR impb) B C.
Proof.
  intros.
  general induction A; simpl in *; eauto.
  eapply IHA; eauto using get.
  etransitivity; eauto.
  exploit PIR2_ojoin_fold as X; [ | | eapply X]; eauto.
  eapply PIR2_fstNoneOrR_inv_left. reflexivity.
  erewrite <- H0; eauto using get.
Qed.


Lemma get_union_union_b X `{BoundedSemiLattice X} (A:list (list X)) (b:list X) n x
  : get b n x
    -> (forall n a, get A n a -> ❬a❭ = ❬b❭)
    -> exists y, get (fold_left (zip join) A b) n y /\ poLe x y.
Proof.
  intros GETb LEN. general induction A; simpl in *.
  - eexists x. eauto with cset.
  - exploit LEN; eauto using get.
    edestruct (get_length_eq _ GETb (eq_sym H1)) as [y GETa]; eauto.
    exploit (zip_get join GETb GETa).
    + exploit IHA; try eapply GET; eauto.
      rewrite zip_length2; eauto using get with len.
      edestruct H3; dcr; subst. eexists; split; eauto.
      rewrite <- H8; eauto. eapply join_poLe.
Qed.


Lemma get_union_union_A X `{BoundedSemiLattice X} (A:list (list X)) a b n k x
  : get A k a
    -> get a n x
    -> (forall n a, get A n a -> ❬a❭ = ❬b❭)
    -> exists y, get (fold_left (zip join) A b) n y /\ poLe x y.
Proof.
  intros GETA GETa LEN.
  general induction A; simpl in * |- *; isabsurd.
  inv GETA; eauto.
  - exploit LEN; eauto using get.
    edestruct (get_length_eq _ GETa H1) as [y GETb].
    exploit (zip_get join GETb GETa).
    exploit (@get_union_union_b _ _ _ A); eauto.
    rewrite zip_length2; eauto using get with len.
    destruct H3; dcr; subst. eexists; split; eauto.
    rewrite <- H5; eauto. rewrite join_commutative.
    eapply join_poLe.
  - exploit IHA; eauto.
    rewrite zip_length2; eauto using get.
    symmetry; eauto using get.
Qed.

(*
Lemma get_olist_union_A' X `{OrderedType X} A a b n k x p
  : get A k a
    -> get a n (Some x)
    -> (forall n a, get A n a -> ❬a❭ = ❬b❭)
    -> get (olist_union A b) n p
    -> exists s, p = (Some s) /\ x ⊆ s.
Proof.
  intros. edestruct get_olist_union_A; eauto; dcr.
  get_functional; eauto.
Qed.
*)

Definition unreachable_code_analysis_correct sT ZL BL s a (ST:subTerm s sT)
  : ann_R poEq (fst (forward unreachable_code_transform ZL s ST a)) a
    -> annotation s a
    -> labelsDefined s (length ZL)
    -> labelsDefined s (length BL)
    -> paramsMatch s (length ⊝ ZL)
    -> poLe (snd (@forward sT _ _ _ unreachable_code_transform ZL s ST a)) (Some ⊝ BL)
    -> unreachable_code ZL BL s a.
Proof.
  intros EQ Ann DefZL DefBL PM.
  general induction Ann; simpl in *; inv DefZL; inv DefBL; inv PM;
    repeat let_case_eq; repeat simpl_pair_eqs; subst; simpl in *.
  - inv EQ.
    pose proof (ann_R_get H8); simpl in *.
    econstructor.
    eapply IHAnn; eauto;
    simpl_forward_setTopAnn.
  - assert (❬snd (forward unreachable_code_transform ZL s (subTerm_EQ_If1 eq_refl ST) sa)❭ =
            ❬snd (forward unreachable_code_transform ZL t (subTerm_EQ_If2 eq_refl ST) ta)❭). {
      eapply (@forward_length_ass _ (fun _ => bool)); eauto. symmetry.
      eapply (@forward_length_ass _ (fun _ => bool)); eauto.
    }
    repeat cases in EQ; simpl in *; try solve [congruence]; inv EQ;
    repeat simpl_forward_setTopAnn;
    econstructor; intros; try solve [congruence];
      eauto using PIR2_fstNoneOrR_inv_left, PIR2_fstNoneOrR_inv_right.
  - inv_get.
    edestruct (get_in_range _ H3) as [B ?]; eauto.
    edestruct PIR2_nth; eauto using ListUpdateAt.list_update_at_get_3; dcr. inv_get.
    destruct x1; isabsurd.
    econstructor; eauto.
  - econstructor.
  - inv EQ.
    pose proof (ann_R_get H8); simpl in *.
    econstructor.
    eapply IHAnn; eauto;
    simpl_forward_setTopAnn.
  - inv EQ.
    econstructor; eauto.
    + eapply IHAnn; eauto.
      erewrite (take_eta ❬s❭) at 1. rewrite map_app. eapply PIR2_app; eauto.
      *
        eapply PIR2_get. intros. inv_get.
        destruct x; econstructor.
        edestruct (get_forwardF (fun _ => bool) (forward unreachable_code_transform)
                                (fst ⊝ s ++ ZL) (subTerm_EQ_Fun2 eq_refl ST) H12 H4 H3).
        edestruct (@get_union_union_b (option bool) _ (option_boundedsemilattice _)).
        eapply H3.
        Focus 2. dcr.
        exploit H17. eapply zip_get. eapply map_get_1; eauto.
        eapply H14. eauto. eapply ann_R_get in H13. rewrite <- H13.
        inv H15; simpl. rewrite getAnn_setTopAnn. eapply H20.
        intros.
        inv_get.
        edestruct (@forwardF_get _ _ _ _ _ _ _ _ _ _ _ _ H13). dcr.
        destruct x7; subst;
        repeat rewrite (@forward_length sT (fun _ => bool)); eauto with len.
        rewrite Take.take_less_length. eauto with len.
        repeat rewrite (@forward_length sT (fun _ => bool)); eauto with len.
      * etransitivity; eauto. eapply PIR2_drop.
        eapply PIR2_fold_ojoin_inv. reflexivity.
        intros.
        inv_get.
        edestruct (@forwardF_get _ _ _ _ _ _ _ _ _ _ _ _ H3). dcr.
        destruct x4; subst;
        repeat rewrite (@forward_length sT (fun _ => bool)); eauto with len.
    + intros.
(*            edestruct (get_forwardF (fun _ => bool) (forward unreachable_code_transform)
                              (fst ⊝ s ++ ZL) (subTerm_EQ_Fun2 eq_refl ST) H3 H4). *)
      eapply H1 with (ST:=(subTerm_EQ_Fun2 eq_refl ST H3)); eauto.
      * assert (
            n < ❬(snd (forward unreachable_code_transform (fst ⊝ s ++ ZL) t (subTerm_EQ_Fun1 eq_refl ST) ta))❭). {
          repeat rewrite (@forward_length sT (fun _ => bool)). rewrite app_length. rewrite map_length.
          eapply get_range in H3. omega.
        }
        edestruct get_in_range; eauto.
        edestruct (get_forwardF (fun _ => bool) (forward unreachable_code_transform)
                                (fst ⊝ s ++ ZL) (subTerm_EQ_Fun2 eq_refl ST) H3 H4 g).
        assert (n <
                ❬snd (match x with
         | ⎣ al' ⎦ =>
             forward unreachable_code_transform (fst ⊝ s ++ ZL) (snd Zs) x0 (setTopAnn a0 al')
         | ⎣⎦ => (setAnn (⊥) (snd Zs), tab ⎣⎦ ‖fst ⊝ s ++ ZL‖)
                      end)❭). {
          destruct x.
          erewrite (@forward_length sT (fun _ => bool)). rewrite app_length,map_length.
          eapply get_range in H3. omega.
          simpl. rewrite map_length, app_length, map_length.
          eapply get_range in H3. omega.
        }
        edestruct get_in_range; eauto.
        exploit (@get_union_union_A (option bool) _ (option_boundedsemilattice _)).
        eapply map_get_1. apply g0. instantiate (3:=snd). eauto.
        Focus 2.
        destruct H13; dcr.
        exploit H17.
        eapply zip_get.
        eapply map_get_1. eauto. eapply H15. eauto.
        destruct x. admit.
        simpl in *. inv_get. admit.

        clear_all. intros. inv_get.
        edestruct (@forwardF_get _ _ _ _ _ _ _ _ _ _ _ _ H). dcr.
        destruct x4; subst;
          repeat erewrite (@forward_length sT (fun _ => bool)); eauto with len.
      * admit.
    + intros. admit.

Qed.

Definition livenessAnalysis s :=
  let a := Analysis.safeFixpoint (LivenessAnalysis.liveness_analysis s) in
  mapAnn (@proj1_sig _ _) (proj1_sig (proj1_sig a)).



Ltac destr_sig H :=
  match type of H with
  | context [proj1_sig ?x] => destruct x; simpl in H
  end.

Tactic Notation "destr_sig" :=
  match goal with
  | [ |- context [proj1_sig (proj1_sig ?x)] ] => destruct x; simpl
  | [ |- context [proj1_sig ?x] ] => destruct x; simpl
  end.

Definition correct s
  : labelsDefined s 0
    -> paramsMatch s nil
    -> true_live_sound Imperative nil nil s (livenessAnalysis s).
Proof.
  intros.
  unfold livenessAnalysis.
  destr_sig. destr_sig. dcr.
  eapply (@liveness_analysis_correct s nil nil s); eauto.
  eapply H3.
Qed.
