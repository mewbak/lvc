Require Import CSet Le ListUpdateAt Coq.Classes.RelationClasses.

Require Import Plus Util AllInRel Map Terminating.
Require Import Val Var Env EnvTy IL Annotation Lattice DecSolve LengthEq MoreList Status AllInRel OptionR.
Require Import Keep Subterm Analysis.

Set Implicit Arguments.


Definition forwardF (sT:stmt) (Dom:stmt->Type)
           (forward:〔params〕 ->
                    forall s (ST:subTerm s sT) (a:ann (Dom sT)), ann (Dom sT) * 〔؟(Dom sT)〕)
           (ZL:list params)
           (F:list (params * stmt)) (anF:list (ann (Dom sT)))
           (ST:forall n s, get F n s -> subTerm (snd s) sT)
  : list (ann (Dom sT) * 〔؟(Dom sT)〕).
  revert F anF ST.
  fix g 1. intros.
  destruct F as [|[Z s] F'], anF as [|a anF'].
  - eapply nil.
  - eapply nil.
  - eapply nil.
  - econstructor 2.
    refine (forward ZL s _ a).
    eapply (ST 0 (Z, s)); eauto using get.
    eapply (g F' anF').
    eauto using get.
Defined.

Arguments forwardF [sT] [Dom] forward ZL F anF ST : clear implicits.

Fixpoint forwardF_length (sT:stmt) (Dom:stmt->Type) forward
           (ZL:list params)
           (F:list (params * stmt)) (anF:list (ann (Dom sT)))
           (ST:forall n s, get F n s -> subTerm (snd s) sT) {struct F}
  : length (forwardF forward ZL F anF ST) = min (length F) (length anF).
Proof.
  destruct F as [|[Z s] F'], anF; simpl; eauto.
Qed.

Lemma forwardF_length_ass (sT:stmt) (Dom:stmt->Type)
      forward ZL F anF ST k
  : length F = k
    -> length F = length anF
    -> length (@forwardF sT Dom forward ZL F anF ST) = k.
Proof.
  intros. rewrite forwardF_length, <- H0, Nat.min_idempotent; eauto.
Qed.

Hint Resolve forwardF_length_ass : len.

Fixpoint forward (sT:stmt) (Dom: stmt -> Type) `{PartialOrder (Dom sT)} `{BoundedSemiLattice (Dom sT)}
           (ftransform :
              forall sT, list params ->
                    forall s, subTerm s sT -> Dom sT -> anni (Dom sT))
           (ZL:list (params)) (st:stmt) (ST:subTerm st sT) (a:ann (Dom sT)) {struct st}
  :  ann (Dom sT) * list (؟(Dom sT))
  := match st as st', a return st = st' -> ann (Dom sT) * list (option (Dom sT)) with
    | stmtLet x e s as st, ann1 d ans =>
      fun EQ =>
        let an := ftransform sT ZL st ST d in
        let (ans', AL) := forward Dom ftransform ZL (subTerm_EQ_Let EQ ST) (setTopAnn ans (getAnni d an)) in
        (ann1 d ans', AL)
    | stmtIf x s t, ann2 d ans ant =>
      fun EQ =>
        let an := ftransform sT ZL st ST d in
        let (ans', AL) := forward Dom ftransform ZL (subTerm_EQ_If1 EQ ST)
                                 (setTopAnn ans (getAnniLeft d an)) in
        let (ant', AL') := forward Dom ftransform ZL (subTerm_EQ_If2 EQ ST)
                                  (setTopAnn ant (getAnniRight d an)) in
        (ann2 d ans' ant', zip join AL AL')
    | stmtApp f Y as st, ann0 d as an =>
      fun EQ =>
        let an := ftransform sT ZL st ST d in
        (ann0 d, list_update_at ((fun _ => None) ⊝ ZL) (counted f) (Some (getAnni d an)))


    | stmtReturn x as st, ann0 d as an =>
      fun EQ => (ann0 d, (fun _ => bottom) ⊝ ZL)

    | stmtExtern x f Y s as st, ann1 d ans =>
      fun EQ =>
        let an := ftransform sT ZL st ST d in
        let (ans', AL) := forward Dom ftransform ZL (subTerm_EQ_Extern EQ ST)
                                 (setTopAnn ans (getAnni d an)) in
        (ann1 d ans', AL)

    | stmtFun F t as st, annF d anF ant =>
      fun EQ =>
        let ZL' := List.map fst F ++ ZL in
        let (ant', ALt) := forward Dom ftransform ZL' (subTerm_EQ_Fun1 EQ ST) ant in
        let anF' :=
            @forwardF sT Dom (forward Dom ftransform) ZL' F anF
                       (subTerm_EQ_Fun2 EQ ST) in
        let AL' := fold_left (fun ALt ALs => zip (fun (x:option _) y => if x then join x y else None) ALt ALs)
                            (snd ⊝ anF') ALt in
        (annF d (fst ⊝ anF') ant', AL')
    | _, an => fun EQ => (an, nil)
  end eq_refl.

Lemma fold_list_length A B (f:list B -> (list A * bool) -> list B) (a:list (list A * bool)) (b: list B)
  : (forall n aa, get a n aa -> ❬b❭ <= ❬fst aa❭)
    -> (forall aa b, ❬b❭ <= ❬fst aa❭ -> ❬f b aa❭ = ❬b❭)
    -> length (fold_left f a b) = ❬b❭.
Proof.
  intros LEN.
  general induction a; simpl; eauto.
  erewrite IHa; eauto 10 using get with len.
  intros. rewrite H; eauto using get.
Qed.


Lemma forwardF_get  (sT:stmt) (Dom:stmt->Type)
           (forward:〔params〕 ->
                     forall s (ST:subTerm s sT) (a:ann (Dom sT)),
                       ann (Dom sT) * list (option (Dom sT)))
           (ZL:list params)
           (F:list (params * stmt)) (anF:list (ann (Dom sT)))
           (ST:forall n s, get F n s -> subTerm (snd s) sT) aa n
           (GetBW:get (forwardF forward ZL F anF ST) n aa)
      :
        { Zs : params * stmt & {GetF : get F n Zs &
        { a : ann (Dom sT) & { getAnF : get anF n a &
        { ST' : subTerm (snd Zs) sT | aa = forward ZL (snd Zs) ST' a
        } } } } }.
Proof.
  eapply get_getT in GetBW.
  general induction anF; destruct F as [|[Z s] F']; inv GetBW.
  - exists (Z, s). eauto using get.
  - edestruct IHanF as [Zs [? [? [? ]]]]; eauto; dcr; subst.
    exists Zs. eauto 10 using get.
Qed.

Lemma get_forwardF  (sT:stmt) (Dom:stmt->Type)
           (forward:〔params〕 ->
                     forall s (ST:subTerm s sT) (a:ann (Dom sT)),
                       ann (Dom sT) * list (option (Dom sT)))
           (ZL:list params)
           (F:list (params * stmt)) (anF:list (ann (Dom sT)))
           (ST:forall n s, get F n s -> subTerm (snd s) sT) n Zs a
  :get F n Zs
    -> get anF n a
    -> { ST' | get (forwardF forward ZL F anF ST) n (forward ZL (snd Zs) ST' a)}.
Proof.
  intros GetF GetAnF.
  eapply get_getT in GetF.
  eapply get_getT in GetAnF.
  general induction GetAnF; destruct Zs as [Z s]; inv GetF; simpl.
  - eexists. econstructor.
  - destruct x'0; simpl.
    edestruct IHGetAnF; eauto.
    eexists x0. econstructor. eauto.
Qed.

Ltac inv_get_step1 dummy := first [inv_get_step |
                            match goal with
                            | [ H: get (forwardF ?f ?ZL ?F ?anF ?ST) ?n ?x |- _ ]
                              => eapply forwardF_get in H;
                                destruct H as [? [? [? [? [? ]]]]]
                            end
                           ].

Tactic Notation "inv_get_step" := inv_get_step1 idtac.
Tactic Notation "inv_get" := inv_get' inv_get_step1.

Lemma PIR2_ojoin_zip A `{BoundedSemiLattice A} (a:list (option A)) a' b b'
  : poLe a a'
    -> poLe b b'
    -> PIR2 (fstNoneOrR poLe) (ojoin _ join ⊜ a b) (ojoin _ join ⊜ a' b').
Proof.
  intros. hnf in H1,H2. general induction H1; inv H2; simpl; eauto using PIR2.
  econstructor; eauto.
  destruct y, y0; inv pf; inv pf0; simpl; eauto using fstNoneOrR.
  - econstructor. rewrite H6. rewrite join_commutative. eapply join_poLe.
  - econstructor. rewrite H6. eapply join_poLe.
  - econstructor. rewrite H6, H7. eauto.
Qed.

Lemma update_at_poLe A `{PartialOrder A} B (L:list B) n (a:option A) b
  : poLe a b
    -> poLe (list_update_at (tab None ‖L‖) n a)
            (list_update_at (tab None ‖L‖) n b).
Proof.
  intros.
  general induction L; simpl; eauto using PIR2.
  - destruct n; simpl; eauto using @PIR2.
    econstructor. econstructor.
    eapply IHL; eauto.
Qed.


Lemma PIR2_ojoin_fold X `{BoundedSemiLattice X} (A A':list (list (option X))) (B B':list (option X))
  : poLe A A'
    -> poLe B B'
    -> poLe (fold_left (fun ALt ALs : 〔؟ X〕 =>
                         (fun x y : ؟ X => if x then ojoin _ join x y else ⎣⎦) ⊜ ALt ALs) A B)
           (fold_left (fun ALt ALs : 〔؟ X〕 =>
                         (fun x y : ؟ X => if x then ojoin _ join x y else ⎣⎦) ⊜ ALt ALs) A' B').
Proof.
  intros. simpl in *.
  general induction H1; simpl; eauto.
  eapply IHPIR2; eauto.
  clear IHPIR2 H1.
  general induction pf; inv H2; simpl; eauto using PIR2.
  econstructor; eauto.
  repeat cases; subst; eauto using fstNoneOrR; inv pf; inv pf1; simpl.
  - destruct y; econstructor; rewrite H5; eauto. eapply join_poLe.
  - econstructor. rewrite H3, H6. reflexivity.
Qed.


Lemma forward_monotone (sT:stmt) (Dom : stmt -> Type) `{BoundedSemiLattice (Dom sT)}
      (f: forall sT, list params ->
                forall s, subTerm s sT -> Dom sT -> anni (Dom sT))
      (fMon:forall s (ST ST':subTerm s sT) ZL,
          forall a b, a ⊑ b -> f sT ZL s ST a ⊑ f sT ZL s ST' b)
  : forall (s : stmt) (ST ST':subTerm s sT) (ZL:list params),
    forall a b : ann (Dom sT), annotation s a ->  a ⊑ b ->
                           forward Dom f ZL ST a ⊑ forward Dom f ZL ST' b.
Proof with eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnni.
  intros s.
  sind s; destruct s; intros ST ST' ZL d d' Ann LE; simpl forward; inv LE; inv Ann;
    simpl forward; repeat let_pair_case_eq; subst; eauto 10 using @ann_R.
  - econstructor; simpl; eauto.
    + econstructor. eauto.
      eapply IH; eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnni.
    + eapply IH; eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnni.
  - econstructor; simpl; eauto.
    + econstructor; eauto.
      eapply (IH s1); eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnniLeft.
      eapply (IH s2); eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnniRight.
    + eapply PIR2_ojoin_zip.
      * eapply IH; eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnniLeft.
      * eapply IH; eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnniRight.
  - econstructor; eauto. simpl.
    eapply update_at_poLe.
    econstructor. eapply poLe_getAnni; eauto.
  - econstructor; simpl; eauto.
  - econstructor; eauto.
    + econstructor. eauto.
      eapply IH; eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnni.
    + eapply IH; eauto using setTopAnn_annotation, poLe_setTopAnn, poLe_getAnni.
  - assert (forall (n : nat) (x x' : ann (Dom sT) * 〔؟ (Dom sT)〕),
               get (forwardF (forward Dom f) (fst ⊝ s ++ ZL) s ans
                        (subTerm_EQ_Fun2 eq_refl ST)) n x ->
               get (forwardF (forward Dom f) (fst ⊝ s ++ ZL) s bns
                        (subTerm_EQ_Fun2 eq_refl ST')) n x' ->
               x ⊑ x'). {
      intros; inv_get.
      eapply IH; eauto. eapply H3; eauto.
    }
    econstructor; simpl; eauto.
    + econstructor; eauto with len.
      * intros. inv_map H6. inv_map H7.
        exploit H5; eauto. eapply H13.
      * eapply IH; eauto.
    + eapply PIR2_ojoin_fold.
      * eapply PIR2_get; eauto with len.
        intros. inv_map H6. inv_map H7.
        exploit H5; eauto. eapply H13.
      * eapply IH; eauto.
Qed.
(*
Lemma backward_ext (sT:stmt) (Dom : stmt -> Type) `{PartialOrder (Dom sT)}
      (f: forall sT, list params -> list (Dom sT) ->
                forall s, subTerm s sT -> anni (Dom sT) -> Dom sT)
      (fMon:forall s (ST:subTerm s sT) ZL AL AL',
          AL ≣ AL' -> forall a b, a ≣ b -> f sT ZL AL s ST a ≣ f sT ZL AL' s ST b)
  : forall (s : stmt) (ST:subTerm s sT) ZL AL AL',
    AL ≣ AL' -> forall a b : ann (Dom sT),
      annotation s a -> a ≣ b -> backward Dom f ZL AL ST a ≣ backward Dom f ZL AL' ST b.
Proof.
  intros s.
  sind s; destruct s; intros ST ZL AL AL' ALLE d d' Ann LE; simpl backward; inv LE; inv Ann;
    simpl backward; eauto 10 using @ann_R, tab_false_impb, update_at_impb, zip_orb_impb.
  - econstructor; eauto.
    + eapply fMon; eauto.
      econstructor.
      eapply getAnn_poEq. eauto.
    + eapply IH; eauto.
  - econstructor; eauto.
    + simpl; eauto.
      eapply fMon; eauto.
      econstructor; eapply getAnn_poEq.
      eapply (IH s1); eauto.
      eapply (IH s2); eauto.
    + eapply IH; eauto.
    + eapply IH; eauto.
  - econstructor; eauto.
  - econstructor; simpl; eauto.
  - econstructor; eauto.
    + eapply fMon; eauto.
      econstructor.
      eapply getAnn_poEq. eapply (IH s); eauto.
    + eapply IH; eauto.
  - assert (AL'LE:getAnn ⊝ ans ++ AL ≣ getAnn ⊝ bns ++ AL'). {
      eapply PIR2_app; eauto.
      eapply PIR2_get; intros; inv_get.
      eapply getAnn_poEq. eapply H2; eauto. eauto with len.
    }
    assert (getAnn
              ⊝ backwardF (backward Dom f) (fst ⊝ s ++ ZL) (getAnn ⊝ ans ++ AL) s ans
              (subTerm_EQ_Fun2 eq_refl ST) ++ AL
              ≣ getAnn
              ⊝ backwardF (backward Dom f) (fst ⊝ s ++ ZL) (getAnn ⊝ bns ++ AL') s bns
              (subTerm_EQ_Fun2 eq_refl ST) ++ AL'). {
      eapply PIR2_app; eauto.
      eapply PIR2_get; eauto 20 with len; intros; inv_get.
      eapply getAnn_poEq.
      assert (x5 = x11) by eapply subTerm_PI; subst.
      eapply IH; eauto.
      exploit H2; eauto.
    }
    econstructor; eauto.
    + eapply fMon; eauto.
      econstructor; eauto.
      eapply getAnn_poEq. eapply IH; eauto.
    + eauto 30 with len.
    + intros; inv_get.
      assert (x9 = x3) by eapply subTerm_PI; subst.
      eapply IH; eauto.
      eapply H2; eauto.
    + eapply IH; eauto.
Qed.
 *)

Lemma forward_annotation sT (Dom:stmt->Type) `{BoundedSemiLattice (Dom sT)} s
      (f: forall sT, list params ->
                forall s, subTerm s sT -> Dom sT -> anni (Dom sT))
  : forall ZL a (ST:subTerm s sT), annotation s a
               -> annotation s (fst (forward Dom f ZL ST a)).
Proof.
  sind s; intros ZL a ST Ann; destruct s; inv Ann; simpl;
    repeat let_pair_case_eq; subst; eauto 20 using @annotation, setTopAnn_annotation.
  - econstructor; eauto with len.
    + intros. inv_get.
      * eapply IH; eauto.
Qed.


Instance makeForwardAnalysis (Dom:stmt -> Type)
         `{forall s, PartialOrder (Dom s) }
         (BSL:forall s, BoundedSemiLattice (Dom s))
         (f: forall sT, list params ->
                   forall s, subTerm s sT -> Dom sT -> anni (Dom sT))
         (fMon:forall sT s (ST ST':subTerm s sT) ZL,
             forall a b, a ⊑ b -> f sT ZL s ST a ⊑ f sT ZL s ST' b)
         (Trm: forall s, Terminating (Dom s) poLt)
  : forall s, Analysis { a : ann (Dom s) | annotation s a } :=
  {
    analysis_step := fun X : {a : ann (Dom s) | annotation s a} =>
                      let (a, Ann) := X in
                      exist (fun a0 : ann (Dom s) => annotation s a0)
                            (fst (forward Dom f nil (subTerm_refl _) a)) (forward_annotation Dom f nil (subTerm_refl _) Ann);
    initial_value :=
      exist (fun a : ann (Dom s) => annotation s a)
            (setAnn bottom s)
            (setAnn_annotation bottom s)
  }.
Proof.
  - intros [d Ann]; simpl.
    pose proof (@ann_bottom s (Dom s) _ _ _ Ann).
    eapply H0.
  - intros. eapply terminating_sig.
    eapply terminating_ann. eauto.
  - intros [a Ann] [b Bnn] LE; simpl in *.
    eapply (forward_monotone Dom f (fMon s)); eauto.
Defined.