Require Import CSet Util Fresh MoreExp Take MoreList Filter OUnion.
Require Import IL Annotation LabelsDefined Sawtooth InRel Liveness UnreachableCode.
Require Import Sim SimTactics SimI.

Set Implicit Arguments.
Unset Printing Records.


Hint Extern 5 =>
match goal with
| [ H : ?A = ⎣ true ⎦, H' : ?A = ⎣ false ⎦ |- _ ] => exfalso; congruence
| [ H : ?A <> ⎣ ?t ⎦, H' : ?A = ⎣ ?t ⎦ |- _ ] => exfalso; congruence
| [ H : ?A = None , H' : ?A = Some _ |- _ ] => exfalso; congruence
| [ H : ?A <> ⎣ true ⎦ , H' : ?A <> ⎣ false ⎦ |- ?A = None ] =>
  case_eq (A); [intros [] ?| intros ?]; congruence
end.

Definition compileF (compile : forall (RZL:list (bool * params)) (s:stmt) (a:ann bool), stmt)
(RZL:list (bool * params)) :=
  fix f (F:〔params * stmt〕) (ans:list (ann bool)) :=
    match F, ans with
    | (Z,s)::F, a::ans =>
      if getAnn a then (Z, compile RZL s a) :: f F ans
      else  f F ans
    | _, _ => nil
    end.

Fixpoint compile (RZL:list (bool * params)) (s:stmt) (a:ann bool) :=
  match s, a with
    | stmtLet x e s, ann1 _ an =>
      stmtLet x e (compile RZL s an)
    | stmtIf e s t, ann2 _ ans ant =>
      if [exp2bool e = Some true] then
        (compile RZL s ans)
      else if [ exp2bool e = Some false ] then
             (compile RZL t ant)
           else
             stmtIf e (compile RZL s ans) (compile RZL t ant)
    | stmtApp f Y, ann0 _ =>
      let lvZ := nth (counted f) RZL (false, nil) in
      stmtApp (LabI (countTrue (fst ⊝ (take (counted f) RZL)))) Y
    | stmtReturn x, ann0 _ => stmtReturn x
    | stmtExtern x f e s, ann1 lv an =>
      stmtExtern x f e (compile RZL s an)
    | stmtFun F t, annF lv ans ant =>
      let LV' := pair ⊜ (getAnn ⊝ ans) (fst ⊝ F) ++ RZL in
      let F' := compileF compile LV' F ans in
      match F' with
      | nil => compile LV' t ant
      | _ => stmtFun F' (compile LV' t ant)
      end
    | s, _ => s
  end.

Lemma compileF_Z_filter_by RZL F als (LEN: ❬F❭ = ❬als❭)
  : fst ⊝ compileF compile RZL F als
    = filter_by (fun b => b) (getAnn ⊝ als) (fst ⊝ F).
Proof.
  length_equify. general induction LEN; simpl; eauto.
  destruct x as [Z s]; cases; simpl; f_equal; eauto.
Qed.

Lemma compileF_get RZL F n ans Zs a
  : get F n Zs
    -> get ans n a
    -> getAnn a = true
    -> get (compileF compile RZL F ans) (countTrue (getAnn ⊝ (take n ans)))
          (fst Zs, compile RZL (snd Zs) a).
Proof.
  intros GetF GetAns EQ.
  general induction ans; destruct F as [|[Z s] ?]; isabsurd.
  - inv GetF; inv GetAns.
    + simpl. rewrite EQ; eauto using get.
    + simpl. cases; simpl; eauto using get.
Qed.

Lemma compileF_get_inv RZL F ans Z' s' n'
  : get (compileF compile RZL F ans) n' (Z', s')
    -> exists Zs a n, get F n Zs
      /\ get ans n a
      /\ getAnn a = true
      /\ Z' = fst Zs
      /\ s' = compile RZL (snd Zs) a
      /\ n' = countTrue (getAnn ⊝ (take n ans)).
Proof.
  intros Get.
  general induction ans; destruct F as [|[Z s] ?]; simpl in *; isabsurd.
  - cases in Get.
    + inv Get.
      * eauto 20 using get.
      * clear Get. edestruct IHans as [Zs [a' [n' [lv ?]]]]; eauto; dcr; subst.
        exists Zs, a', (S n'). simpl; rewrite <- Heq; eauto 20 using get.
    + edestruct IHans as [Zs [a' [n [lv ?]]]]; eauto; dcr; subst.
      exists Zs, a', (S n). simpl; rewrite <- Heq; eauto 20 using get.
Qed.

Lemma compile_occurVars RZL s uc
  : occurVars (compile RZL s uc) ⊆ occurVars s.
Proof.
  revert RZL uc.
  sind s; destruct s; intros RZL uc; destruct uc; simpl; eauto.
  - rewrite IH; eauto.
  - repeat cases; simpl; repeat rewrite IH; eauto with cset.
  - rewrite IH; eauto.
  - cases.
    + rewrite IH; eauto.
    + rewrite Heq; clear Heq; simpl.
      eapply incl_union_lr; eauto.
      eapply list_union_incl; eauto with cset.
      intros; inv_get. destruct x as [Z s'].
      edestruct compileF_get_inv; eauto; dcr; subst.
      eapply incl_list_union. eauto using map_get_1.
      simpl. rewrite IH; eauto.
Qed.

Lemma compile_freeVars RZL s uc
  : freeVars (compile RZL s uc) ⊆ freeVars s.
Proof.
  revert RZL uc.
  sind s; destruct s; intros RZL uc; destruct uc; simpl; eauto.
  - rewrite IH; eauto.
  - repeat cases; simpl; repeat rewrite IH; eauto with cset.
  - rewrite IH; eauto.
  - cases.
    + rewrite IH; eauto.
    + rewrite Heq; clear Heq; simpl.
      eapply incl_union_lr; eauto.
      eapply list_union_incl; eauto with cset.
      intros; inv_get. destruct x as [Z s'].
      edestruct compileF_get_inv; eauto; dcr; subst.
      eapply incl_list_union. eauto using map_get_1.
      simpl. rewrite IH; eauto.
Qed.

Lemma compileF_length LV F ans
  : length F = length ans
    -> length (compileF compile LV F ans) = countTrue (getAnn ⊝ ans).
Proof.
  intros. length_equify.
  general induction H; simpl; eauto.
  cases; subst. cases; simpl; eauto.
Qed.

Lemma getAnn_eq X Y Y' (F:list (Y * Y')) (als:list (ann X))
  : ❬F❭ = ❬als❭
    -> getAnn ⊝ als = fst ⊝ pair ⊜ (getAnn ⊝ als) (fst ⊝ F).
Proof.
  intros LEN. rewrite fst_zip_pair; eauto with len.
Qed.

Lemma getAnn_take_eq X Y Y' (F:list (Y * Y')) (als:list (ann X)) k a LV
  : ❬F❭ = ❬als❭
    -> get als k a
    -> getAnn ⊝ take k als = fst ⊝ take k (pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ LV).
Proof.
  intros LEN Get.
  rewrite take_app_lt; eauto with len.
  repeat rewrite map_take.
  rewrite fst_zip_pair; eauto with len.
Qed.

Local Hint Extern 0 =>
match goal with
| [ H : exp2bool ?e <> Some ?t , H' : exp2bool ?e <> Some ?t -> ?B = ?C |- _ ] =>
  specialize (H' H); subst
| [ H : exp2bool ?e = Some true , H' : exp2bool ?e <> Some false -> ?B = ?C |- _ ] =>
  let H'' := fresh "H" in
  assert (H'':exp2bool e <> Some false) by congruence;
    specialize (H' H''); subst
end.

Hint Extern 5 =>
match goal with
| [ H : Is_true ?B, EQ : ?A = ?B |- Is_true ?A] => rewrite EQ; eapply H
| [ H : Is_true ?B, EQ : ?B = ?A |- Is_true ?A] => rewrite <- EQ; eapply H
end.

Lemma compileF_nil_als_false RZL F als (LEN:❬F❭ = ❬als❭)
  : nil = compileF compile RZL F als
    -> forall n a, get als n a -> getAnn a = false.
Proof.
  length_equify.
  general induction LEN; simpl in *.
  - isabsurd.
  - destruct x as [Z s]; simpl in *.
    cases in H.
    + inv H.
    + inv H0; eauto.
Qed.

Lemma compileF_not_nil_exists_true RZL F als (LEN:❬F❭ = ❬als❭)
  : nil <> compileF compile RZL F als
    -> exists n a, get als n a /\ getAnn a.
Proof.
  length_equify.
  general induction LEN; simpl in *.
  - isabsurd.
  - destruct x as [Z s]; simpl in *.
    cases in H.
    + eexists 0, y; split; eauto using get.
      rewrite <- Heq; eauto.
    + edestruct IHLEN; dcr; eauto 20 using get.
Qed.

Lemma trueIsCalled_compileF_not_nil (i : sc) (ZL : 〔params〕)
      (s : stmt) (slv : ann bool) k F als RL x
  : unreachable_code i (fst ⊝ F ++ ZL) (getAnn ⊝ als ++ RL) s slv
    -> getAnn slv
    -> trueIsCalled s (LabI k)
    -> get als k x
    -> ❬F❭ = ❬als❭
    -> nil = compileF compile (pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ pair ⊜ RL ZL) F als
    -> False.
Proof.
  intros UC Ann IC Get Len.
  assert (LenNEq:length (compileF compile (pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ pair ⊜ RL ZL) F als)
                 <> 0). {
    rewrite compileF_length; eauto.
    edestruct (unreachable_code_trueIsCalled UC IC); eauto; simpl in *; dcr.
    inv_get.
    eapply countTrue_exists. eapply map_get_eq; eauto.
    eapply Is_true_eq_true; eauto. rewrite <- H1; eauto.
  }
  intros EQ. eapply LenNEq. rewrite <- EQ. reflexivity.
Qed.

Lemma DCE_callChain RL ZL F als t alt l' k ZsEnd aEnd n
      (IH : forall k Zs,
          get F k Zs ->
       forall (ZL : 〔params〕) (RL : 〔bool〕) (lv : ann bool) (n : nat),
       unreachable_code SoundAndComplete ZL RL (snd Zs) lv ->
       trueIsCalled (snd Zs) (LabI n) ->
       getAnn lv ->
       trueIsCalled (compile (pair ⊜ RL ZL) (snd Zs) lv)
                (LabI (countTrue (fst ⊝ take n (pair ⊜ RL ZL)))))
  (UC:unreachable_code SoundAndComplete (fst ⊝ F ++ ZL) (getAnn ⊝ als ++ RL) t alt)
  (LEN: ❬F❭ = ❬als❭)
  (UCF:forall (n : nat) (Zs : params * stmt) (a : ann bool),
       get F n Zs ->
       get als n a ->
       unreachable_code SoundAndComplete (fst ⊝ F ++ ZL)
         (getAnn ⊝ als ++ RL) (snd Zs) a)
  (Ann: getAnn alt)
  (IC: trueIsCalled t (LabI l'))
  (CC: callChain trueIsCalled F (LabI l') (LabI k))
  (GetF: get F k ZsEnd)
  (ICEnd: trueIsCalled (snd ZsEnd) (LabI (❬F❭ + n)))
  (GetAls: get als k aEnd)
: callChain trueIsCalled
            (compileF compile (pair ⊜ (getAnn ⊝ als ++ RL) (fst ⊝ F ++ ZL)) F als)
            (LabI (countTrue (fst ⊝ take l' (pair ⊜ (getAnn ⊝ als ++ RL)
                                                  (fst ⊝ F ++ ZL)))))
            (LabI (countTrue (getAnn ⊝ als) +
                   countTrue (fst ⊝ take n (pair ⊜ RL ZL)))).
Proof.
  general induction CC.
  - exploit unreachable_code_trueIsCalled as IMPL; try eapply IC; eauto.
    simpl in *; dcr; inv_get. rewrite H1 in Ann.
    exploit compileF_get; eauto.
    eapply Is_true_eq_true; eauto.
    econstructor 2; [ | | econstructor 1 ].
    rewrite zip_app at 2; eauto with len.
    rewrite take_app_lt; eauto 20 with len.
    rewrite map_take. rewrite <- getAnn_eq; eauto.
    rewrite <- map_take. eauto. simpl.
    eapply IH in ICEnd; eauto.
    rewrite zip_app in ICEnd; eauto with len.
    rewrite take_app_ge in ICEnd; eauto 20 with len.
    rewrite zip_length2 in ICEnd; eauto with len.
    rewrite map_length in ICEnd.
    orewrite (❬F❭ + n - ❬als❭ = n) in ICEnd. simpl.
    rewrite map_app in ICEnd. rewrite countTrue_app in ICEnd.
    rewrite <- getAnn_eq in ICEnd; eauto.

  - exploit unreachable_code_trueIsCalled; try eapply IC; eauto.
    simpl in *; dcr; inv_get. assert (getAnn x0).
    rewrite <- H4. eauto.
    exploit compileF_get; eauto.
    eapply Is_true_eq_true; eauto.
    econstructor 2; [ | | ].
    rewrite zip_app at 2; eauto with len.
    rewrite take_app_lt; eauto 20 with len.
    rewrite map_take. rewrite <- getAnn_eq; eauto.
    rewrite <- map_take. eauto.
    simpl.
    eapply IH in H0; eauto.
    eapply (IHCC _ _ _ (snd Zs)); eauto.
Qed.

Lemma DCE_callChain' RL ZL F als l' k
      (IH : forall k Zs,
          get F k Zs ->
       forall (ZL : 〔params〕) (RL : 〔bool〕) (lv : ann bool) (n : nat),
       unreachable_code SoundAndComplete ZL RL (snd Zs) lv ->
       trueIsCalled (snd Zs) (LabI n) ->
       getAnn lv ->
       trueIsCalled (compile (pair ⊜ RL ZL) (snd Zs) lv)
                (LabI (countTrue (fst ⊝ take n (pair ⊜ RL ZL)))))
  (LEN: ❬F❭ = ❬als❭)
  (UCF:forall (n : nat) (Zs : params * stmt) (a : ann bool),
       get F n Zs ->
       get als n a ->
       unreachable_code SoundAndComplete (fst ⊝ F ++ ZL)
         (getAnn ⊝ als ++ RL) (snd Zs) a)
  (Ann: get (getAnn ⊝ als ++ RL) l' true)
  (CC: callChain trueIsCalled F (LabI l') (LabI k))
: callChain trueIsCalled
            (compileF compile (pair ⊜ (getAnn ⊝ als ++ RL) (fst ⊝ F ++ ZL)) F als)
            (LabI (countTrue (fst ⊝ take l' (pair ⊜ (getAnn ⊝ als ++ RL)
                                                  (fst ⊝ F ++ ZL)))))
            (LabI (countTrue (fst ⊝ take k (pair ⊜ (getAnn ⊝ als ++ RL)
                                                  (fst ⊝ F ++ ZL))))).
Proof.
  general induction CC.
  - econstructor.
  - inv_get.
    exploit unreachable_code_trueIsCalled; try eapply H0; eauto.
    simpl in *; dcr; inv_get. assert (x0 = true).
    destruct (getAnn x), x0; isabsurd; eauto.
    exploit compileF_get; eauto.
    econstructor 2; [ | | ].
    rewrite zip_app at 2; eauto with len.
    rewrite take_app_lt; eauto 20 with len.
    rewrite map_take. rewrite <- getAnn_eq; eauto.
    rewrite <- map_take. eauto.
    simpl.
    eapply IH in H0; eauto. rewrite <- H3. eauto.
    subst. eauto.
Qed.

Lemma DCE_trueIsCalled ZL RL s lv n
  : unreachable_code SoundAndComplete ZL RL s lv
    -> trueIsCalled s (LabI n)
    -> getAnn lv
    -> trueIsCalled (compile (pair ⊜ RL ZL) s lv)
               (LabI (countTrue (fst ⊝ take n (pair ⊜ RL ZL)))).
Proof.
  intros Live IC.
  revert ZL RL lv n Live IC.
  sind s; simpl; intros; invt unreachable_code; invt trueIsCalled;
    simpl in *; eauto using trueIsCalled.
  - repeat cases; eauto using trueIsCalled.
  - repeat cases; eauto using trueIsCalled.
  - eapply callChain_cases in H6. destruct H6; subst.
    + cases.
      * exploit (IH t) as IHt; eauto.
        rewrite <- zip_app; eauto with len.
        rewrite zip_app in IHt; eauto with len.
        rewrite take_app_ge in IHt; eauto 20 with len.
        rewrite zip_length2 in IHt; eauto with len.
        rewrite map_length in IHt.
        orewrite (❬F❭ + n - ❬als❭ = n) in IHt. simpl.
        rewrite map_app in IHt. rewrite countTrue_app in IHt.
        rewrite <- getAnn_eq in IHt; eauto.
        erewrite <- compileF_length in IHt; eauto.
        erewrite <- Heq in IHt. eauto.
      * rewrite Heq. econstructor. econstructor 1.
        exploit (IH t) as IHt; eauto.
        rewrite <- zip_app; eauto with len.
        rewrite compileF_length; eauto. simpl.
        rewrite zip_app in IHt; eauto with len.
        rewrite take_app_ge in IHt; eauto 20 with len.
        rewrite zip_length2 in IHt; eauto with len.
        rewrite map_length in IHt.
        orewrite (❬F❭ + n - ❬als❭ = n) in IHt. simpl.
        rewrite map_app in IHt. rewrite countTrue_app in IHt.
        erewrite <- getAnn_eq in IHt; eauto.
    + destruct H2 as [? [? [? ?]]]; dcr.
      destruct l' as [l'].
      cases.
      * exfalso. inv_get.
        eapply get_in_range in H2. destruct H2. inv_get.
        eapply trueIsCalled_compileF_not_nil.
        eapply H0. eauto. eauto. eauto. eauto. eauto.
      * rewrite Heq; clear Heq p b. inv_get.
        rewrite <- zip_app; eauto with len.
        econstructor; eauto. simpl.
        rewrite compileF_length; eauto.
        eapply DCE_callChain; eauto.
Qed.

Lemma DCE_noUnreachableCode ZL RL s lv
  : unreachable_code SoundAndComplete ZL RL s lv
    -> getAnn lv
    -> noUnreachableCode trueIsCalled (compile (pair ⊜ RL ZL) s lv).
Proof.
  intros Live GetAnn.
  induction Live; simpl; repeat cases; eauto using noUnreachableCode.
  - specialize (H NOTCOND0). specialize (H0 NOTCOND). subst.
    simpl in *. econstructor; eauto.
  - rewrite <- zip_app; eauto with len.
  - rewrite Heq; clear Heq.
    econstructor; eauto using noUnreachableCode.
    + intros. destruct Zs as [Z' s'].
      edestruct compileF_get_inv as [Zs' [a [n' ?]]]; eauto; dcr; subst; simpl.
      simpl in *.
      rewrite <- zip_app; eauto with len.
      eapply H2; eauto. rewrite H7; eauto.
    + rewrite <- zip_app; eauto with len.
    + intros. simpl in *.
      edestruct get_in_range as [Zs ?]; eauto. destruct Zs as [Z' s'].
      edestruct compileF_get_inv as [Zs' [a [n' [lv' ?]]]]; eauto.
      dcr; subst; simpl.
      exploit H3 as ICF; eauto. rewrite H8; eauto.
      rewrite <- zip_app; eauto with len.
      destruct ICF as [[l'] [? ?]].
      exploit DCE_trueIsCalled; eauto.
      eexists; split; eauto.
      exploit DCE_callChain'; eauto using DCE_trueIsCalled.
      exploit unreachable_code_trueIsCalled; eauto.
      dcr; subst; simpl in *. rewrite H12 in GetAnn.
      destruct x; isabsurd; eauto.
      rewrite zip_app in H9 at 3; [| eauto with len].
      rewrite take_app_lt in H9.
      setoid_rewrite map_take in H9 at 2.
      rewrite <- getAnn_eq in H9; eauto.
      setoid_rewrite <- map_take in H9. eauto.
      eauto with len.
Qed.

Lemma DCE_paramsMatch i PL ZL RL s lv
  : unreachable_code i ZL RL s lv
    -> getAnn lv
    -> paramsMatch s PL
    -> paramsMatch (compile (pair ⊜ RL ZL) s lv) (filter_by (fun b => b) RL PL).
Proof.
  intros UC Ann PM.
  general induction UC; inv PM; simpl; repeat cases; eauto using paramsMatch.
  - specialize (H NOTCOND0). specialize (H0 NOTCOND). subst. simpl in *.
    econstructor; eauto.
  - simpl in *. rewrite take_zip. rewrite fst_zip_pair; eauto.
    exploit (get_filter_by (fun b => b) H0 H5). destruct a,b; isabsurd; eauto.
    rewrite map_id in H3.
    econstructor; eauto.
    eapply get_range in H. eapply get_range in H0.
    repeat rewrite take_length_le; omega.
  - rewrite <- zip_app; eauto with len. exploit IHUC; eauto.
    rewrite filter_by_app in H0; eauto with len.
    rewrite filter_by_nil in H0; eauto.
    intros; inv_get; eauto using compileF_nil_als_false.
  - rewrite Heq; clear Heq p b.
    rewrite <- zip_app in *; eauto with len.
    econstructor.
    + intros ? [Z s] Get.
      eapply compileF_get_inv in Get; destruct Get; dcr; subst; simpl; eauto.
      exploit H2; eauto. rewrite H8; eauto.
      rewrite compileF_Z_filter_by, map_filter_by, <- filter_by_app; eauto with len.
    + rewrite compileF_Z_filter_by, map_filter_by, <- filter_by_app; eauto with len.
Qed.

Module I.

  Definition ArgRel (V V':onv val) (G:bool * params) (VL VL': list val) : Prop :=
      VL' = VL /\
      length (snd G) = length VL /\ V = V'.


  Definition ParamRel (G:bool * params) (Z Z' : list var) : Prop :=
    Z' = Z /\ snd G = Z.

Instance SR : ProofRelationI (bool * params) := {
   ParamRelI := ParamRel;
   ArgRelI := ArgRel;
   BlockRelI := fun lvZ b b' => (*block_Z b = block_Z b' *) True;
   Image AL := countTrue (List.map fst AL);
   IndexRelI AL n n' :=
     n' = countTrue (fst ⊝ (take n AL)) /\ exists Z, get AL n (true, Z)
}.
- intros. hnf in H, H0; dcr; subst.
  eauto.
- intros AL' AL n n' [H H']; subst.
  split. clear H' H.
  + general induction AL'; simpl.
    * orewrite (n - 0 = n). omega.
    * destruct n; simpl; eauto. cases; simpl; eauto.
  + destruct H' as [? ?]. rewrite get_app_ge in H0; eauto.
Defined.


Lemma inv_extend s L L' RZL als  Z f
(LEN: ❬s❭ = ❬als❭)
(H: forall (f : nat) (Z : params),
       get RZL f (true, Z) ->
       exists b b' : I.block, get L f b /\ get L' (countTrue (fst ⊝ take f RZL)) b')
(Get : get (pair ⊜ (getAnn ⊝ als) (fst ⊝ s) ++ RZL) f (true, Z))
  :  exists b b' : I.block, get (mapi I.mkBlock s ++ L) f b /\
                       get (mapi I.mkBlock (compileF compile (pair ⊜ (getAnn ⊝ als) (fst ⊝ s) ++ RZL) s als) ++ L') (countTrue (fst ⊝ take f (pair ⊜ (getAnn ⊝ als) (fst ⊝ s) ++ RZL))) b'.
Proof.
  get_cases Get; inv_get.
  - exploit compileF_get; eauto.
    do 2 eexists; split; eauto using get_app, mapi_get_1.
    eapply get_app. eapply mapi_get_1.
    erewrite <- getAnn_take_eq; eauto.
  - edestruct H as [b [b' [? ?]]]; eauto.
    exists b, b'; split.
    eapply get_app_right; eauto.
    rewrite mapi_length. rewrite zip_length2; eauto with len.
    rewrite map_length.
    rewrite zip_length2 in H1; eauto with len.
    rewrite map_length in H1. omega.
    eapply get_app_right; eauto.
    rewrite take_app_ge; eauto. rewrite map_app.
    rewrite countTrue_app.
    rewrite mapi_length.
    rewrite compileF_length; eauto.
    rewrite <- getAnn_eq; eauto.
Qed.


Lemma sim_I i ZL RL r L L' V s (a:ann bool) (Ann:getAnn a)
  : unreachable_code i ZL RL s a
-> simILabenv Bisim r SR (pair ⊜ RL ZL) L L'
-> (forall (f:nat) Z,
      get (pair ⊜ RL ZL) f (true, Z)
      -> exists (b b' : I.block),
        get L f b /\
        get L' (countTrue (fst ⊝ (take f (pair ⊜ RL ZL)))) b')
-> sim'r r Bisim (L,V, s) (L',V, compile (pair ⊜ RL ZL) s a).
Proof.
  unfold sim'r. revert_except s.
  sind s; destruct s; simpl; intros; invt unreachable_code; simpl in * |- *.
  - case_eq (exp_eval V e); intros.
    + pone_step; eauto.
    + pno_step.
  - repeat cases.
    + edestruct (exp2bool_val2bool V); eauto; dcr.
      eapply sim'_expansion_closed.
      eapply (IH s1); eauto.
      eapply star2_silent.
      econstructor; eauto. eapply star2_refl.
      eapply star2_refl.
    + edestruct (exp2bool_val2bool V); eauto; dcr.
      eapply sim'_expansion_closed.
      eapply (IH s2); eauto.
      eapply star2_silent.
      econstructor 3; eauto. eapply star2_refl.
      eapply star2_refl.
    + remember (exp_eval V e). symmetry in Heqo.
      destruct o. case_eq (val2bool v); intros.
      pfold; econstructor; try eapply plus2O; eauto.
      econstructor; eauto.
      econstructor; eauto.
      left; eapply (IH s1); eauto using agree_on_incl.
      pfold; econstructor; try eapply plus2O; eauto.
      econstructor 3; eauto.
      econstructor 3; eauto.
      left; eapply (IH s2); eauto using agree_on_incl.
      pfold. econstructor 4; try eapply star2_refl; eauto.
      stuck. stuck.
  - assert (b=true). destruct a0, b; isabsurd; eauto. subst.
    edestruct H1 as [? [? [GetL GetL']]]; eauto using zip_get.
    remember (omap (exp_eval V) Y). symmetry in Heqo.
    destruct o.
    + destruct x as [Z1 s1 n1], x0 as [Z2 s2 n2].
      edestruct H0 as [[? ?] SIM]; eauto; dcr.
      edestruct SIM as [[? ?] SIM']; eauto using zip_get.
      hnf; simpl. split; eauto using zip_get.
      instantiate (1:=LabI (countTrue (fst ⊝ take (labN l) (pair ⊜ RL ZL)))).
      reflexivity. simpl. eauto.
      eapply SIM'; eauto using zip_get.
      hnf; simpl. split; eauto using zip_get with len.
    + pfold; econstructor 4; try eapply star2_refl; eauto; stuck2.
  - pno_step.
  - remember (omap (exp_eval V) Y). symmetry in Heqo.
    destruct o.
    + pextern_step; eauto using agree_on_update_same, agree_on_incl; try congruence.
    + pno_step.
  - cases.
    + eapply sim'_expansion_closed;
        [| eapply star2_silent; [ econstructor; eauto | eapply star2_refl ]
         | eapply star2_refl ].
      rewrite <- zip_app; eauto with len.
      eapply IH; eauto.
      * rewrite zip_app; eauto with len.
        eapply simILabenv_extension with (F':=nil); eauto. eauto with len.
        intros; isabsurd. isabsurd.
        simpl; intros; dcr; subst. exfalso.
        rewrite get_app_lt in H8; eauto with len. inv_get.
        assert (length (compileF compile (pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ pair ⊜ RL ZL) F als)
                <> 0). {
          rewrite compileF_length; eauto.
          eapply countTrue_exists. rewrite <- EQ1; eauto using map_get_1.
        }
        eapply H6. rewrite <- Heq. eauto.
        simpl; intros; dcr; subst.
        rewrite get_app_ge in H8; eauto with len. inv_get.
        rewrite map_take. rewrite map_app.
        rewrite map_zip.
        rewrite zip_map_fst; eauto with len.
        rewrite take_app_ge. rewrite countTrue_app. omega.
        rewrite map_length. omega.
        rewrite zip_length2; eauto with len.
        rewrite map_length. omega.
        simpl. rewrite <- getAnn_eq; eauto. erewrite <- compileF_length; eauto.
        erewrite <- Heq. eauto.
      * intros. rewrite zip_app in H2; eauto with len.
        eapply get_app_cases in H2. destruct H2.
        exfalso. inv_get.
        assert (length (compileF compile (pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ pair ⊜ RL ZL) F als)
                <> 0). {
          rewrite compileF_length; eauto.
          eapply countTrue_exists. rewrite <- EQ1; eauto using map_get_1.
        }
        eapply H6. rewrite <- Heq. eauto.
        dcr. exploit H1; eauto. destruct H2 as [? [? ?]]; dcr.
        do 2 eexists. split.
        eapply get_app_right; eauto. rewrite mapi_length, zip_length2; eauto with len.
        rewrite map_length. rewrite zip_length2 in H6; eauto with len.
        rewrite map_length in H6. omega.
        rewrite zip_app; eauto with len.
        rewrite take_app_ge; eauto. rewrite map_app.
        rewrite <- getAnn_eq; eauto. rewrite countTrue_app.
        erewrite <- compileF_length; eauto. erewrite <- Heq. eauto.
    + rewrite Heq; clear Heq.
      pone_step. left. rewrite <- zip_app; eauto with len.
      eapply IH; eauto.
      {
        + rewrite zip_app; eauto with len.
          eapply simILabenv_extension; eauto. eauto with len.
          * intros. hnf; intros.
            hnf in H3. dcr. hnf in H10; dcr; subst.
            rewrite get_app_lt in H14; eauto using get_range.
            inv_get.
            exploit (compileF_get ((pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ pair ⊜ RL ZL) )).
            eapply H6. eauto. eauto.
            erewrite <- getAnn_take_eq in H7; eauto.
            simpl in *. get_functional.
            rewrite <- zip_app; eauto with len.
            eapply IH; eauto. rewrite EQ; eauto.
            exploit H9; eauto.
            rewrite zip_app; eauto with len.
            intros.
            eapply inv_extend; eauto with len.
          * hnf; intros.
            hnf in H2. dcr; subst.
            rewrite get_app_lt in H12; eauto with len.
            inv_get. simpl; unfold ParamRel; simpl.
            exploit (compileF_get ((pair ⊜ (getAnn ⊝ als) (fst ⊝ F) ++ pair ⊜ RL ZL) )).
            eapply H3. eauto. eauto.
            erewrite <- getAnn_take_eq in H6; eauto.
            get_functional. eauto.
          * intros. rewrite compileF_length; eauto.
            hnf in H2; dcr; subst.
            rewrite get_app_lt in H8;
              [| rewrite zip_length2; eauto with len; rewrite map_length; omega].
            inv_get.
            erewrite <- getAnn_take_eq; eauto.
            rewrite map_take.
            erewrite (take_eta n (getAnn ⊝ als)) at 2.
            rewrite countTrue_app.
            erewrite <- get_eq_drop; eauto using map_get_1.
            rewrite EQ1. simpl; omega.
          * intros. rewrite compileF_length; eauto.
            hnf in H2; dcr; subst.
            rewrite map_take. rewrite map_app.
            rewrite map_zip.
            rewrite zip_map_fst; eauto with len.
            rewrite take_app_ge. rewrite countTrue_app. omega.
            rewrite map_length. omega.
          * simpl. rewrite compileF_length; eauto.
            rewrite map_zip.
            rewrite zip_map_fst; eauto with len.
      }
      rewrite zip_app; eauto with len. intros; eapply inv_extend; eauto.
Qed.

Lemma sim_DCE i V s a
  : unreachable_code i nil nil s a
    -> getAnn a
    -> @sim I.state _ I.state _ Bisim (nil,V, s) (nil,V, compile nil s a).
Proof.
  intros. eapply sim'_sim.
  eapply (@sim_I i nil nil); eauto; isabsurd.
  econstructor; simpl; eauto using @sawtooth; isabsurd.
Qed.

End I.

Fixpoint compile_live (s:stmt) (a:ann (set var)) (b:ann bool) : ann (set var) :=
  match s, a, b with
    | stmtLet x e s, ann1 lv an, ann1 _ bn =>
      ann1 lv (compile_live s an bn)
    | stmtIf e s t, ann2 lv ans ant, ann2 _ bns bnt =>
      if [exp2bool e = Some true] then
        compile_live s ans bns
      else if [exp2bool e = Some false ] then
        compile_live t ant bnt
      else
        ann2 lv (compile_live s ans bns) (compile_live t ant bnt)
    | stmtApp f Y, ann0 lv, _ => ann0 lv
    | stmtReturn x, ann0 lv, _ => ann0 lv
    | stmtExtern x f Y s, ann1 lv an, ann1 _ bn  =>
      ann1 lv (compile_live s an bn)
    | stmtFun F t, annF lv anF ant, annF _ bnF bnt =>
      let anF'' := zip (fun (Zs:params * stmt) ab =>
                         compile_live (snd Zs) (fst ab) (snd ab)) F (pair ⊜ anF bnF) in
      let anF' := filter_by (fun b => b) (getAnn ⊝ bnF) anF'' in
      match anF' with
      | nil => (compile_live t ant bnt)
      | _ => annF lv anF' (compile_live t ant bnt)
      end
    | _, a, _ => a
  end.


Require Import TrueLiveness.

Lemma compile_live_incl i uci ZL LV RL s lv uc
  : true_live_sound i ZL LV s lv
    -> unreachable_code uci ZL RL s uc
    -> getAnn (compile_live s lv uc) ⊆ getAnn lv.
Proof.
  intros LS UC.
  general induction LS; inv UC; simpl; eauto.
  - repeat cases; simpl; eauto.
    + rewrite H0; eauto.
    + rewrite H2; eauto.
  - cases.
    + rewrite IHLS; eauto.
    + rewrite Heq. simpl; eauto.
Qed.

Lemma DCE_live uci i ZL LV RL s uc lv
  : unreachable_code uci ZL RL s uc
    -> getAnn uc
    -> true_live_sound i ZL LV s lv
    -> true_live_sound i (filter_by (fun b => b) RL ZL)
                      (filter_by (fun b => b) RL LV)
                      (compile (zip pair RL ZL) s uc)
                      (compile_live s lv uc).
Proof.
  intros UC Ann LS.
  general induction LS; inv UC; simpl; eauto using true_live_sound.
  - econstructor; eauto using compile_live_incl with cset.
    intros. eapply H. eapply compile_live_incl; eauto.
  - repeat cases; eauto. econstructor; eauto; intros.
    + rewrite compile_live_incl; eauto.
    + rewrite compile_live_incl; eauto.
  - repeat get_functional. simpl in *.
    assert (❬take (labN l) RL❭ = ❬take (labN l) ZL❭).
    eapply get_range in H. eapply get_range in H7.
    repeat rewrite take_length_le; eauto. omega. omega.
    econstructor; eauto.
    rewrite take_zip. rewrite fst_zip_pair; eauto.
    exploit (get_filter_by (fun b => b) H7 H); eauto.
    destruct a, b; isabsurd; eauto.
    simpl. rewrite map_id in H5. eauto.
    rewrite take_zip. rewrite fst_zip_pair; eauto.
    exploit (get_filter_by (fun b => b) H7 H0); eauto.
    destruct a, b; isabsurd; eauto.
    simpl. rewrite map_id in H5. eauto.
  - econstructor; eauto.
    rewrite compile_live_incl; eauto.
  - cases. rewrite <- zip_app; eauto with len.
    + exploit IHLS; eauto.
      assert (forall (n : nat) (b : bool), get (getAnn ⊝ als0) n b -> b = false).
      intros; inv_get; eauto using compileF_nil_als_false.
      rewrite !filter_by_app in H4; eauto with len.
      rewrite filter_by_nil in H4; eauto.
      setoid_rewrite filter_by_nil in H4 at 3; eauto.
      setoid_rewrite filter_by_nil at 3; eauto.
    + rewrite Heq. exploit compileF_not_nil_exists_true; eauto.
      rewrite <- Heq; congruence. clear Heq; dcr.
      rewrite <- zip_app; eauto with len.
      cases. exfalso. refine (filter_by_not_nil _ _ _ _ _ (eq_sym Heq));
                        eauto 20 using Is_true_eq_true with len.
      rewrite Heq; clear Heq.
      econstructor; eauto.
      rewrite compileF_Z_filter_by; eauto with len.
      rewrite map_filter_by. rewrite <- !filter_by_app; eauto 20 with len.
      eapply true_live_sound_monotone.
      eapply IHLS; eauto 20 with len.
      rewrite !filter_by_app; eauto 20 with len. eapply PIR2_app; [ | reflexivity ].
      eapply PIR2_get; intros; inv_get.

      simpl.
      eapply compile_live_incl; eauto.
      repeat rewrite filter_by_length; eauto 20 with len.
      rewrite compileF_length; eauto. rewrite filter_by_length, map_id; eauto 20 with len.
      intros; inv_get.
      destruct Zs as [Z s].
      edestruct compileF_get_inv; eauto; dcr; subst. simpl.
      rewrite compileF_Z_filter_by; eauto with len.
      inv_get. rewrite <- filter_by_app; eauto with len.
      eapply true_live_sound_monotone.
      eapply H1; eauto 20 with len.
      rewrite !filter_by_app; eauto 20 with len. eapply PIR2_app; [ | reflexivity ].
      eapply PIR2_get; intros; inv_get. simpl.
      eapply compile_live_incl; eauto.
      rewrite map_length.
      repeat rewrite filter_by_length; eauto 20 with len.
      intros. inv_get.
      destruct Zs as [Z s].
      edestruct compileF_get_inv; eauto; dcr; subst. simpl.
      inv_get. cases; eauto.
      rewrite compile_live_incl; eauto.
      rewrite compile_live_incl; eauto.
Qed.