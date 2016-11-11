Require Import List CSet.
Require Import Util AllInRel MapDefined IL Sim Status Annotation.
Require Import Rename RenameApart RenameApart_Liveness.
Require CMap.
Require Liveness LivenessValidators ParallelMove ILN ILN_IL.
Require TrueLiveness LivenessAnalysis LivenessAnalysisCorrect.
Require Coherence Invariance.
Require Delocation DelocationAlgo DelocationCorrect DelocationValidator.
Require Allocation AllocationAlgo AllocationAlgoCorrect.
Require UCE DVE EAE Alpha.
Require ReachabilityAnalysis ReachabilityAnalysisCorrect.
Require Import DCVE.
(* Require CopyPropagation ConstantPropagation ConstantPropagationAnalysis.*)

Require Import String.

Set Implicit Arguments.

Section Compiler.

Hypothesis ssa_construction : stmt -> ann (option (set var)) * ann (list var).
Hypothesis parallel_move : var -> list var -> list var -> (list(list var * list var)).
Hypothesis first : forall (A:Type), A -> ( A -> status (A * bool)) -> status A.

Arguments first {A} _ _.


(*Definition constantPropagationAnalysis :=
Analysis.fixpoint ConstantPropagationAnalysis.constant_propagation_analysis first. *)


Definition additionalArguments s lv :=
  fst (DelocationAlgo.computeParameters nil nil nil s lv).

Class ToString (T:Type) := toString : T -> string.

Hypothesis OutputStream : Type.
Hypothesis print_string : OutputStream -> string -> OutputStream.

Hypothesis toString_nstmt : ILN.nstmt -> string.
Instance ToString_nstmt : ToString ILN.nstmt := toString_nstmt.

Hypothesis toString_stmt : stmt -> string.
Instance ToString_stmt : ToString stmt := toString_stmt.

Hypothesis toString_ann : forall A, (A -> string) -> ann A -> string.
Instance ToString_ann {A} `{ToString A} : ToString (ann A) :=
  toString_ann (@toString A _).

Hypothesis toString_live : set var -> string.
Instance ToString_live : ToString (set var) := toString_live.

Hypothesis toString_list : list var -> string.
Instance ToString_list : ToString (list var) := toString_list.

Notation "S '<<' x '<<' y ';' s" := (let S := print_string S (x ++ "\n" ++ toString y ++ "\n\n") in s) (at level 1, left associativity).

Definition ensure_f P `{Computable P} (s: string) {A} (cont:status A) : status A :=
if [P] then cont else Error s.

Arguments ensure_f P [H] s {A} cont.

Notation "'ensure' P s ; cont " := (ensure_f P s cont)
                                    (at level 20, P at level 0, s at level 0, cont at level 200, left associativity).

(* Print Grammar operconstr. *)

Definition toDeBruijn (ilin:ILN.nstmt) : status IL.stmt :=
  ILN_IL.labIndices nil ilin.

Lemma toDeBruijn_correct (ilin:ILN.nstmt) s (E:onv val)
 : toDeBruijn ilin = Success s
   ->  @sim _ ILN.statetype_I _ _ bot3 Bisim
           (ILN.I.labenv_empty, E, ilin)
           (nil:list I.block, E, s).
Proof.
  intros. unfold toDeBruijn in H. simpl in *.
  eapply ILN_IL.labIndicesSim_sim.
  econstructor; eauto; isabsurd. econstructor; isabsurd. constructor.
Qed.

Arguments sim S {H} S' {H0} r t _ _.

Definition addParams (s:IL.stmt) (lv:ann (set var)) : IL.stmt :=
  let additional_params := additionalArguments s lv in
  Delocation.compile nil s additional_params.


Lemma addParams_correct (E:onv val) (ili:IL.stmt) lv
  : defined_on (getAnn lv) E
    -> Liveness.live_sound Liveness.Imperative nil nil ili lv
    -> LabelsDefined.noUnreachableCode LabelsDefined.isCalled ili
    -> sim I.state F.state bot3 Sim (nil, E, ili) (nil:list F.block, E, addParams ili lv).
Proof with eauto using DCVE_live, DCVE_noUC.
  intros. subst. unfold addParams.
  eapply sim_trans with (S2:=I.state).
  - eapply bisim_sim.
    eapply DelocationCorrect.correct; eauto.
    + eapply DelocationAlgo.is_trs; eauto...
    + eapply (@Delocation.live_sound_compile nil)...
      eapply DelocationAlgo.is_trs...
      eapply DelocationAlgo.is_live...
  - eapply bisim_sim.
    eapply bisim_sym.
    eapply (@Invariance.srdSim_sim nil nil nil nil nil);
      [ | isabsurd | econstructor | reflexivity | | econstructor ].
    + eapply Delocation.trs_srd; eauto.
      eapply DelocationAlgo.is_trs...
    + eapply (@Delocation.live_sound_compile nil nil nil)...
      eapply DelocationAlgo.is_trs...
      eapply DelocationAlgo.is_live...
Qed.

Definition toILF (s:IL.stmt) : IL.stmt :=
  let (s_dcve, lv) := DCVE Liveness.Imperative s in
  addParams s_dcve lv.

Lemma toILF_correct (ili:IL.stmt) (E:onv val)
  (PM:LabelsDefined.paramsMatch ili nil)
  : defined_on (IL.occurVars ili) E
    -> sim I.state F.state bot3 Sim (nil, E, ili) (nil:list F.block, E, toILF ili).
Proof with eauto using DCVE_live, DCVE_noUC.
  intros. subst. unfold toILF.
  eapply sim_trans with (S2:=I.state).
  eapply DCVE_correct_I; eauto. let_pair_case_eq; simpl_pair_eqs; subst.
  unfold fst at 1.
  eapply addParams_correct...
  eauto using defined_on_incl, DCVE_occurVars.
Qed.

(*
Definition optimize (s':stmt) : status stmt :=
  let s := rename_apart s' in
  sdo ALAE <- constantPropagationAnalysis s;
  match ALAE with
    | (AL, AEc) =>
      let AE := (fun x => MapInterface.find x AEc) in
      ensure (ConstantPropagation.cp_sound AE nil s)
             "Constant propagation unsound";
      ensure (forall x, x ∈ freeVars s' -> AE x = None)
             "Constant propagation makes no assumptions on free vars";
      let s := ConstantPropagation.constantPropagate AE s in
      sdo lv <- livenessAnalysis s;
      ensure (TrueLiveness.true_live_sound Liveness.Functional nil s lv) "Liveness unsound (2)";
      Success (DVE.compile nil s lv)
  end.
*)

Print all.

Require Import SimplSpill SpillSim DoSpill DoSpillRm Take Drop.
Require Import ReconstrLive ReconstrLiveSound.
Require Import RenameApart_Liveness.

Definition max := max.
Definition slot k n x := if [x < k] then x else x + n.

Definition spill (k:nat) (s:stmt) (lv:ann (set var)) (VD:set var) : stmt * ann (set var) :=
  let fvl := to_list (getAnn lv) in
  let (R,M) := (of_list (take k fvl), of_list (drop k fvl)) in
  let spl := @simplSpill k nil nil R M s lv in
  let n := fold max VD 0 in
  let slt := slot k n in
  let s_spilled := do_spill slt s spl nil in
  let lv_spilled := reconstr_live nil nil ∅ s_spilled (do_spill_rm slt spl) in
  let s_fun := addParams s_spilled lv_spilled in
  (s_fun, lv_spilled).

Lemma spill_correct k (s:stmt) lv ra E (PM:LabelsDefined.paramsMatch s nil)
      (LV:Liveness.live_sound Liveness.Imperative nil nil s lv)
      (AEF:AppExpFree.app_expfree s)
      (RA:RenamedApart.renamedApart s ra)
      (Def:defined_on (getAnn lv) E)
      (Bnd:Spilling.fv_e_bounded k s)
      (Incl:getAnn lv ⊆ fst (getAnn ra))
      (NUC:LabelsDefined.noUnreachableCode LabelsDefined.isCalled s)
  : sim I.state F.state bot3 Sim
        (nil, E, s)
        (nil, E [slot k (fold max (fst (getAnn ra) ∪ snd (getAnn ra)) 0) ⊝ drop k (to_list (getAnn lv)) <-- lookup_list E (drop k (to_list (getAnn lv)))], fst (spill k s lv (fst (getAnn ra) ∪ snd (getAnn ra)))).
Proof.
  unfold spill.
  set (R:=of_list (take k (to_list (getAnn lv)))).
  set (M:=of_list (drop k (to_list (getAnn lv)))).
  set (spl:=(simplSpill k nil nil R M s lv)).
  set (VD:=fst (getAnn ra) ∪ snd (getAnn ra)).
  set (n := fold max VD 0) in *.
  set (slt:=(slot k n)).
  subst n.
  assert (lvRM:getAnn lv [=] R ∪ M). {
    subst R M. rewrite <- of_list_app. rewrite <- take_eta.
    rewrite of_list_3. eauto.
  }
  eapply sim_trans with (S2:=I.state).
  - eapply sim_I with (slot:=slt) (k:=k) (R:=R) (M:=M) (sl:=spl) (Λ:=nil)
      (VD:=VD)
      (V':=E [slt ⊝ drop k (elements (getAnn lv)) <-- lookup_list E (drop k (elements (getAnn lv)))]);
      eauto.
    + eapply agree_on_update_list_dead; eauto.
      subst R. admit.
    + admit.
    + eapply simplSpill_sat_spillSound; eauto using PIR2. admit.
      subst R. rewrite TakeSet.take_of_list_cardinal; eauto.
      rewrite lvRM; eauto.
    + admit.
    + admit.
    + admit.
    + eapply defined_on_union.
      * admit.
      * admit.
    + rewrite <- Incl, lvRM; eauto.
    + eapply SimI.labenv_sim_nil.
    + eauto.
    + admit.
  - eapply addParams_correct; eauto.
    + admit.
    + eapply (@reconstr_live_sound k slt nil _ nil R M VD); eauto using PIR2.
      ** admit.
      ** admit.
      ** admit.
      ** admit.
      ** reflexivity.
      ** eapply simplSpill_sat_spillSound; eauto using PIR2. admit.
         subst R. rewrite TakeSet.take_of_list_cardinal; eauto.
         rewrite lvRM; eauto.
      ** admit.
      ** isabsurd.
    + eapply (@do_spill_no _ _ _ nil nil).
Qed.



Definition fromILF (k:nat) (s:stmt) : status stmt :=
  let s_eae := EAE.compile s in
  let s_ra := rename_apart s_eae in
  let (s_dcve, lv) := DCVE Liveness.Imperative s_ra in
  let fvl := to_list (getAnn lv) in
  let s_ren := rename_apart s_fun in
  let lv_ren := snd (renameApart_live id (freeVars s_fun) s_fun lv_spilled) in
  let fvl := to_list (getAnn lv_ren) in
  let ϱ := CMap.update_map_with_list fvl fvl (@MapInterface.empty var _ _ _) in
  sdo ϱ' <- AllocationAlgo.regAssign s_ren lv_ren ϱ;
    let s_allocated := rename (CMap.findt ϱ' 0) s_ren in
    let s_lowered := ParallelMove.lower parallel_move
                                       nil
                                       s_allocated
                                       (mapAnn (map (CMap.findt ϱ' 0)) lv_ren) in
    s_lowered.

Opaque LivenessValidators.live_sound_dec.
Opaque DelocationValidator.trs_dec.


Lemma fromILF_correct k (s s':stmt) E (PM:LabelsDefined.paramsMatch s nil)
  : fromILF k s = Success s'
    -> sim F.state I.state bot3 Sim (nil:list F.block, E, s) (nil:list I.block, E, s').
Proof.
  unfold fromILF; intros.
  repeat let_case_eq; repeat simpl_pair_eqs; subst.
  monadS_inv H.
  exploit (@ParallelMove.correct parallel_move nil); try eapply EQ0; try now econstructor; eauto.
  eapply (@Liveness.live_rename_sound _ nil nil).
  eapply (@renameApart_live_sound_srd _ nil nil nil nil nil); eauto.
  clear; isabsurd.
  eapply (@Delocation.live_sound_compile nil nil nil nil); eauto.
  eapply DelocationAlgo.is_trs; eauto.
  eapply (@ReconstrLiveSound.reconstr_live_sound _ _ nil _ nil).


  eapply AllocationAlgo.regAssign_renamedApart_agree in EQ; eauto;
    [|eapply rename_apart_renamedApart; eauto
     |].

  Focus 5. eapply DCVE_live; eauto. eapply EAE.EAE_paramsMatch. eauto.
  admit.
  reflexivity. reflexivity. isabsurd.
  eapply (sim_trans _ H).
  Unshelve.
  eapply sim_trans with (σ2:=(nil:list F.block, E, EAE.compile s)).
  eapply EAE.sim_EAE.
  eapply sim_trans with (σ2:=(nil:list F.block, E, fst (DCVE Liveness.Functional (EAE.compile s)))).
  eapply DCVE_correct_F; eauto. eapply EAE.EAE_paramsMatch; eauto.
  admit.
  eapply sim_trans with (σ2:=(nil:list F.block, E, _)).
  eapply bisim_sim.
  eapply (@Alpha.alphaSim_sim (nil, E, _) (nil, E, _)).
  econstructor; eauto using PIR2, Alpha.envCorr_idOn_refl.
  eapply Alpha.alpha_sym. eapply rename_apart_alpha.

  eapply sim_trans with (σ2:=(nil:list F.block, E, _)).
  eapply bisim_sim.
  eapply Alpha.alphaSim_sim. econstructor; eauto using PIR2.
  instantiate (2:=id).
  eapply Allocation.renamedApart_locally_inj_alpha; eauto.
  eapply rename_apart_renamedApart; eauto.
  eapply AllocationAlgoCorrect.regAssign_correct; eauto.
  admit.
  eapply RenameApart_Liveness.renameApart_live_sound.
  eapply Liveness.live_sound_overapproximation_F; eauto.
  eapply AllocationAlgo.regAssign_renamedApart_agree in EQ1; eauto.
  rewrite fst_renamedApartAnn in EQ1.

  eapply (@Liveness.live_rename_sound _ nil nil); eauto.
  admit.
  eapply sim_trans with (σ2:=(nil, E, rename (CMap.findt x 0) (rename_apart (fst (DCVE (EAE.compile s)))))); eauto.
  eapply Liveness.live_sound_overapproximation_I; eauto.
  eauto.

  exploit rename_apart_renamedApart; eauto.
  exploit AllocationAlgoCorrect.regAssign_correct' as XXX; eauto. admit. admit. admit. admit. admit.
  - eapply injective_on_agree; [| eapply CMap.map_update_list_update_agree; reflexivity].
    hnf; intros ? ? ? ? EqMap.
    rewrite lookup_update_same in EqMap.
    rewrite EqMap; eauto. rewrite lookup_update_same; eauto with cset.
    rewrite of_list_3; eauto.
    rewrite of_list_3; eauto.
  - rewrite fst_renamedApartAnn. eauto.
  - eapply sim_trans with (σ2:=(nil:list F.block, E,
                                    rename (CMap.findt x0 0)
                                           (rename_apart (EAE.compile s)))).
    eapply bisim_sim.
    eapply Alpha.alphaSim_sim. econstructor; eauto using PIR2.
    instantiate (1:=id).
    eapply Allocation.renamedApart_locally_inj_alpha; eauto.
    eapply Liveness.live_sound_overapproximation_F; eauto.
    eapply AllocationAlgo.regAssign_renamedApart_agree in EQ1; eauto.
    rewrite fst_renamedApartAnn in EQ1.
    rewrite <- CMap.map_update_list_update_agree in EQ1; eauto.
    hnf; intros. repeat rewrite <- EQ1; eauto;
                   repeat rewrite lookup_update_same; eauto;
                     rewrite of_list_3; eauto.
    hnf; intros ? ? ? EQy. cbv in EQy. subst. rewrite EQy. reflexivity.
    eapply sim_trans with (S2:=I.state).
    eapply bisim_sim.
    eapply Coherence.srdSim_sim.
    econstructor. eapply Allocation.rename_renamedApart_srd; eauto.
    rewrite fst_renamedApartAnn; eauto.
    eapply I. isabsurd. econstructor. reflexivity.
    eapply (@Liveness.live_rename_sound _ nil); eauto.
    eapply Liveness.live_sound_overapproximation_I; eauto.
    econstructor.
    eapply (ParallelMove.pmSim_sim).
    econstructor; try now econstructor; eauto.
    eapply (@Liveness.live_rename_sound _ nil); eauto.
    eapply Liveness.live_sound_overapproximation_I; eauto.
    eauto.
Qed.
 *)


(*
Lemma optimize_correct (E:onv val) s s'
: optimize s = Success s'
  -> LabelsDefined.labelsDefined s 0
  -> sim (nil:list F.block, E, s) (nil:list F.block, E, s').
Proof.
  intros.
  unfold optimize, ensure_f in *.
  monadS_inv H. destruct x.
  repeat (cases in EQ0; [| isabsurd]).
  monadS_inv EQ0.
  repeat (cases in EQ2; [| isabsurd]).
  invc EQ2.

  eapply sim_trans with (S2:=F.state).
  eapply bisim_sim.
  eapply Alpha.alphaSim_sim. econstructor; eauto using rename_apart_alpha, PIR2.
  eapply Alpha.alpha_sym. eapply rename_apart_alpha. hnf; intros.
  cbv in H, H1. instantiate (1:=E). congruence.
  eapply sim_trans with (S2:=F.state).
  Focus 2.
  eapply DVE.sim_DVE; eauto. reflexivity.
  eapply sim'_sim.
  eapply ValueOpts.sim_vopt; eauto.
  Focus 2.
  eapply ConstantPropagation.cp_sound_eqn; eauto.
  eapply rename_apart_renamedApart. instantiate (1:=nil). simpl.
  eapply labelsDefined_rename_apart; eauto.
  intros; isabsurd.
  rewrite fst_renamedApartAnn.
  intros. hnf; intros.
  rewrite ConstantPropagation.cp_eqns_no_assumption in H. cset_tac; intuition. eassumption.
  constructor.
  eapply rename_apart_renamedApart.
  rewrite fst_renamedApartAnn.
  rewrite ConstantPropagation.cp_eqns_no_assumption. eapply incl_empty. eauto.
  hnf; intuition.
Qed.
*)

End Compiler.

Print Assumptions toDeBruijn_correct.
Print Assumptions toILF_correct.
(* Print Assumptions fromILF_correct.
   Print Assumptions optimize_correct. *)
