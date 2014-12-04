Require Import List Arith.
Require Import IL Annotation AutoIndTac Bisim Exp MoreExp Coherence Fresh Util.
Require Import SetOperations Sim Var.
Require Import sexp smt nofun noGoto Terminates bitvec Crash freeVars.
Require Import tvalTactics TUtil.

 Lemma guard_true_if_eval:
forall F E e s v,
 exp_eval E e = Some v
->  undef e = Some s
->  models F E s.

Proof.
intros. general induction e; simpl.
- simpl in *. monad_inv H. destruct u.
  + apply (IHe F E s x); eauto.
  +  apply (IHe F E s x); eauto.
- simpl in H.  monad_inv H.  simpl in H0. destruct b.
  +  case_eq (undef e1); case_eq (undef e2); intros.
     *  rewrite H in H0; rewrite H1 in H0. simpl in H0.
        inversion H0. simpl; split.
        { eapply IHe1; eauto. }
        { eapply IHe2; eauto. }
     * rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0; simpl.
       eapply IHe1; eauto. rewrite <- H0; eauto.
     * rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0; simpl.
       eapply IHe2; eauto. rewrite <- H0; eauto.
     * rewrite H in H0; rewrite H1 in H0; simpl in H0;  simpl.
       exfalso; discriminate H0.
  + destruct b.
    *  case_eq (undef e1); case_eq (undef e2); intros.
     {  rewrite H in H0; rewrite H1 in H0. simpl in H0. inversion H0.
        simpl; split.
        - eapply IHe1; eauto.
        - eapply IHe2; eauto. }
     { rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0; simpl.
       eapply IHe1; eauto. rewrite <- H0; eauto. }
     { rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0; simpl.
       eapply IHe2; eauto. rewrite <- H0; eauto. }
     { rewrite H in H0; rewrite H1 in H0; simpl in H0;  simpl.
       exfalso; discriminate H0. }
    * destruct b.
      { case_eq (undef e1); case_eq (undef e2); intros.
        -  rewrite H in H0; rewrite H1 in H0. simpl in H0. inversion H0.
simpl; split.
           + eapply IHe1; eauto.
           + eapply IHe2; eauto.
        - rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0; simpl.
          eapply IHe1; eauto. rewrite <- H0; eauto.
        - rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0; simpl.
          eapply IHe2; eauto. rewrite <- H0; eauto.
        - rewrite H in H0; rewrite H1 in H0; simpl in H0;  simpl.
          exfalso; discriminate H0. }
      { destruct b.
        -  case_eq (undef e1); case_eq (undef e2); intros.
           +  rewrite H in H0; rewrite H1 in H0. simpl in H0. inversion H0.
              simpl; split.
              * eapply IHe1; eauto.
              * eapply IHe2; eauto.
           + rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0.
             simpl. eapply IHe1; eauto. rewrite <- H0; eauto.
           + rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0.
             simpl. eapply IHe2; eauto. rewrite <- H0; eauto.
            +rewrite H in H0; rewrite H1 in H0; simpl in H0;  simpl.
             exfalso; discriminate H0.
        - destruct b.
          +  case_eq (undef e1); case_eq (undef e2); intros.
             *  rewrite H in H0; rewrite H1 in H0. simpl in H0. inversion H0.
                simpl; split.
                { eapply IHe1; eauto. }
                { eapply IHe2; eauto. }
             * rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0.
               simpl. eapply IHe1; eauto. rewrite <- H0; eauto.
             *rewrite H in H0; rewrite H1 in H0; simpl in H0; inversion H0.
              simpl. eapply IHe2; eauto. rewrite <- H0; eauto.
             * rewrite H in H0; rewrite H1 in H0; simpl in H0;  simpl.
               exfalso; discriminate H0.
          + simpl in EQ2.
            * case_eq (undef e1); case_eq (undef e2); intros.
              {  rewrite H in H0; rewrite H1 in H0. simpl in H0. inversion H0.
                 unfold binop_eval in EQ2.  clear H0. unfold bvDiv in EQ2.
                 simpl. split.
                 - case_eq(bvZero x0).
                   + intros.  rewrite H0 in EQ2.  exfalso; discriminate EQ2.
                   + intros A.   unfold evalSexp. intros. clear H3. clear EQ2.
                     hnf in H0.  rewrite EQ1 in H0.  simpl in H0. simpl  in A.
                     eapply  (not_zero_implies_uneq _  A) in H0;  eauto.
                 - split.
                   + eapply IHe1; eauto.
                   + eapply IHe2; eauto.  }
                 { rewrite H in H0; rewrite H1 in H0; simpl in H0. inversion H0.
                   unfold binop_eval in EQ2. clear H0. unfold bvDiv in EQ2.
                   simpl. split.
                 - case_eq(bvZero x0).
                   + intros.  rewrite H0 in EQ2.  exfalso; discriminate EQ2.
                   + intros A.   unfold evalSexp. intros. clear H3. clear EQ2.
                     hnf in H0. rewrite EQ1 in H0.  simpl in H0. simpl  in A.
                     eapply ( not_zero_implies_uneq _) in H0; eauto.
                 -  eapply IHe1; eauto. }
                 { rewrite H in H0; rewrite H1 in H0; simpl in H0. inversion H0.
                   unfold binop_eval in EQ2. clear H0. unfold bvDiv in EQ2.
                   simpl. split.
                 - case_eq(bvZero x0).
                   + intros.  rewrite H0 in EQ2.  exfalso; discriminate EQ2.
                   + intros A.   unfold evalSexp. intros. clear H3. clear EQ2.
                     hnf in H0.  rewrite EQ1 in H0.  simpl in H0. simpl  in A.
                     eapply  (not_zero_implies_uneq _) in H0; eauto.
                 -  eapply IHe2; eauto. }
                 { rewrite H in H0; rewrite H1 in H0; simpl in H0. inversion H0.
                   unfold binop_eval in EQ2. clear H0.
                   unfold bvDiv in EQ2. simpl.
                   case_eq(bvZero x0).
                   - intros.  rewrite H0 in EQ2.  exfalso; discriminate EQ2.
                   - intros A.   unfold evalSexp. intros. clear H3. clear EQ2.
                     hnf in H0. rewrite EQ1 in H0.  simpl in H0. simpl  in A.
                     eapply  (not_zero_implies_uneq _ ) in H0; eauto. } }
(*                 * case_eq (undef e1); case_eq (undef e2); intros; simpl.
                   { rewrite H in H0; rewrite H1 in H0; simpl in H0.
                     inversion H0. simpl; split.
                     - eapply IHe1; eauto.
                     - eapply IHe2; eauto. }
                   { rewrite H in H0; rewrite H1 in H0; simpl in H0.
                     inversion H0. simpl.
                     - eapply IHe1; eauto. rewrite <- H3. assumption. }
                   { rewrite H in H0; rewrite H1 in H0; simpl in H0.
                     inversion H0. simpl.
                     - eapply IHe2; eauto. rewrite <- H3. assumption. }
                   {  rewrite H in H0; rewrite H1 in H0; simpl in H0.
                      inversion H0. } } *)
Qed.

Lemma guardList_true_if_eval:
forall F E el s vl,
omap (exp_eval E) el = Some vl
-> undefLift el = Some s
-> models F E s.

Proof.
intros. general induction el.
- simpl in *.  case_eq (undef a); intros.
  + rewrite H1 in H0. simpl in H0.  case_eq (undefLift el); intros; simpl.
    * rewrite H2 in H0. inversion H0. simpl. split.
      { monad_inv H. eapply (guard_true_if_eval); eauto. }
      { monad_inv H. eapply IHel; eauto. }
    * rewrite H2 in H0. inversion H0. monad_inv H.
      eapply (guard_true_if_eval); eauto.
  + rewrite H1 in H0; monad_inv H. eapply IHel; eauto.
Qed.

Lemma noguard_impl_eval:
forall E e,
(forall x, x ∈ Exp.freeVars e -> exists v,  E x = Some v)
-> undef e = None
-> exists v, exp_eval E e = Some v.

Proof.
  intros. general induction e.
  - exists v. unfold exp_eval. reflexivity.
  - destruct (H v); simpl; cset_tac; eauto.
  - simpl in H. specialize (IHe E H). simpl in H0.
     destruct IHe; eauto.
     simpl. rewrite H1. simpl. destruct u; simpl.
    + case_eq (val2bool x); intros.
      * exists val_true; unfold option_lift1; simpl.
          rewrite H2; eauto.
      * exists val_false; unfold option_lift1; simpl.
         rewrite H2; eauto.
      + exists (neg x); unfold option_lift1.
          destruct u; eauto.
  - specialize (IHe1 E); specialize (IHe2 E). simpl in H. cset_tac.
    assert (forall x, x ∈ Exp.freeVars e1 -> exists v, E x = Some v)
      by (cset_tac; eauto).
    assert (forall x, x ∈ Exp.freeVars e2 -> exists v, E x  = Some v)
      by (cset_tac; eauto).
    specialize (IHe1 H1); specialize (IHe2 H2).
    destructBin b; simpl in *.
    + eapply combine_keep_undef in H0. destruct H0.
      destruct IHe1; destruct IHe2; eauto.
      rewrite H4; rewrite H5. simpl. exists (bvAdd x x0).
      unfold option_lift2; eauto.
    + eapply combine_keep_undef in H0; destruct H0.
      destruct IHe1, IHe2; eauto.
      rewrite H4; rewrite H5; simpl; exists (bvSub x x0).
      unfold option_lift2; eauto.
    + eapply combine_keep_undef in H0; destruct H0.
      destruct IHe1, IHe2; eauto.
      rewrite H4, H5; simpl; exists (bvMult x x0).
      unfold option_lift2; eauto.
    + eapply combine_keep_undef in H0; destruct H0.
      destruct IHe1, IHe2; eauto.
      rewrite H4, H5; simpl; exists (bvEq x x0).
      unfold option_lift2; eauto.
    + eapply combine_keep_undef in H0; destruct H0.
      destruct IHe1, IHe2; eauto.
      rewrite H4, H5; simpl; exists (neg (bvEq x x0)).
      unfold option_lift2; eauto.
    + case_eq (undef e1); case_eq(undef e2); intros;
      rewrite H3 in *; rewrite H4 in *; discriminate H0.
(*    + eapply combine_keep_undef in H0; destruct H0.
      destruct IHe1; destruct IHe2; eauto.
      rewrite H4, H5; simpl. exists (bvAdd x x0).
      unfold option_lift2; eauto. *)
Qed.

Lemma noguardlist_impl_eval:
  forall E el,
    (forall x, x ∈ list_union (List.map Exp.freeVars el) -> exists v,  E x = Some v)
    -> undefLift el = None
    -> exists v, omap (exp_eval E) el = Some v.

Proof.
  intros.
  general induction el; simpl; eauto.
  - eapply (combine_keep_undef_list) in H0.
    destruct H0.
    case_eq (exp_eval E a); intros; simpl.
    + simpl in H0.  exploit (IHel E); eauto.
      Focus 2.  destruct X. rewrite H3. exists (v::x); eauto.
      intros; eapply H. unfold list_union; simpl.
      eapply list_union_start_swap. cset_tac.
      right; eauto.
    + pose proof (noguard_impl_eval E a).
      destruct H3; eauto; isabsurd.
      intros; eapply H. unfold list_union; simpl.
      eapply list_union_start_swap; cset_tac.
      left; right; eauto.
Qed.

Lemma guard_impl_eval:
forall F E e g,
 undef e = Some g
-> models F E g
-> (forall x, x ∈ Exp.freeVars e -> exists v, E x = Some v)
-> exists v, exp_eval E e = Some v.

Proof.
intros. general induction e; try isabsurd; simpl.
- destruct u; simpl in H.
  + destruct (IHe F E g H H0) as [v eval]; cset_tac; eauto.
    rewrite eval. simpl. unfold option_lift1.
    destruct(val2bool v); eauto.
 + destruct (IHe F E g H H0) as [v eval]; cset_tac; eauto.
   rewrite eval; simpl; unfold option_lift1.
   exists (neg v); eauto.
- destructBin b; simpl in *.
  + case_eq (undef e1); case_eq (undef e2); intros; simpl in *;
    rewrite H2, H3 in H; inversion H.
    * rewrite <- H5 in H0; simpl in H0.
      destruct H0.
      destruct (IHe1 F E s0 H3 H0); cset_tac; eauto.
      destruct (IHe2 F E s H2 H4); cset_tac; eauto.
      rewrite H6, H5; simpl. exists (bvAdd x x0); eauto.
    *  pose proof (noguard_impl_eval E e2).
       destruct H4; cset_tac; eauto.
       destruct (IHe1 F E g); cset_tac; eauto.
       rewrite H4, H5; simpl; unfold option_lift2.
       exists (bvAdd x0 x); eauto.
    * pose proof (noguard_impl_eval E e1).
      destruct H4; cset_tac; eauto.
      destruct (IHe2 F E g); cset_tac; eauto.
      rewrite H4, H5. simpl. exists (bvAdd x x0); eauto.
  + case_eq (undef e1); case_eq (undef e2); intros; simpl in *;
    rewrite H2, H3 in H; inversion H.
    * rewrite <- H5 in H0; simpl in H0.
      destruct H0.
      destruct (IHe1 F E s0 H3 H0); cset_tac; eauto.
      destruct (IHe2 F E s H2 H4); cset_tac; eauto.
      rewrite H6, H5; simpl. exists (bvSub x x0); eauto.
    *  pose proof (noguard_impl_eval E e2 ).
       destruct H4; cset_tac; eauto.
       destruct (IHe1 F E g); cset_tac; eauto.
       rewrite H4, H5; simpl; unfold option_lift2.
       exists (bvSub x0 x); eauto.
    * pose proof (noguard_impl_eval E e1).
      destruct H4; cset_tac; eauto.
      destruct (IHe2 F E g); cset_tac; eauto.
      rewrite H4, H5. simpl. exists (bvSub x x0); eauto.
  + case_eq (undef e1); case_eq (undef e2); intros; simpl in *;
    rewrite H2, H3 in H; inversion H.
    * rewrite <- H5 in H0; simpl in H0.
      destruct H0.
      destruct (IHe1 F E s0 H3 H0); cset_tac; eauto.
      destruct (IHe2 F E s H2 H4); cset_tac; eauto.
      rewrite H6, H5; simpl. exists (bvMult x x0); eauto.
    *  pose proof (noguard_impl_eval E e2 ).
       destruct H4; cset_tac; eauto.
       destruct (IHe1 F E g); cset_tac; eauto.
       rewrite H4, H5; simpl; unfold option_lift2.
       exists (bvMult x0 x); eauto.
    * pose proof (noguard_impl_eval E e1).
      destruct H4; cset_tac; eauto.
      destruct (IHe2 F E g); cset_tac; eauto.
      rewrite H4, H5. simpl. exists (bvMult x x0); eauto.
  + case_eq (undef e1); case_eq (undef e2); intros; simpl in *;
    rewrite H2, H3 in H; inversion H.
    * rewrite <- H5 in H0; simpl in H0.
      destruct H0.
      destruct (IHe1 F E s0 H3 H0); cset_tac; eauto.
      destruct (IHe2 F E s H2 H4); cset_tac; eauto.
      rewrite H6, H5; simpl. exists (bvEq x x0); eauto.
    *  pose proof (noguard_impl_eval E e2 ).
       destruct H4; cset_tac; eauto.
       destruct (IHe1 F E g); cset_tac; eauto.
       rewrite H4, H5; simpl; unfold option_lift2.
       exists (bvEq x0 x); eauto.
    * pose proof (noguard_impl_eval E e1).
      destruct H4; cset_tac; eauto.
      destruct (IHe2 F E g); cset_tac; eauto.
      rewrite H4, H5. simpl. exists (bvEq x x0); eauto.
  + case_eq (undef e1); case_eq (undef e2); intros; simpl in *;
    rewrite H2, H3 in H; inversion H.
    * rewrite <- H5 in H0; simpl in H0.
      destruct H0.
      destruct (IHe1 F E s0 H3 H0); cset_tac; eauto.
      destruct (IHe2 F E s H2 H4); cset_tac; eauto.
      rewrite H6, H5; simpl. exists (neg (bvEq x x0)); eauto.
    *  pose proof (noguard_impl_eval E e2).
       destruct H4; cset_tac; eauto.
       destruct (IHe1 F E g); cset_tac; eauto.
       rewrite H4, H5; simpl; unfold option_lift2.
       exists (neg (bvEq x0 x)); eauto.
    * pose proof (noguard_impl_eval E e1).
      destruct H4; cset_tac; eauto.
      destruct (IHe2 F E g); cset_tac; eauto.
      rewrite H4, H5. simpl. exists (neg (bvEq x x0)); eauto.
  + case_eq (undef e1); case_eq (undef e2); intros; simpl in *;
    rewrite H2, H3 in H; simpl in H; inversion H.
    rewrite <- H5 in H0.
    * destruct H0.  clear H5. clear H. simpl in H0. unfold evalSexp in H0; simpl in H0.
      destruct H4.
      destruct (IHe1 F E s0); cset_tac; eauto.
      destruct (IHe2  F E s); cset_tac; eauto.
      rewrite H5, H6; simpl.
      rewrite H6 in H0.
      clear H5. clear H6. clear H1.
      unfold bvDiv.
      case_eq (bvZero x0); intros.
      { eapply (zero_implies_eq x0) in H1. specialize (H0 H1); isabsurd.
        unfold zext. simpl; eauto. }
      { eauto. }
    * rewrite <- H5 in H0.  destruct H0.
      clear H5; clear H. simpl in H0. unfold evalSexp in H0; simpl in H0.
      pose proof (noguard_impl_eval E e2).
      destruct H; cset_tac; eauto.
      destruct (IHe1 F E s); eauto.
      rewrite H, H5; simpl.
      rewrite H in H0. clear H. clear H5. clear H1.
      unfold bvDiv. simpl.
      case_eq (bvZero x); intros.
      { eapply (zero_implies_eq x (b:=(zext k (O::nil)))) in H.
        simpl in H. specialize (H0 H); isabsurd.  f_equal; eauto. }
      { eauto. }
    * rewrite <- H5 in H0; destruct H0; clear H5; clear H.
      simpl in H0. unfold evalSexp in H0; simpl in H0.
      pose proof (noguard_impl_eval  E e1).
      destruct H; cset_tac; eauto.
      destruct (IHe2 F E s); eauto.
      rewrite H, H5; simpl.
      rewrite H5 in H0. clear H. clear H5. clear H1.
      unfold bvDiv.
      case_eq (bvZero x0); intros.
      { eapply (zero_implies_eq x0 (b:=(zext k (O::nil)))) in H.
        simpl in H. specialize (H0 H); isabsurd.  f_equal; eauto. }
      { eauto. }
    * rewrite <- H5 in H0. clear H5. simpl in H0.
      pose proof (noguard_impl_eval E e1).
      pose proof (noguard_impl_eval E e2).
      destruct H4; cset_tac;  eauto.
      destruct H5; cset_tac; eauto.
      rewrite H4, H5. simpl.
      unfold evalSexp in *; rewrite H5 in H0. simpl in H0.
      unfold bvDiv. case_eq (bvZero x0); intros; eauto.
      eapply (zero_implies_eq x0 (b:=zext k (O::nil))) in H6.
      specialize (H0 H6); isabsurd.
      f_equal; eauto.
Qed.

(*
*** Local Variables: ***
*** coq-load-path: (("../" "Lvc")) ***
*** End: ***
*)