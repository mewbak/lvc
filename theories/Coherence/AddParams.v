Require Import Util CSet IL Annotation MapDefined AllInRel.
Require Import Sim LabelsDefined Liveness.
Require Import Coherence Invariance Delocation DelocationAlgo DelocationCorrect.
Require Import Liveness LabelsDefined.

Arguments sim S {H} S' {H0} r t _ _.

Definition addParams (s:IL.stmt) (lv:ann (set var)) : IL.stmt :=
  let additional_params := fst (computeParameters nil nil nil s lv) in
  compile nil s additional_params.

Lemma addParams_correct b (E:onv val) (ili:IL.stmt) lv
  : defined_on (getAnn lv) E
    -> live_sound Imperative nil nil ili lv
    -> noUnreachableCode (isCalled b) ili
    -> sim I.state F.state bot3 Sim
          (nil, E, ili)
          (nil:list F.block, E, addParams ili lv).
Proof with eauto.
  intros. subst. unfold addParams.
  eapply sim_trans with (S2:=I.state).
  - eapply bisim_sim.
    eapply correct; eauto.
    + eapply is_trs; eauto...
    + eapply (@live_sound_compile nil)...
      eapply is_trs...
      eapply is_live...
  - eapply bisim_sim.
    eapply bisim_sym.
    eapply (@srdSim_sim nil nil nil nil nil);
      [ | isabsurd | econstructor | reflexivity | | econstructor ].
    + eapply trs_srd; eauto.
      eapply is_trs...
    + eapply (@live_sound_compile nil nil nil)...
      eapply is_trs...
      eapply is_live...
Qed.

Lemma addParams_live b ili lv
  (LS:live_sound Imperative nil nil ili lv)
  (NUC:noUnreachableCode (isCalled b) ili)
  : live_sound FunctionalAndImperative nil nil
               (addParams ili lv) lv.
Proof.
  unfold addParams.
  eapply srd_live_functional; eauto using PIR2; eauto.
  - eapply (@live_sound_compile nil nil nil nil);
      eauto using is_trs, is_live.
  - eauto using trs_srd, is_trs.
  - exploit compile_noUnreachableCode; eauto using is_trs.
Qed.
