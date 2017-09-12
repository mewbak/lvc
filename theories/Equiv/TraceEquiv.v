Require Import List.
Require Export Util Var Val Exp Env Map CSet AutoIndTac IL AllInRel.
Require Export SmallStepRelations StateType NonParametricBiSim Sim.

Set Implicit Arguments.
Unset Printing Records.

(** * Divergence *)

CoInductive diverges S `{StateType S} : S -> Prop :=
| DivergesI σ σ'
  : step σ EvtTau σ'
    -> diverges σ'
    -> diverges σ.

Lemma diverges_reduction_closed S `{StateType S} (σ σ':S)
: diverges σ -> star2 step σ nil σ'  -> diverges σ'.
Proof.
  intros. general induction H1; eauto using diverges.
  invt diverges; relsimpl. eauto.
Qed.

Lemma diverges_never_activated S `{StateType S} (σ:S)
: activated σ -> diverges σ -> False.
Proof.
  intros. invt diverges; relsimpl.
Qed.

Lemma diverges_never_terminates S `{StateType S} (σ:S)
: normal2 step σ -> diverges σ -> False.
Proof.
  intros. invt diverges; relsimpl.
Qed.

(** ** Bisimilarity preserves silent divergence *)

Lemma bisim_sound_diverges S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: bisim σ σ' -> diverges σ -> diverges σ'.
Proof.
  revert σ σ'. cofix COH; intros.
  inv H1.
  - eapply plus2_destr_nil in H4. dcr.
    econstructor. eauto.
    eapply COH; eauto.
    eapply simp_bisim.
    eapply sim_reduction_closed.
    eapply bisim_simp. eapply H1. econstructor.
    eapply (star2_step EvtTau); eauto. econstructor.
  - eapply diverges_reduction_closed in H3.
    + exfalso. eapply (diverges_never_activated H5); eauto.
    + eapply H2.
  - eapply diverges_reduction_closed in H4.
    + exfalso. eapply (diverges_never_terminates H6); eauto.
    + eapply H2.
Qed.

(** ** Silently diverging programs are bisimlar *)

Lemma bisim_complete_diverges S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: diverges σ -> diverges σ' -> bisim σ σ'.
Proof.
  revert σ σ'. cofix COH; intros.
  inv H1; inv H2.
  econstructor. econstructor; eauto. econstructor; eauto.
  eapply COH; eauto.
Qed.


(** * Prefix Trace Equivalence (partial traces) **)

(** A prefix is a list of [extevent] *)

Inductive extevent :=
  | EEvtExtern (evt:event)
  | EEvtTerminate (res:option val).

(** A relation that assigns prefixes to states *)

Inductive prefix {S} `{StateType S} : S -> list extevent -> Prop :=
  | producesPrefixSilent (σ:S) (σ':S) L :
      step σ EvtTau σ'
      -> prefix σ' L
      -> prefix σ  L
  | producesPrefixExtern (σ:S) (σ':S) evt L :
      activated σ
      -> step σ evt σ'
      -> prefix σ' L
      -> prefix σ (EEvtExtern evt::L)
  | producesPrefixTerm (σ:S) (σ':S) r
    : result σ' = r
      -> star2 step σ nil σ'
      -> normal2 step σ'
      -> prefix σ (EEvtTerminate r::nil)
  | producesPrefixPrefix (σ:S)
    : prefix σ nil.

(** ***Closedness under silent reduction/expansion *)

Lemma prefix_star2_silent {S} `{StateType S} (σ σ':S) L
 : star2 step σ nil σ' ->
   prefix σ' L -> prefix σ L.
Proof.
  intros. general induction H0; eauto.
  - destruct yl, y; simpl in *; try congruence.
    econstructor 1; eauto.
Qed.

Lemma prefix_star2_silent' {S} `{StateType S} (σ σ':S) L
 : star2 step σ nil σ' ->
   prefix σ L -> prefix σ' L.
Proof.
  intros. general induction H0; eauto.
  - destruct yl, y; simpl in *; try congruence.
    eapply IHstar2; eauto.
    inv H2.
    + relsimpl; eauto.
    + relsimpl.
    + exploit star2_reach_silent_step; eauto. eapply H.
      destruct H3; subst. exfalso. eapply H5; firstorder.
      econstructor 3; eauto.
    + econstructor 4.
Qed.

(** ** Bisimilarity is sound for prefix inclusion *)

Lemma bisim_terminate {S1} `{StateType S1} (σ1 σ1':S1)
      {S2} `{StateType S2} (σ2:S2)
: star2 step σ1 nil σ1'
  -> normal2 step σ1'
  -> sim bot3 Bisim σ1 σ2
  -> exists σ2', star2 step σ2 nil σ2' /\ normal2 step σ2' /\ result σ1' = result σ2'.
Proof.
  intros. general induction H1.
  - pinversion H3; subst.
    + exfalso. eapply H2. inv H1; do 2 eexists; eauto.
    + exfalso. eapply star2_normal in H1; eauto. subst.
      eapply (activated_normal _ H5); eauto.
    + eapply star2_normal in H4; eauto; subst.
      eexists; split; eauto.
  - destruct y; isabsurd. simpl.
    eapply IHstar2; eauto.
    eapply sim_reduction_closed_1; eauto using star2, star2_silent.
Qed.


Lemma bisim_activated {S1} `{StateType S1} (σ1:S1)
      {S2} `{StateType S2} (σ2:S2)
: activated σ1
  -> sim bot3 Bisim σ1 σ2
  -> exists σ2', star2 step σ2 nil σ2' /\ activated σ2' /\
           ( forall (evt : event) (σ1'' : S1),
               step σ1 evt σ1'' ->
               exists σ2'' : S2,
                 step σ2' evt σ2'' /\
                 (sim bot3 Bisim σ1'' σ2''))
           /\
           ( forall (evt : event) (σ2'' : S2),
               step σ2' evt σ2'' ->
               exists σ1' : S1,
                 step σ1 evt σ1' /\
                 (sim bot3 Bisim σ1' σ2'')).
Proof.
  intros.
  pinversion H2; subst.
  -  exfalso. edestruct (plus2_destr_nil H3); dcr.
     destruct H1 as [? []].
     exploit (step_internally_deterministic _ _ _ _ H7 H1); dcr; congruence.
  - assert (σ1 = σ0). eapply activated_star_eq; eauto. subst σ1.
    eexists σ3; split; eauto. split; eauto. split.
    intros. edestruct H7; eauto; dcr. destruct H12; isabsurd.
    eexists; split; eauto.
    intros. edestruct H8; eauto; dcr. destruct H12; isabsurd.
    eexists; split; eauto.
  - exfalso. refine (activated_normal_star _ H1 _ _); eauto using star2.
Qed.

Lemma bisim_prefix' {S} `{StateType S} {S'} `{StateType S'} (sigma:S) (σ':S')
: bisim sigma σ' -> forall L, prefix sigma L -> prefix σ' L.
Proof.
  intros. general induction H2.
  - eapply bisim_simp in H3.
    eapply IHprefix; eauto.
    eapply simp_bisim. eapply sim_reduction_closed_1; eauto.
    eapply (star2_step _ _ H0). eapply star2_refl.
  - eapply bisim_simp in H4.
    eapply sim_activated in H4; eauto.
    destruct H4 as [? [? [? []]]].
    destruct evt.
    + eapply prefix_star2_silent; eauto.
      edestruct H6; eauto. destruct H8.
      econstructor 2. eauto. eapply H8.
      eapply IHprefix; eauto.
      eapply simp_bisim. eapply H9.
    + exfalso; eapply (no_activated_tau_step _ H0 H1); eauto.
  - eapply (@bisim_simp Bisim) in H4. eapply bisim_terminate in H4; eauto.
    destruct H4 as [? [? []]]. econstructor 3; [ | eauto | eauto]. congruence.
  - econstructor 4.
Qed.

Lemma bisim_prefix {S} `{StateType S} {S'} `{StateType S'} (sigma:S) (σ':S')
  : bisim sigma σ' -> forall L, prefix sigma L <-> prefix σ' L.
Proof.
  split; eapply bisim_prefix'; eauto.
  eapply NonParametricBiSim.bisim_sym; eauto.
Qed.

(** ** The only prefix is empty if and only if the state diverges *)

Lemma produces_only_nil_diverges S `{StateType S} (σ:S)
: (forall L, prefix σ L -> L = nil) -> diverges σ.
Proof.
  revert σ. cofix f; intros.
  destruct (@step_dec _ H σ).
  - destruct H1; dcr. destruct x.
    + exfalso. exploit H0. econstructor 2; try eapply H2.
      eexists; eauto.
      econstructor 4. congruence.
    + econstructor. eauto. eapply f.
      intros. eapply H0.
      eapply prefix_star2_silent.
      eapply star2_silent; eauto. econstructor. eauto.
  - exfalso.
    exploit H0. econstructor 3. reflexivity. econstructor. eauto. congruence.
Qed.

Lemma prefix_extevent S `{StateType S} (σ:S) evt L
: prefix σ (EEvtExtern evt::L)
  -> exists σ', star2 step σ nil σ'
          /\ activated σ'
          /\ exists σ'', step σ' evt σ'' /\ prefix σ'' L.
Proof.
  intros. general induction H0.
  - edestruct IHprefix. reflexivity. dcr.
    eexists x; split; eauto using star2_silent.
  - eexists σ; eauto using star2.
Qed.

Lemma prefix_terminates S `{StateType S} (σ:S) r L
:  prefix σ (EEvtTerminate r::L)
   -> exists σ', star2 step σ nil σ' /\ normal2 step σ' /\ result σ' = r /\ L = nil.
Proof.
  intros. general induction H0.
  - edestruct IHprefix. reflexivity.
    eexists x; dcr; subst. eauto using star2_silent.
  - eexists; intuition; eauto.
Qed.

Lemma diverges_produces_only_nil S `{StateType S} S' `{StateType S'} (σ:S)
: diverges σ -> (forall L, prefix σ L -> L = nil).
Proof.
  intros. general induction L; eauto.
  destruct a.
  - eapply prefix_extevent in H2; dcr.
    exfalso. eapply diverges_never_activated; eauto.
    eapply diverges_reduction_closed; eauto.
  - eapply prefix_terminates in H2; dcr; subst.
    exfalso. eapply diverges_never_terminates; eauto using diverges_reduction_closed.
Qed.

(** ** Prefix Equivalence is sound for divergence *)

Lemma produces_diverges S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: (forall L, prefix σ L <-> prefix σ' L)
  -> diverges σ -> diverges σ'.
Proof.
  intros.
  pose proof (diverges_produces_only_nil H2).
  eapply produces_only_nil_diverges.
  intros. eapply H3. rewrite H1. eauto.
Qed.

(** ** Several closedness properties *)

Lemma prefix_star_activated S `{StateType S} (σ1 σ1' σ1'':S) evt L
: star2 step σ1 nil σ1'
  -> activated σ1'
  -> step σ1' evt σ1''
  -> prefix σ1'' L
  -> prefix σ1 (EEvtExtern evt::L).
Proof.
  intros. general induction H0.
  - econstructor 2; eauto.
  - relsimpl.
    econstructor; eauto.
Qed.

Lemma prefix_preserved' S `{StateType S} S' `{StateType S'} (σ1 σ1' σ1'':S) (σ2 σ2' σ2'':S') evt
: (forall L : list extevent, prefix σ1 L <-> prefix σ2 L)
  -> star2 step σ1 nil σ1'
  -> activated σ1'
  -> step σ1' evt σ1''
  -> star2 step σ2 nil σ2'
  -> activated σ2'
  -> step σ2' evt σ2''
  -> forall L, prefix σ1'' L -> prefix σ2'' L.
Proof.
  intros.
  - exploit (prefix_star_activated _ H2 H3 H4 H8).
    eapply H1 in H9.
    eapply prefix_extevent in H9. dcr.
    exploit both_activated. eapply H11. eapply H5. eauto. eauto. subst.
    assert (x0 = σ2''). eapply step_externally_determined; eauto. subst; eauto.
Qed.

Lemma prefix_preserved S `{StateType S} S' `{StateType S'} (σ1 σ1' σ1'':S) (σ2 σ2' σ2'':S') evt
:
  (forall L : list extevent, prefix σ1 L <-> prefix σ2 L)
  -> star2 step σ1 nil σ1'
  -> activated σ1'
  -> step σ1' evt σ1''
  -> star2 step σ2 nil σ2'
  -> activated σ2'
  -> step σ2' evt σ2''
  -> forall L, prefix σ1'' L <-> prefix σ2'' L.
Proof.
  split; intros.
  eapply (prefix_preserved' _ _ H1); eauto.
  symmetry in H1.
  eapply (prefix_preserved' _ _ H1); eauto.
Qed.

Lemma produces_silent_closed {S} `{StateType S}  S' `{StateType S'}  (σ1 σ1':S) (σ2 σ2':S')
: star2 step σ1 nil σ1'
  -> star2 step σ2 nil σ2'
  -> (forall L, prefix σ1 L <-> prefix σ2 L)
  -> (forall L, prefix σ1' L <-> prefix σ2' L).
Proof.
  split; intros.
  - eapply prefix_star2_silent'; eauto. eapply H3.
    eapply prefix_star2_silent; eauto.
  - eapply prefix_star2_silent'; eauto. eapply H3.
    eapply prefix_star2_silent; eauto.
Qed.

(** * Trace Equivalence (maximal traces) *)

CoInductive stream (A : Type) : Type :=
| sil : stream A
| sons : A -> stream A -> stream A.

Arguments sil [A].

CoInductive coproduces {S} `{StateType S} : S -> stream extevent -> Prop :=
| CoProducesExtern (σ σ' σ'':S) evt L :
    star2 step σ nil σ'
      -> activated σ'
      -> step σ' evt σ''
      -> coproduces σ'' L
      -> coproduces σ (sons (EEvtExtern evt) L)
| CoProducesSilent (σ:S) :
    diverges σ
    -> coproduces σ sil
| CoProducesTerm (σ:S) (σ':S) r
  : result σ' = r
    -> star2 step σ nil σ'
    -> normal2 step σ'
    -> coproduces σ (sons (EEvtTerminate r) sil).

(** ** Several closedness properties *)

Lemma coproduces_reduction_closed_step S `{StateType S} (σ σ':S) L
: coproduces σ L -> step σ EvtTau σ'  -> coproduces σ' L.
Proof.
  intros. inv H0.
  - exploit activated_star_reach. eapply H3. eauto.
    eapply (star2_step EvtTau); eauto. econstructor.
    econstructor. eapply H6. eauto. eauto. eauto.
  - econstructor. eapply diverges_reduction_closed; eauto.
    eapply (star2_step EvtTau); eauto. econstructor.
  - relsimpl.
    econstructor; eauto.
Qed.

Lemma coproduces_reduction_closed S `{StateType S} (σ σ':S) L
: coproduces σ L -> star2 step σ nil σ'  -> coproduces σ' L.
Proof.
  intros. general induction H1; eauto using coproduces. eauto.
  destruct yl, y; simpl in *; try congruence.
  eapply IHstar2; eauto.
  eapply coproduces_reduction_closed_step; eauto.
Qed.

Lemma coproduces_expansion_closed_step S `{StateType S} (σ σ':S) L
: coproduces σ' L -> step σ EvtTau σ'  -> coproduces σ L.
Proof.
  intros. inv H0.
  - econstructor; eauto.
    eapply star2_trans_silent; eauto using star2_silent, star2_refl.
  - econstructor; eauto. econstructor; eauto.
  - econstructor; eauto using star2_silent, star2_refl.
Qed.


(** ** Bisimilarity is sound for maximal traces *)
Lemma bisim_coproduces S `{StateType S} S' `{StateType S'} (sigma:S) (σ':S')
  : bisim sigma σ' -> forall L, coproduces sigma L -> coproduces σ' L.
Proof.
  revert sigma σ'. cofix COH; intros.
  inv H2.
  - assert (sim bot3 Bisim σ'0 σ').
    eapply sim_reduction_closed. eapply (bisim_simp _ H1).
    eauto. econstructor.
    exploit (bisim_activated H4 H7). dcr.
    edestruct H11. eauto. dcr.
    econstructor; try eapply H10. eauto. eauto.
    eapply COH; eauto.
    eapply simp_bisim. eauto.
  - econstructor. eapply (bisim_sound_diverges H1); eauto.
  - exploit (bisim_terminate H4 H5 (bisim_simp _ H1)).
    dcr.
    econstructor; eauto.
Qed.

(** ** Prefix trace equivalence coincides with maximal trace equivalence. *)

Lemma produces_coproduces' S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: (forall L, prefix σ L <-> prefix σ' L)
  -> (forall T, coproduces σ T -> coproduces σ' T).
Proof.
  revert σ σ'.
  cofix f; intros.
  inv H2.
  - assert (prefix σ (EEvtExtern evt::nil)).
    eapply prefix_star_activated; eauto. econstructor 4.
    eapply H1 in H7.
    eapply prefix_extevent in H7. dcr.
    econstructor. eauto. eauto. eauto. eapply f; try eapply H6.
    eapply (prefix_preserved _ _ _ H1); eauto.
  - exploit (produces_diverges H1 H3).
    econstructor. eauto.
  - assert (prefix σ (EEvtTerminate (result σ'0)::nil)).
    econstructor 3; eauto. eapply H1 in H3.
    eapply prefix_terminates in H3. dcr.
    econstructor 3; eauto.
Qed.

Lemma produces_coproduces S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: (forall L, prefix σ L <-> prefix σ' L)
  -> (forall T, coproduces σ T <-> coproduces σ' T).
Proof.
  split; eapply produces_coproduces'; eauto. symmetry; eauto.
Qed.

(** ** Bisimilarity is complete for prefix trace equivalence. *)

Require Import Classical_Prop Coq.Logic.Epsilon.

Lemma neither_diverges S `{StateType S} (σ:S)
  (H0 : ~ (exists σ' : S, star2 step σ nil σ' /\ normal2 step σ'))
  (H1 : ~ (exists σ' : S, star2 step σ nil σ' /\ activated σ'))
  : diverges σ.
Proof.
  revert σ H0 H1. cofix f.
  intros. destruct (@step_dec _ H σ).
  - inv H2; dcr.
    destruct x.
    + exfalso. eapply H1; eexists σ; split; eauto using star2_refl.
      do 2 eexists; eauto.
    + econstructor. eauto. eapply f; intro; dcr.
      * eapply H0; eexists; split; eauto. eapply star2_silent; eauto.
      * eapply H1; eexists; split; eauto. eapply star2_silent; eauto.
  - exfalso. eapply H0; eexists σ; split; eauto using star2_refl.
Qed.

Lemma three_possibilities S `{StateType S} (σ:S)
: (exists σ', star2 step σ nil σ' /\ normal2 step σ')
  \/ (exists σ', star2 step σ nil σ' /\ activated σ')
  \/ diverges σ.
Proof.
  destruct (classic (exists σ' : S, star2 step σ nil σ' /\ normal2 step σ')); eauto; right.
  destruct (classic (exists σ' : S, star2 step σ nil σ' /\ activated σ')); eauto; right.
  eapply neither_diverges; eauto.
Qed.

Require Import Coq.Logic.ClassicalDescription.

Lemma three_possibilities_strong S `{StateType S} (σ:S)
: { σ' : S | star2 step σ nil σ' /\ normal2 step σ' }
  + { σ' : S & { p : star2 step σ nil σ' &
                     { ext : extern & { σ'' : S | step σ' (EvtExtern ext) σ'' } } } }
  + diverges σ.
Proof.
  destruct (excluded_middle_informative (exists σ' : S, star2 step σ nil σ' /\ normal2 step σ')); eauto.
  - eapply constructive_indefinite_description in e. eauto.
  - destruct (excluded_middle_informative (exists σ' : S, star2 step σ nil σ' /\ activated σ')).
    + eapply constructive_indefinite_description in e.
      left; right. destruct e. eexists x; eauto. dcr; eauto.
      eapply constructive_indefinite_description in H1. destruct H1.
      eapply constructive_indefinite_description in e. destruct e.
      eauto.
    + right. revert σ n n0. cofix f.
      intros. destruct (@step_dec _ H σ).
      * inv H0; dcr.
        destruct x.
        -- exfalso. eapply n0; eexists σ; split; eauto using star2_refl.
           do 2 eexists; eauto.
        -- econstructor. eauto. eapply f; intro; dcr.
           ++ eapply n; eexists; split; eauto. eapply star2_silent; eauto.
           ++ eapply n0; eexists; split; eauto. eapply star2_silent; eauto.
      * exfalso. eapply n; eexists σ; split; eauto using star2_refl.
Qed.

CoFixpoint tr S `{StateType S} (σ:S) : stream extevent.
Proof.
  destruct (three_possibilities_strong σ) as [[|]|].
  - destruct s.
    eapply (sons (EEvtTerminate (result x)) sil).
  - destruct s as [? [? ?]]. destruct s. destruct s.
    eapply (sons (EEvtExtern (EvtExtern x1)) (tr S H x2)).
  - eapply sil.
Defined.

Definition stream_match A (s:stream A) :=
  match s with
  | sil => sil
  | sons a b => sons a b
  end.

Lemma stream_id A (s:stream A)
  : s = stream_match s.
Proof.
  destruct s. reflexivity. reflexivity.
Qed.

Lemma coproduces_total S `{StateType S} (σ:S)
  : coproduces σ (tr σ).
Proof.
  revert σ.
  cofix f; intros.
  rewrite stream_id. simpl.
  destruct (three_possibilities_strong σ) as [[|]|].
  - destruct s. econstructor. reflexivity. eauto. eauto.
  - destruct s. destruct s. destruct s. destruct s.
    econstructor; eauto.
    do 2 eexists; eauto.
  - econstructor; eauto.
Qed.

Lemma coproduces_prefix S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
  : (forall T, coproduces σ T -> coproduces σ' T)
      -> forall L, prefix σ L -> prefix σ' L.
Proof.
  intros. general induction H2.
  - eapply IHprefix; eauto using coproduces_expansion_closed_step.
  - assert (coproduces σ (sons (EEvtExtern evt) (tr σ'))). {
      econstructor 1; eauto using star2_silent, star2_refl.
      eapply coproduces_total.
    }
    eapply H4 in H5. inv H5.
    eapply prefix_star_activated; eauto.
    eapply IHprefix.
    intros.
    assert (coproduces σ (sons (EEvtExtern evt) T)). {
      econstructor 1; eauto using star2_silent, star2_refl.
    }
    eapply H4 in H7. inv H7.
    relsimpl.
    exploit (step_externally_determined _ _ _ _ H11 H17). subst. eauto.
  - assert (coproduces σ (sons (EEvtTerminate (result σ')) sil)). {
      econstructor; eauto.
    }
    eapply H4 in H0. inv H0.
    econstructor 3; eauto.
  - econstructor 4.
Qed.

Lemma coproduces_prefix_iff S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
  : (forall T, coproduces σ T <-> coproduces σ' T)
    -> forall L, prefix σ L <-> prefix σ' L.
Proof.
  split; eapply coproduces_prefix; firstorder.
Qed.

Lemma prefix_bisim S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: (forall L, prefix σ L <-> prefix σ' L)
  -> bisim σ σ'.
Proof.
  revert σ σ'.
  cofix f; intros.
  destruct (three_possibilities σ) as [A|[A|A]].
  - dcr.
    assert (prefix σ (EEvtTerminate (result x)::nil)). {
      econstructor 3; eauto.
    }
    eapply H1 in H2.
    eapply prefix_terminates in H2. dcr.
    econstructor 3; eauto.
  - dcr. inv H4; dcr.
    assert (prefix x1 nil) by econstructor 4.
    exploit (prefix_star_activated _ H3 H4 H5 H2).
    eapply H1 in H6.
    eapply prefix_extevent in H6. dcr.
    econstructor 2; eauto.
    + intros.
      assert (B:prefix x (EEvtExtern evt::nil)) by
          (econstructor 2; eauto; econstructor 4).
      pose proof H1.
      eapply produces_silent_closed in H9; eauto.
      eapply H9 in B.
      inv B.
      * exfalso. exploit (step_internally_deterministic _ _ _ _ H12 H10 ); eauto. dcr; congruence.
      * eexists; split. eauto. eapply f.
        eapply prefix_preserved; eauto.
    + intros.
      assert (B:prefix x2 (EEvtExtern evt::nil)) by
          (econstructor 2; eauto; econstructor 4).
      pose proof H1.
      eapply produces_silent_closed in H9; eauto.
      eapply H9 in B.
      inv B.
      * exfalso. exploit (step_internally_deterministic _ _ _ _ H12 H5 ); eauto. dcr; congruence.
      * eexists; split. eauto. eapply f.
        eapply prefix_preserved; eauto.
  - assert (diverges σ').
    eapply (produces_diverges H1); eauto.
    eapply bisim_complete_diverges; eauto.
Qed.

Lemma coproduces_terminates S `{StateType S} (σ:S) r T
:  coproduces σ (sons (EEvtTerminate r) T)
   -> exists σ', star2 step σ nil σ' /\ normal2 step σ' /\ result σ' = r /\ T = sil.
Proof.
  intros. inv H0.
  - eexists; intuition; eauto.
Qed.

Lemma diverges_coproduces_only_sil S `{StateType S} S' `{StateType S'} (σ:S)
: diverges σ -> (forall T, coproduces σ T -> T = sil).
Proof.
  intros. inv H2.
  - exfalso.
    eapply diverges_reduction_closed in H1; eauto.
    eapply @diverges_never_activated in H1; eauto.
  - reflexivity.
  - exfalso.
    eapply diverges_reduction_closed in H1; eauto.
    eapply @diverges_never_terminates in H1; eauto.
Qed.

Lemma coproduces_diverges S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: (forall L, coproduces σ L <-> coproduces σ' L)
  -> diverges σ -> diverges σ'.
Proof.
  intros.
  assert (coproduces σ sil). {
    econstructor; eauto.
  }
  eapply H1 in H3.
  inv H3. eauto.
Qed.

Lemma coproduced_bisim S `{StateType S} S' `{StateType S'} (σ:S) (σ':S')
: (forall L, coproduces σ L <-> coproduces σ' L)
  -> bisim σ σ'.
Proof.
  intros. eapply prefix_bisim.
  eapply coproduces_prefix_iff. eauto.
Qed.
