Require Import AllInRel Util Map Env EnvTy Exp IL Bisim DecSolve MoreList InRel Sublist.

Set Implicit Arguments.
Unset Printing Records.

(** Pull all definitions to the top.
    [D] at index f holds the new index of function f
    n is the number of pulled-up defintions so far (n >= length D),
    not neccessarily equal
    yields the transformed statement and the global definitions
*)

Definition egalize_funs (egalize:list nat -> nat -> stmt -> stmt * list (params * stmt))
           (D':list nat) (n:nat) (F:list (params * stmt)) :=
  fold_right (fun f nF' =>
                       let '(n, F1, F2) := nF' in
                       let (s, F'') := egalize D' n (snd f) in
                       let n' := n + length F'' in
                       (n', (fst f, s)::F1, F2 ++ F'')) (n, nil, nil) F.

Definition extend n (F:list (params * stmt)) D := mapi (fun i _ => i+n) F ++ D.

Fixpoint egalize (D:list nat) (n:nat) (s:stmt) : stmt * list (params * stmt) :=
  match s with
    | stmtLet x e s =>
      let (s', F) := egalize D n s in
      (stmtLet x e s', F)
    | stmtExtern x f Y s =>
      let (s', F) := egalize D n s in
      (stmtExtern x f Y s', F)
    | stmtIf x s1 s2 =>
      let (s1', F1) := egalize D n s1 in
      let (s2', F2) := egalize D (n + length F1) s2 in
      (stmtIf x s1' s2', F1 ++ F2)
    | stmtApp l Y => (stmtApp (LabI (nth (counted l) D 0)) Y, nil)
    | stmtReturn x => (stmtReturn x, nil)
    | stmtFun F s =>
      (* entries for definitions in F: they are put to the bottom of the stack *)
      let D' := extend n F D in
      let '(n', F1, F2) := egalize_funs egalize D' (length F + n) F in
      let (s', F'') := egalize D' n' s in
      (s', F1 ++ F2 ++ F'')
  end.

(*
Lemma foo L
 :
  (forall f b, get L f b -> f > block_n b)
-> (forall f n b b', get L f b -> get L (f - block_n b + n) b' -> n > block_n b').
Proof.
  intros.
  eapply H in H0. eapply H in H1. simpl in *.
Qed.
*)
(*
Lemma inRel_resetting {A} {B} `{BlockType B} {C} `{BlockType C} R
      (AL:list A) (L:list B) (L':list C)
: inRel R AL L L' -> n_resetting L.
Proof.
  intros. unfold n_resetting.
  general induction H1. inv H2; eauto.
  eapply get_app_cases in H3; destruct H3; dcr;
  eapply get_app_cases in H4; destruct H4; dcr.
  - erewrite mutual_block_zero; eauto.
    erewrite mutual_block_zero; eauto. omega.
  - exploit (eapply (mutual_block_zero H2); eauto).
    exploit (eapply (inRel_less H1 H5)). omega.
  - exploit (eapply (inRel_less H1 H5)).
    exploit (eapply (get_length H3)). omega.
  - eapply IHinRel.  eapply H5.
    exploit (eapply (inRel_less H1 H5)).
    orewrite (f - length L1' - block_n b + n = f - block_n b + n - length L1'); eauto.
Qed.
*)
(*
Definition n_smaller' n L :=
        forall f b, get L f b -> (f+n) >= I.block_n b.

Definition n_resetting' m {B} `{BlockType B} (L:list B) :=
  (forall f n b b', get L f b -> get L (f - block_n b + n) b' -> (n+m) >= block_n b').



Lemma sawtooth_invariant L F n
  : n_smaller' n L -> n_resetting' n L
    -> n_smaller' n (mapi_impl I.mkBlock n F ++ L).
Proof.
  general induction F; simpl; eauto.
  exploit (eapply (IHF L (S n))); eauto.
  - hnf; intros. specialize (H _ _ H1). omega.
  - hnf; intros. specialize (H0 _ _ _ _ H1 H2). omega.
  - hnf; intros. inv H1. simpl; omega.
    specialize (X _ _ H6). omega.
Qed.
*)
(*
Definition sawtooth B `{BlockType B} (L:list B) :=
  forall f b b', get L f b -> get L (S f) b' -> S (block_n b) = block_n b' \/ block_n b' = 0.

Definition sawtooth_n B `{BlockType B} n (L:list B)
 := sawtooth L /\ forall b, get L 0 b -> block_n b = n.


Lemma sawtooth_I_mkBlock' L F n
  : sawtooth_n 0 L
    -> sawtooth (mapi_impl I.mkBlock n F ++ L).
Proof.
  unfold sawtooth_n.
  general induction F; simpl in * |- *; eauto. eapply H; eauto.
  hnf; intros. inv H0; inv H1. simpl.
  destruct F; simpl in *. right. eapply H; eauto.
  left. inv H6. simpl. reflexivity.
  eapply IHF; eauto.
Qed.


Lemma sawtooth_I_mkBlock L F
  : sawtooth_n 0 L
    -> sawtooth_n 0 (mapi_impl I.mkBlock 0 F ++ L).
Proof.
  split; eauto using sawtooth_I_mkBlock'.
  intros. destruct F; simpl in *.
  - eapply H; eauto.
  - inv H0; eauto.
Qed.

Definition index_larger {B} `{BlockType B} n (L:list B) :=
        forall f b, get L f b -> f + n >= block_n b.

Definition reset_larger {B} `{BlockType B} (L:list B) :=
  (forall f n b b', get L f b -> get L (f - block_n b + n) b' -> n >= block_n b').

Lemma sawtooth_n_tl {B} `{BlockType B} (L:list B) b n
  : sawtooth_n n (b::L) -> sawtooth_n (S n) L \/ sawtooth_n 0 L.
Proof.
  unfold sawtooth_n; intros.
  destruct L.
  - right; split; isabsurd.
  - destruct_prop (block_n b0 = 0).
    + right; split.
      * hnf; intros. eapply H0; eauto using get.
      * intros. inv H1. eauto.
    + left; split.
      * hnf; intros. eapply H0; eauto using get.
      * hnf; intros. inv H1. dcr.
        exploit (eapply H3; eauto using get).
        edestruct H2; eauto using get; omega.
Qed.

Lemma sawtooth_index_larger {B} `{BlockType B} n L
: sawtooth_n n L -> index_larger n L.
Proof.
  general induction L. isabsurd.
  edestruct H0.
  hnf; intros. inv H3.
  erewrite H2; eauto.
  edestruct sawtooth_n_tl; eauto.
  orewrite (S n0 + n = n0 + S n). eapply IHL; eauto.
  exploit (eapply (IHL _ _ H4); eauto). specialize (X _ _ H8). omega.
Qed.

Definition reset_larger' {B} `{BlockType B} n' (L:list B) :=
  (forall f n b b', get L f b -> get L (f - block_n b + n) b' -> n + n' >= block_n b').


Lemma sawtooth_reset_larger {B} `{BlockType B} L
: sawtooth_n 0 L -> reset_larger L.
Proof.
  intros; hnf; intros.
  general induction n.
  - simpl in *. admit.
  - inv H1. simpl in *.
    pose proof (sawtooth_index_larger H0 H2); eauto. omega.
Admitted.

Lemma sawtooth_drop {B} `{BlockType B} L f n b
: sawtooth_n n L
  -> get L f b
  -> sawtooth_n n (drop (f - block_n b) L).
Proof.
  intros.
  hnf; intros. split.
  hnf; intros. eapply get_drop in H2. eapply get_drop in H3.
  eapply H0; eauto. orewrite (S (f - block_n b + f0) = f - block_n b + S f0); eauto.
  intros. hnf in H0. eapply get_drop in H2.
Admitted.
*)


Lemma egalize_funs_length1 f D n F
      : length (snd (fst (egalize_funs f D n F))) = length F.
Proof.
  induction F; intros; simpl; eauto.
  erewrite <- IHF. unfold egalize_funs.
  repeat let_pair_case_eq; subst; simpl.
  repeat let_pair_case_eq; subst; simpl. repeat f_equal; try omega.
Qed.

Lemma egalize_funs_length2 f D n F
      : length (snd (egalize_funs f  D n F)) + n = fst (fst (egalize_funs f  D n F)).
Proof.
  revert n. induction F; intros; simpl; eauto.
  repeat let_pair_case_eq; subst; simpl.
  rewrite app_length. rewrite <- IHF. omega.
Qed.

Lemma egalize_funs_get F f Zb sb n D s p
: get F f (Zb, sb)
-> get (snd (fst (egalize_funs egalize D n F))) f (p, s)
-> let nF := egalize_funs egalize D n (drop (f+1) F) in
    fst (egalize D (fst (fst nF)) sb) = s /\ p = Zb.
Proof.
  intros.
  general induction F. inv H. simpl in *. subst nF. inv H.
  simpl in *.
  repeat let_case_eq. subst. simpl in *. inv H0. rewrite eq1; eauto.
  inv H. simpl. eapply IHF; eauto.
  repeat let_case_eq; subst; simpl in *; eauto.
  inv H0; eauto.
Qed.

Lemma mapi_app X Y (f:nat -> X -> Y) n L L'
: mapi_impl f n (L++L') = mapi_impl f n L ++ mapi_impl f (n+length L) L'.
Proof.
  general induction L; simpl; eauto.
  - orewrite (n + 0 = n); eauto.
  - f_equal. rewrite IHL. f_equal; f_equal. omega.
Qed.

Lemma drop_app_eq X (L L' : list X) n
: length L = n
  -> drop n (L ++ L') = L'.
Proof.
  intros; subst. orewrite (length L = length L + 0) . eapply drop_app.
Qed.

Lemma egalize_funs_get2 D F L' f Zb sb n'
  : get F f (Zb, sb)
    -> exists L'',
      let h := egalize_funs egalize D n' in
      drop (length (snd (h (drop (f + 1) F))))
           (mapi_impl I.mkBlock n' (snd (h F))
                      ++ L') =
      mapi_impl I.mkBlock (length (snd (h (drop (f + 1) F))) + n')
                (snd (egalize D
                              (length (snd (h (drop (f + 1) F))) + n') sb)) ++
                L''.
Proof.
  intros. general induction f. inv H.
  - simpl in *.
    repeat let_pair_case_eq; subst; simpl.
    rewrite <- egalize_funs_length2.
    rewrite mapi_app.
    simpl in *.
    rewrite <- app_assoc.
    erewrite (drop_app_eq). eexists. rewrite Plus.plus_comm. reflexivity.
    rewrite mapi_length; eauto.
  - inv H; simpl in *.
    repeat let_pair_case_eq; subst; simpl.
    edestruct (IHf D) with (n':=n'); eauto.
    eexists. rewrite mapi_app. rewrite <- app_assoc.
    eapply H0.
Qed.


Inductive approx (L':list I.block)
  : list nat ->  nat -> I.block -> I.block -> Prop :=
  Approx Z s n m s' F D f L''
  : egalize D m s = (s', F)
    -> drop m L' = mapi_impl I.mkBlock m F ++ L''
    -> approx L' D f (I.blockI Z s n) (I.blockI Z s' f).

Inductive renestSim : I.state -> I.state -> Prop :=
  RenestSim (E:onv val) (L:list I.block) L' L'' s n D
  (SL:forall f b, get L f b -> exists b', get L' (nth f D 0) b' /\ approx L' (drop (f-block_n b) D) (nth f D 0) b b')
  (ST:sawtooth L)
  (DP:drop n L' = mapi_impl I.mkBlock n (snd (egalize D n s)) ++ L'')
  : renestSim (L, E, s) (L', E, (fst (egalize D n s))).


Lemma app_drop X (L L' L'':list X)
 : L = L' ++ L''
   -> drop (length L') L = L''.
Proof.
  general induction L'; simpl; eauto.
Qed.

Instance PR : ProofRelationI (params) :=
  {
    ParamRelI G Z Z' := Z = Z' /\ Z = G;
    ArgRelI G VL VL' := VL = VL' /\ length VL = length G;
    BlockRelI := fun Z b b' => length (I.block_Z b) = length Z
                           /\ length (I.block_Z b') = length Z
  }.
intros. dcr; repeat subst. eauto.
Defined.

Instance bisim_progeq {S} `{StateType S} : ProgramEquivalence S S.
constructor. eapply (paco2 (@bisim_gen S _ S _)).
Defined.

Ltac pone_step := pfold; eapply bisim'Silent; [ eapply plus2O; single_step
                              | eapply plus2O; single_step
                              | ].

Lemma nth_drop X (L:list X) n m x
: nth n (drop m L) x = nth (n+m) L x.
Proof.
  general induction m; simpl. orewrite (n + 0 = n); eauto.
  rewrite IHm; eauto. orewrite (n + S m = S (n + m)); eauto.
  destruct L; simpl; eauto. destruct (n + m); eauto.
Qed.

Lemma renestSim_sim r L L' E s n D L''
      (SL:forall (f : nat) (b : I.block),
          get L f b ->
          exists b' : I.block,
            get L' (nth f D 0) b' /\
            approx L' (drop (f - block_n b) D) (nth f D 0) b b')
      (ST:sawtooth L)
      (DROP:drop n L' = mapi_impl I.mkBlock n (snd (egalize D n s)) ++ L'')
  : bisim'r r (L, E, s) (L', E, fst (egalize D n s)).
Proof.
  revert_all. pcofix CIH.
  intros. destruct s; simpl in *;
            repeat let_case_eq; repeat simpl_pair_eqs; subst; simpl in *.
  - case_eq (exp_eval E e); intros.
    + pone_step. right. eapply CIH; eauto.
    + pno_step.
  - case_eq (exp_eval E e); [ intros | intros; pno_step ].
    rewrite mapi_app in DROP. rewrite <- app_assoc in DROP.
    case_eq (val2bool v); intros.
    + pone_step. right. eapply CIH; eauto.
    + pone_step. right. eapply CIH; eauto.
      eapply app_drop in DROP. rewrite mapi_length in DROP.
      rewrite drop_drop in DROP. rewrite plus_comm.
      rewrite DROP. rewrite plus_comm. eauto.
  - destruct (get_dec L (counted l)) as [[? ?]|].
    + edestruct SL; eauto; dcr; eauto. invt approx. destruct l as [f]; simpl in *.
      repeat let_case_eq; repeat let_pair_case_eq; simpl in * |- *; subst.
      decide (length Z = length Y); [| pno_step; get_functional; simpl in *; eauto].
      case_eq (omap (exp_eval E) Y); [ intros | intros; pno_step; eauto ].
      pone_step. right. simpl. eapply CIH.
      *  orewrite (nth f D 0 - nth f D 0 = 0); simpl; intros ? ? GET.
         repeat rewrite drop_drop. rewrite nth_drop.
         eapply get_drop in GET. edestruct (SL _ _ GET); dcr.
         rewrite plus_comm. eexists; split; eauto.
         rewrite plus_comm; eauto.
         pose proof (sawtooth_resetting ST _ g GET).
         simpl in *.
         orewrite (f - n0 + (f0 - I.block_n b) = f - n0 + f0 - I.block_n b).
         eauto.
      * eapply (sawtooth_drop ST g).
      * orewrite (nth f D 0 - nth f D 0 = 0). simpl.
        eauto.
    + pno_step; eauto.
      admit.
  - pno_step.
  - case_eq (omap (exp_eval E) Y); [intros | intros; pno_step ].
    pextern_step.
    + eexists; split. econstructor; eauto.
      right. eapply CIH; eauto.
    + eexists; split. econstructor; eauto.
      right. eapply CIH; eauto.
  - eapply bisim'_expansion_closed;
      [ | eapply (S_star2 EvtTau); [ econstructor | eapply star2_refl ]
        | eapply star2_refl].
    eapply CIH.
    unfold I.mkBlocks in A. eapply mapi_get in A. destruct A; dcr.
    destruct x as [Zb sb]. unfold I.mkBlock in H10; simpl in H10.
    subst b1. simpl. orewrite (f - f = 0). simpl.
    exploit (eapply get_length; eauto).
    unfold extend at 1. unfold extend at 2.
    rewrite app_nth1; eauto.
    repeat rewrite nth_mapi; eauto. subst. simpl in *.
    edestruct get_in_range. Focus 2.
    eexists. split. rewrite Plus.plus_comm. eapply get_drop.
    rewrite DP. rewrite mapi_app. repeat eapply get_app. eapply g.
    exploit (eapply mapi_get_impl; eauto using get_getT). destruct X0 as [? [? ?]].
    subst. eapply getT_get in g0. unfold I.mkBlock. destruct x0. simpl.
    edestruct egalize_funs_get; try eapply H8; try eapply g0. subst p.

    repeat rewrite mapi_app in DP.
    repeat rewrite <- app_assoc in DP.
    eapply app_drop in DP.
    repeat rewrite mapi_length in DP.
    rewrite drop_drop in DP.
    rewrite egalize_funs_length1 in DP.
    rewrite <- Plus.plus_assoc in DP. rewrite Plus.plus_comm in DP.

    intros.
    intros. edestruct (@egalize_funs_get2 (extend n F D) F) with (n':= n + length F). eassumption.
    eapply Approx.
    subst. eapply surjective_pairing.
    rewrite <- egalize_funs_length2.
    rewrite <- drop_drop. rewrite Plus.plus_comm. rewrite DP.
    simpl in *.
    eapply H3.

    rewrite mapi_length. rewrite egalize_funs_length1; eauto.
    unfold mapi. rewrite mapi_length; eauto.
  - edestruct (SL _ _ H8); dcr. unfold extend.
    repeat rewrite app_nth2; eauto.
    unfold mapi. rewrite mapi_length. eexists x.
    split.
    unfold I.mkBlocks in *. unfold mapi in *. rewrite mapi_length in *. eauto.
    unfold I.mkBlocks in *. unfold mapi in *. rewrite mapi_length in *.
    pose proof (sawtooth_smaller ST H8). rewrite drop_length_ge. rewrite mapi_length.
    orewrite (f - length F - I.block_n b1 = f - I.block_n b1 - length F) in H15. eauto.
    rewrite mapi_length. simpl in *. omega.
    unfold mapi. rewrite mapi_length. simpl in *.
    unfold I.mkBlocks in *. unfold mapi in *. rewrite mapi_length in *. eauto.
  - eapply sawtooth_I_mkBlocks; eauto.
  - subst. simpl in * |- *.
    rewrite <- egalize_funs_length2 at 1. simpl.
    repeat rewrite mapi_app in DP. repeat rewrite <- app_assoc in DP. simpl in *.
    eapply app_drop with (L:=drop n L') in DP. repeat rewrite mapi_length in DP. simpl in *.
    rewrite egalize_funs_length1 in DP.
    eapply app_drop in DP. repeat rewrite mapi_length in DP. simpl in *.
    repeat rewrite drop_drop in DP. simpl. rewrite Plus.plus_assoc.
    rewrite DP. simpl.
    rewrite <- egalize_funs_length2. f_equal. f_equal. omega.
Qed.



(*
*** Local Variables: ***
*** coq-load-path: (("." "Lvc")) ***
*** End: ***
*)