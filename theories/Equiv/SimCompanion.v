Require Import Util Option AllInRel Get Setoid.
Require Export paco3 SmallStepRelations StateType Sim SimLockStep.
Require Import Tower3 Tower2.

Definition simc {S} `{StateType S} {S'} `{StateType S'} r t (σ1:S) (σ2:S')
  := companion3 (@sim_gen S _ S' _) r t σ1 σ2.

Theorem simc_sim {S} `{StateType S} {S'} `{StateType S'} r t (σ1:S) (σ2:S')
  : simc bot3 t σ1 σ2 -> sim r t σ1 σ2.
Proof.
  intros. revert t σ1 σ2 H1.
  pcofix CIH; intros.
  pfold. eapply companion3_unfold in H2.
  eapply sim_gen_mon; eauto.
Qed.


Theorem sim_simc {S} `{StateType S} {S'} `{StateType S'} r t (σ1:S) (σ2:S')
  : sim bot3 t σ1 σ2 -> simc r t σ1 σ2.
Proof.
  intros. revert t σ1 σ2 H1.
  unfold simc.
  eapply tower_ind3; intros.
  - hnf; intros; hnf; intros. eauto.
  - punfold H2.
    eapply sim_gen_mon; eauto; intros.
    destruct PR; isabsurd.
    eapply H1. eauto.
Qed.

Lemma simc_trans t {S1} `{StateType S1}
      (σ1:S1) {S2} `{StateType S2} (σ2:S2) {S3} `{StateType S3} (σ3:S3)
  : simc bot3 t σ1 σ2 -> simc bot3 t σ2 σ3 -> simc bot3 t σ1 σ3.
Proof.
  intros.
  eapply sim_simc.
  eapply sim_trans with (S2:=S2).
  eapply simc_sim; eauto.
  eapply simc_sim; eauto.
Qed.

Definition expc {S} `{StateType S} {S'} `{StateType S'}
           (r:(simtype -> S -> S' -> Prop)) : simtype -> S -> S' -> Prop :=
  fun t σ σ' => exists σ1 σ2, star2 step σ nil σ1 /\ star2 step σ' nil σ2 /\ r t σ1 σ2.

Lemma expc_upto {S} `{StateType S} {S'} `{StateType S'}
  : (forall r, @expc S _ S' _ (simc r) <3= simc r).
Proof.
  intros H1 H2.
  eapply upto3.
  - unfold expc; hnf; intros.
    destruct IN as [? [? [? [? ?]]]].
    do  2eexists; split; eauto.
  - unfold expc; intros.
    destruct PR as [? [? [? [? ?]]]].
    inv H6; zzsimpl; eauto 20.
Qed.


Lemma expc_simc {S} `{StateType S} {S'} `{StateType S'} (σ1 σ1':S) (σ2 σ2':S') t r
  : simc r t σ1'  σ2'
    -> star2 step σ1 nil σ1'
    -> star2 step σ2 nil σ2'
    -> simc r t σ1 σ2.
Proof.
  intros.
  eapply expc_upto; hnf; eauto 20.
Qed.


Definition redc {S} `{StateType S} {S'} `{StateType S'}
           (r:(simtype -> S -> S' -> Prop)) : simtype -> S -> S' -> Prop :=
  fun t σ σ2 => exists σ1, star2 step σ1 nil σ (* /\ star2 step σ2 nil σ'*) /\ r t σ1 σ2.

Lemma star2n_reach' X (R:X -> event -> X -> Prop) σ1 σ2a σ2b n n'
: star2n R n σ1 nil σ2a
  -> star2n R n' σ1 nil σ2b
  -> internally_deterministic R
  -> ((star2n R (n'-n) σ2a nil σ2b /\ n' > n) \/
     (star2n R (n-n') σ2b nil σ2a /\ n > n')
     \/ ( n' = n /\ σ2a = σ2b)).
Proof.
  intros Star1 Star2 IDet.
  general induction Star1; eauto.
  - orewrite (n' - 0 = n').
    inv Star2; eauto.
    left. rewrite H. split; eauto. omega.
  - relsimpl. invc Star2; relsimpl; simpl; eauto.
    + right. left. split. eapply (S_star2n _ _ H Star1). omega.
    + edestruct IHStar1 as [?|[?|?]]; eauto; dcr.
      * left. split; try omega. eauto.
      * right. left. split; try omega. eauto.
Qed.

Lemma star2n_plus {S} `{StateType S} (σ σ':S) n
  : star2n step n σ nil σ'
    -> n > 0
    -> plus2 step σ nil σ'.
Proof.
  intros. general induction H0.
  - omega.
  - destruct y, yl; isabsurd; simpl in *.
    destruct n.
    + inv H1. econstructor 1; eauto.
    + econstructor 2; eauto. eapply IHstar2n; eauto.
      omega.
Qed.

(*
Lemma sim_reduction_closed_1 t {S} `{StateType S}
      (σ1 σ1':S) {S'} `{StateType S'} (σ2:S') r
  : simc r t σ1 σ2
    -> star2 step σ1 nil σ1'
    -> simc r t σ1' σ2.
Proof.
  intros Sim Star.
  eapply star2_star2n in Star. destruct Star as[n StarN].
  revert dependent r. revert σ1 σ2 σ1' StarN.
  size induction n.

  inv Sim; zzsimpl.
    + invc StarN; eauto. zzsimpl.
      eapply star2_star2n in H4. dcr.
      edestruct (star2n_reach' H11 H7) as [?|[?|?]]; eauto; subst; dcr. eapply H.
      * econstructor 1. eapply star2n_plus; eauto. omega. eauto. eauto.
      * eapply H3; eauto. admit.
      * subst.

Lemma redc_upto {S} `{StateType S} {S'} `{StateType S'}
  : (forall r, @redc S _ S' _ (simc r) <3= simc r).
Proof.
  intros H1 H2.
  eapply upto.
  - unfold redc; hnf; intros.
    dcr.
    do  2eexists;  eauto.
  - unfold redc. intros r UH t σ1 σ2 PR.
    destruct PR as [σ1' [StarN Sim]].
    eapply star2_star2n in StarN. destruct StarN as[n StarN].
    revert dependent r. revert σ1 σ2 σ1' StarN.
    size induction n.
    inv Sim; zzsimpl.
    + invc StarN; eauto. zzsimpl.
      eapply star2_star2n in H4. dcr.
      edestruct (star2n_reach' H11 H7) as [?|[?|?]]; eauto; subst; dcr. eapply H.
      * econstructor 1. eapply star2n_plus; eauto. omega. eauto. eauto.
      * eapply H3; eauto. admit.
      * subst.

        eapply H3. Focus 2. eauto. omega. eauto.



Qed.


Lemma redc_simc {S} `{StateType S} {S'} `{StateType S'} (σ1 σ1':S) (σ2 σ2':S') t r
  : simc r t σ1'  σ2'
    -> star2 step σ1 nil σ1'
    -> star2 step σ2 nil σ2'
    -> simc r t σ1 σ2.
Proof.
  intros.
  eapply redc_upto; hnf; eauto 20.
Qed.

*)



Definition sconv {S} `{StateType S} (σ1 σ2:S) :=
  star2 step σ1 nil σ2 \/ star2 step σ2 nil σ1.

Instance sconv_refl {S} `{StateType S} : Reflexive sconv.
Proof.
  hnf; intros; hnf; left; eapply star2_refl.
Qed.

Instance sconv_sym {S} `{StateType S} : Symmetric sconv.
Proof.
  hnf; intros; hnf; firstorder.
Qed.

Lemma sconv_star2 {S} `{StateType S} (σ1 σ2:S)
  : star2 step σ1 nil σ2
    -> sconv σ1 σ2.
firstorder.
Qed.

Lemma sconv_plus2 {S} `{StateType S} (σ1 σ2:S)
  : plus2 step σ1 nil σ2
    -> sconv σ1 σ2.
  firstorder using plus2_star2.
Qed.

Lemma sconv_star2' {S} `{StateType S} (σ1 σ2:S)
  : star2 step σ1 nil σ2
    -> sconv σ2 σ1.
firstorder.
Qed.

Lemma sconv_plus2' {S} `{StateType S} (σ1 σ2:S)
  : plus2 step σ1 nil σ2
    -> sconv σ2 σ1.
Proof.
  unfold sconv; intros; eauto using plus2_star2.
Qed.

Hint Resolve sconv_star2 sconv_plus2 sconv_star2' sconv_plus2'.

Lemma sconv_closed {S} `{StateType S} (σ1 σ2 σ1' σ2':S)
  : sconv σ1 σ2
    -> star2 step σ1 nil σ1'
    -> star2 step σ2 nil σ2'
    -> sconv σ1' σ2'.
Proof.
  unfold sconv; intros; destruct H0; zzsimpl; try zzcases; eauto.
  edestruct (star2_reach H1 H2); eauto. eapply H.
  edestruct (star2_reach H1 H2); eauto. eapply H.
Qed.

Hint Resolve sconv_closed.

Lemma sconv_activated_right  {S} `{StateType S} σ1 σ2
  : sconv σ1 σ2 -> activated σ2 ->
    exists σ1', star2 step σ1 nil σ1' /\ activated σ1'.
Proof.
  intros. destruct H0.
  - zzsimpl. eauto.
  - zzsimpl. eauto using star2.
Qed.

Ltac fold_conv :=
  match goal with
  | [ H : sconv ?σ1 ?σ2, I : star2 step ?σ2 nil ?σ3 |- _ ]
    => eapply sconv_closed in H; [ clear I | eapply star2_refl | eapply  I]
  | [ H : sconv ?σ1 ?σ2, I : star2 step ?σ1 nil ?σ3 |- _ ]
    => eapply sconv_closed in H; [ clear I | eapply  I | eapply star2_refl]
  end.

Definition sim_lockc {S} `{StateType S} {S'} `{StateType S'} r (σ1:S) (σ2:S')
  := companion2 (@sim_gen_lock S _ S' _) r σ1 σ2.

Theorem sim_lockc_sim {S} `{StateType S} {S'} `{StateType S'} r (σ1:S) (σ2:S')
  : sim_lockc bot2 σ1 σ2 -> sim_lock r σ1 σ2.
Proof.
  intros. revert σ1 σ2 H1.
  pcofix CIH; intros.
  pfold. eapply companion2_unfold in H2.
  eapply sim_gen_lock_mon; eauto.
Qed.

Theorem sim_lock_simc {S} `{StateType S} {S'} `{StateType S'} r (σ1:S) (σ2:S')
  : sim_lock bot2 σ1 σ2 -> sim_lockc r σ1 σ2.
Proof.
  intros. revert σ1 σ2 H1.
  unfold sim_lockc.
  eapply tower_ind2; intros.
  - hnf; intros; hnf; intros. eauto.
  - punfold H2.
    eapply sim_gen_lock_mon; eauto; intros.
    destruct PR; isabsurd.
    eapply H1. eauto.
Qed.

Lemma no_activated_plus_step (S : Type) `{StateType S} (σ σ' : S)
  : activated σ -> plus2 step σ nil σ' -> False.
Proof.
  intros. inv H1; destruct y; isabsurd;
    eapply no_activated_tau_step; eauto.
Qed.

(*
Lemma sim_reduction_closed_2 {S} `{StateType S}
      (σ1:S) {S'} `{StateType S'} (σ2 σ2':S')
  : sim_lockc bot2 σ1 σ2
    -> star2 step σ2 nil σ2'
    -> sim_lockc bot2 σ1 σ2'.
Proof.
  intros. general induction H2.
  - eauto.
  - destruct y, yl; isabsurd.
    eapply companion2_unfold in H3. invc H3; relsimpl.
    + eapply IHstar2; eauto.

    + eapply H1; try eapply H9. omega.
      eapply sim_expansion_closed. eapply H6.
      eauto using plus2_star2. eapply star2_refl.
  - eapply star2n_star2 in H3. eapply activated_star_reach in H3; eauto.
  - pfold. eauto.
  - pfold. eapply star2n_star2 in H3.
    eapply star2_reach_normal in H3; eauto. eapply H0.
Qed.
 *)

Lemma sim_lock_terminate_1 {S1} `{StateType S1} (σ2 σ2':S1)
      {S2} `{StateType S2} (σ1:S2)
: star2 step σ2 nil σ2'
  -> normal2 step σ2'
  -> sim_lockc bot2 σ2 σ1
  -> exists σ1', star2 step σ1 nil σ1' /\ normal2 step σ1' /\
           result σ1' = result σ2'.
Proof.
  intros. general induction H1.
  - eapply companion2_unfold in H3. inv H3.
    + exfalso. eapply H2. do 2 eexists; eauto.
    + exfalso.
      eapply (activated_normal _ H1); eauto.
    + eexists σ1; split; eauto. eapply star2_refl.
  - relsimpl.
    eapply companion2_unfold in H4. invc H4; relsimpl.
    edestruct IHstar2; eauto; dcr.
    eexists; split; eauto. eapply star2_silent; eauto.
Qed.

Lemma sim_lock_terminate_2 {S1} `{StateType S1} (σ2 σ2':S1)
      {S2} `{StateType S2} (σ1:S2)
: star2 step σ2 nil σ2'
  -> normal2 step σ2'
  -> sim_lockc bot2 σ1 σ2
  -> exists σ1', star2 step σ1 nil σ1' /\ normal2 step σ1' /\
           result σ1' = result σ2'.
Proof.
  intros. general induction H1.
  - eapply companion2_unfold in H3. inv H3.
    + exfalso. eapply H2. do 2 eexists; eauto.
    + exfalso.
      eapply (activated_normal _ H4); eauto.
    + eexists σ1; split; eauto. eapply star2_refl.
  - relsimpl.
    eapply companion2_unfold in H4. invc H4; relsimpl.
    edestruct IHstar2; eauto; dcr.
    eexists; split; eauto. eapply star2_silent; eauto.
Qed.

Lemma sim_lock_activated_1 {S1} `{StateType S1} (σ1 σ1':S1)
      {S2} `{StateType S2} (σ2:S2)
  : star2 step σ1 nil σ1'
    -> activated σ1'
  -> sim_lockc bot2 σ1 σ2
  -> exists σ2', star2 step σ2 nil σ2' /\
           (activated σ2' /\
           ( forall (evt : event) (σ1'' : S1),
               step σ1' evt σ1'' ->
               exists σ2'' : S2,
                 step σ2' evt σ2'' /\ (sim_lockc bot2 σ1'' σ2''))
           /\
           ( forall (evt : event) (σ2'' : S2),
               step σ2' evt σ2'' ->
               exists σ1'' : S1,
                 step σ1' evt σ1'' /\ (sim_lockc bot2 σ1'' σ2''))).
Proof.
  intros. general induction H1.
  - eapply companion2_unfold in H3. inv H3; relsimpl.
    eexists σ2; split; eauto using star2_refl.
  - relsimpl.
    eapply companion2_unfold in H4. inv H4; relsimpl.
    eapply IHstar2 in H7; eauto; dcr.
    eexists x0; split; eauto. eapply star2_silent; eauto.
Qed.

Lemma sim_lock_activated_2 {S1} `{StateType S1} (σ1 σ1':S1)
      {S2} `{StateType S2} (σ2:S2)
  : star2 step σ1 nil σ1'
    -> activated σ1'
  -> sim_lockc bot2 σ2 σ1
  -> exists σ2', star2 step σ2 nil σ2' /\
           (activated σ2' /\
           ( forall (evt : event) (σ1'' : S1),
               step σ1' evt σ1'' ->
               exists σ2'' : S2,
                 step σ2' evt σ2'' /\ (sim_lockc bot2 σ2'' σ1''))
           /\
           ( forall (evt : event) (σ2'' : S2),
               step σ2' evt σ2'' ->
               exists σ1'' : S1,
                 step σ1' evt σ1'' /\ (sim_lockc bot2 σ2'' σ1''))).
Proof.
  intros. general induction H1.
  - eapply companion2_unfold in H3. inv H3; relsimpl.
    eexists σ2; split; eauto using star2_refl.
  - relsimpl.
    eapply companion2_unfold in H4. inv H4; relsimpl.
    eapply IHstar2 in H7; eauto; dcr.
    eexists x0; split; eauto. eapply star2_silent; eauto.
Qed.

Lemma simc_trans_r_right {S} `{StateType S} {S'} `{StateType S'} r t
       (σ1:S) (σ2:S) (σ3:S')
  : sim_lockc bot2 σ1 σ2
    -> simc r t σ2 σ3
    -> simc r t σ1 σ3.
Proof.
  revert σ1 σ2 σ3. unfold simc.
  eapply tower_ind3.
  - hnf; intros. hnf; intros; eauto.
  - intros.
    eapply companion2_unfold in H2.
    invc H2; invc H3; zzsimpl.
    + econstructor 1. econstructor 1; eauto. eauto.
      eapply H1. eauto. eapply expc_simc. eapply H8.
      eauto. eapply star2_refl.
    + eapply sim_lock_activated_2 in H6; eauto; dcr.
      econstructor 2. eapply star2_silent; eauto.
      eauto. eauto. eauto.
      * intros. edestruct H15; dcr; eauto. edestruct H10; dcr; eauto.
      * intros. edestruct H11; dcr; eauto. edestruct H13; dcr; eauto.
    + eapply sim_lock_terminate_2 in H6; eauto; dcr.
      econstructor 3. rewrite H11; eauto.
      eapply star2_silent; eauto. eauto.
    + eapply sim_lock_terminate_2 in H6; eauto; dcr.
      econstructor 4. rewrite H13; eauto.
      eapply star2_silent; eauto. eauto. eauto. eauto.
    + exfalso.
      eapply (no_activated_plus_step _ _ _ H5 H2).
    + econstructor 2. eapply star2_refl. eauto. eauto. eauto.
      * intros. edestruct H6; eauto; dcr.
        edestruct H11; eauto; dcr. eauto.
      * intros. edestruct H12; eauto; dcr.
        edestruct H7; eauto; dcr. eauto.
    + exfalso; eauto using plus_not_normal.
    + econstructor 3. rewrite H4. eauto.
      eapply star2_refl. eauto.
    + econstructor 4. rewrite H4. eauto.
      eapply star2_refl. eauto. eauto. eauto.
Qed.

Lemma simc_trans_r_left {S} `{StateType S} {S'} `{StateType S'} r t
       (σ3:S) (σ2:S) (σ1:S')
  : sim_lockc bot2 σ2 σ3
    -> simc r t σ1 σ2
    -> simc r t σ1 σ3.
Proof.
  revert σ1 σ2 σ3. unfold simc.
  eapply tower_ind3.
  - hnf; intros. hnf; intros; eauto.
  - intros.
    eapply companion2_unfold in H2.
    invc H2; invc H3; zzsimpl; relsimpl.
    + econstructor 1. eauto. econstructor 1; eauto.
      eapply H1. eauto. eapply expc_simc. eapply H8.
      eapply star2_refl. eauto.
    + eapply sim_lock_activated_1 in H6; eauto; dcr.
      econstructor 2. eauto. eapply star2_silent; eauto.
      eauto. eauto.
      * intros. edestruct H10; dcr; eauto. edestruct H13; dcr; eauto.
      * intros. edestruct H15; dcr; eauto. edestruct H11; dcr; eauto.
    + econstructor 3; eauto.
    + eapply sim_lock_terminate_1 in H6; eauto; dcr.
      econstructor 4. rewrite H13; eauto. eauto.
      eapply star2_silent; eauto. eauto. eauto.
    + exfalso.
      eapply (no_activated_plus_step _ _ _ H4 H8).
    + econstructor 2. eauto. eapply star2_refl. eauto. eauto.
      * intros. edestruct H11; eauto; dcr.
        edestruct H6; eauto; dcr. eauto.
      * intros. edestruct H7; eauto; dcr.
        edestruct H12; eauto; dcr. eauto.
    + econstructor 3; eauto.
    + exfalso; eauto using plus_not_normal.
    + econstructor 3; eauto.
    + econstructor 4. rewrite H2. eauto. eauto.
      eapply star2_refl. eauto. eauto.
Qed.

(*
Definition g {S} `{StateType S} {S'} `{StateType S'}
           (r:(simtype -> S -> S' -> Prop)) : simtype -> S -> S' -> Prop :=
  fun t σ σ' => exists σ1 σ2, simc bot3 t σ σ1 /\
                      sconv σ1 σ2
                      /\ r t σ2 σ'.

Lemma g_upto {S} `{StateType S} {S'} `{StateType S'}
  : (forall r, @g S _ S' _ (simc r) <3= simc r).
    Proof.
      intros H1 H2.
      eapply upto.
      - unfold g; hnf; intros.
        destruct IN as [? [? ?]]. dcr.
        do 2 eexists; split; eauto.
      - unfold g; intros.
        destruct PR as [? [? [? [? ?]]]].
        eapply companion3_unfold in H4.
        + { inv H6.
          - econstructor 1. eauto. eauto.
            eapply H3; eauto.
            do 2 eexists; split; eauto.
            split; [|eauto].
            eapply sconv_closed; eauto using plus2_star2.
          - (* plus step <-> activated *)
            admit.
          -
            zzsimpl. zzcases. zzsimpl.
        + econstructor 2; eauto using plus2_star2.
          * intros. unfold upaco3 in *; zzsimpl; eauto 10 using star2_refl.
          * intros. unfold upaco3 in *; zzsimpl; eauto 10 using star2_refl.
        + zzsimpl. assert (t = Sim).
          eapply (@sim_t_Sim_activated t _ _ _ H10 H9 _ _ _ H7); eauto.
          subst.
          econstructor 3; eauto using plus2_star2, star2_trans.
      - (* plus step <-> err *)
        zzsimpl. zzcases.
        + pfold. zzsimpl.
          econstructor 3; eauto; eauto.
        + eapply plus2_star2 in H4.
          exploit (star2_trans H4 H2); eauto.
      - (*  plus step <-> term *)
        zzsimpl. zzcases.
        + pfold. zzsimpl.
          econstructor 4; eauto; eauto.
        + zzsimpl.
          destruct (@sim_t_Sim_normal t _ _ _ _ _ _ H9 H8 H14 H7); eauto.
          * subst.
            pfold. econstructor 3; eauto using plus2_star2, star2_trans.
          * pfold. econstructor 4; eauto using plus2_star2, star2_trans.
            congruence.
      - (* activated <-> plus step *)
        pfold. zzsimpl.
        zzcases. zzsimpl.
        + unfold upaco3 in *.
          econstructor 2; eauto using plus2_star2.
          * intros. zzsimpl; eauto 10 using star2_refl.
          * intros. zzsimpl; eauto 10 using star2_refl.
      - (* activated <-> activated *)
        pfold. zzsimpl.
        unfold upaco3 in *.
        econstructor 2; eauto using plus2_star2.
        * intros. zzsimpl; eauto 10 using star2_refl.
        * intros. zzsimpl; eauto 10 using star2_refl.
      - (* activated <-> err *)
        zzsimpl.
      - (* activated <-> term *)
        zzsimpl.
      - (* term <-> plus step *)
        case_eq (result σ1'); intros.
        + pfold. zzsimpl. zzcases.
          zzsimpl.
          econstructor 4; eauto. eauto.
        + zzsimpl.
          rewrite H4 in H10.
          destruct (@sim_t_Sim_normal_step _ _ _ _ _ _ _ H10 H9 H15); eauto.
          * subst.
            pfold. econstructor 3; eauto. congruence.
          * destruct H2; dcr.
            zzsimpl.
            pfold. econstructor 4; eauto. congruence.
      - zzsimpl.
      - (* term <-> err *)
        zzsimpl.
        pfold. econstructor 3; eauto. congruence.
      - (* term <-> term *)
        zzsimpl.
        pfold. econstructor 4; eauto. congruence.


            + econstructor 1. eauto. eauto.
              eapply H3; eauto.
              do 2 eexists; split; eauto.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          - admit.
          }
        + {
            inv H4; inv H6.
            - zzsimpl. zzcases.
              + econstructor 1. eauto. eauto.
              eapply H3; eauto.
              do 2 eexists; split; eauto.
              + econstructor 1. eauto. eauto.
                eapply H3; eauto.
                do 2 eexists; split; eauto.

          }

    Qed.
 *)

(*

Lemma simc_trans_r_right {S} `{StateType S} {S'} `{StateType S'} r t
       (σ1:S) (σ2a σ2b:S) (σ3:S')
  : simc bot3 t σ1 σ2a
    -> (star2 step σ2a nil σ2b \/ star2 step σ2b nil σ2a)
    -> simc r t σ2b σ3
    -> simc r t σ1 σ3.
Proof.

Lemma simc_trans_r_right {S} `{StateType S} {S'} `{StateType S'} r t
       (σ1:S) (σ2a σ2b:S) (σ3:S')
  : simc bot3 t σ1 σ2a
    -> (star2 step σ2a nil σ2b \/ star2 step σ2b nil σ2a)
    -> simc r t σ2b σ3
    -> simc r t σ1 σ3.
Proof.
  eapply upto.
  unfold simc.
  revert σ1 σ2a σ2b σ3. eapply tower_ind; intros.
  hnf; intros; eauto.
  intros.
  assert (sim r t σ2b σ3). admit.
  eapply simc_sim in H4.
  eapply companion3_fold; eauto using sim_gen_mon.
  destruct H4.
*)