Require Import CSet Le Var.

Require Import Plus Util AllInRel Map CSet.
Require Import Val Var Env IL Annotation Lattice DecSolve Filter SigR.
Require Import Analysis AnalysisBackward Terminating.

Remove Hints trans_eq_bool.

Set Implicit Arguments.

Instance PartialOrder_Subset_Equal X `{OrderedType X} : PartialOrder (set X) :=
{
  poLe := Subset;
  poLe_dec := @Subset_computable _ _;
  poEq := Equal;
  poEq_dec := @Equal_computable _ _
}.
Proof.
  - intros. rewrite H0; eauto.
  - hnf; intros. split; eauto.
Defined.

Instance set_var_semilattice : BoundedSemiLattice (set var) := {
  bottom := ∅;
  join := union
}.
Proof.
  - intros; hnf; simpl. cset_tac.
  - hnf; intros. eapply union_idem.
  - hnf; intros. eapply union_comm.
  - hnf; intros. eapply union_assoc.
  - hnf; intros. eapply incl_left.
Defined.

Instance PartialOrder_Subset_Equal_Bounded X `{OrderedType X} U : PartialOrder ({ s : set X | s ⊆ U}) :=
{
  poLe := sig_R Subset;
  poLe_dec x y := _;
  poEq := sig_R Equal;
  poEq_dec x y := _;
}.
Proof.
  - intros [a ?] [b ?]; simpl. intros EQ. rewrite EQ. reflexivity.
  - hnf; intros [a ?] [b ?]; simpl; intros. split; eauto.
Defined.

Instance set_var_semilattice_bounded U : BoundedSemiLattice ({ s : set var | s ⊆ U}) := {
  bottom := exist _ ∅ (@incl_empty var _ U);
  join x y := exist _ (union (proj1_sig x) (proj1_sig y)) _
}.
Proof.
  - destruct x,y; simpl. cset_tac.
  - intros [a ?]; simpl. cset_tac.
  - hnf; intros [a ?]. eapply union_idem.
  - hnf; intros [a ?] [b ?]. eapply union_comm.
  - hnf; intros [a ?] [b ?] [c ?]. eapply union_assoc.
  - hnf; intros [a ?] [b ?]; simpl. eapply incl_left.
  - simpl. unfold Proper, respectful; intros. destruct x,y,x0,y0; simpl in * |- *.
    rewrite H, H0. reflexivity.
  - simpl. unfold Proper, respectful; intros. destruct x,y,x0,y0; simpl in * |- *.
    rewrite H, H0. reflexivity.
Defined.

Lemma bunded_set_terminating X `{OrderedType X} U
  : Terminating {s : ⦃X⦄ | s ⊆ U} poLt.
Proof.
  hnf; intros [s Incl].
  remember (cardinal (U \ s)). assert (cardinal (U \ s) <= n) as Le by omega.
  clear Heqn. revert s Incl Le. induction n; intros.
  - econstructor. intros [y ?] [A B]; simpl in *.
    exfalso. eapply B. assert (cardinal (U \ s) = 0) by omega.
    rewrite <- cardinal_Empty in H0.
    eapply empty_is_empty_1 in H0. eapply diff_subset_equal' in H0.
    cset_tac.
  - intros. econstructor. intros [y ?] [A B]; simpl in *.
    eapply IHn.
    assert (~ y ⊆ s) by (intro; eapply B; split; eauto).
    edestruct not_incl_element; eauto; dcr.
    rewrite cardinal_difference'; eauto.
    rewrite cardinal_difference' in Le; eauto.
    erewrite (@cardinal_2 _ _ _ _ (y \ singleton x) y); eauto;
      [|cset_tac| rewrite Add_Equal; cset_tac; decide (x === a); eauto].
    assert (s ⊆ y \ singleton x) by cset_tac.
    eapply cardinal_morph in H1. omega.
Qed.

Definition liveness_transform
           (ZL:list params) (DL:list (set var))
           (st:stmt)
           (a:anni (⦃var⦄))
  : ⦃var⦄ :=
  match st, a with
  | stmtLet x e s, anni1 d =>
    d \ singleton x ∪ (if [x ∈ d] then Exp.freeVars e else ∅)
  | stmtIf e s t, anni2 ds dt =>
    if [exp2bool e = Some true] then
      ds
    else
      if [ exp2bool e = Some false ] then
        dt
      else
        Exp.freeVars e ∪ (ds) ∪ (dt)
  | stmtApp f Y, anni0 =>
    let lv := nth (counted f) DL ∅ in
    let Z :=  nth (counted f) ZL nil in
    lv \ of_list Z ∪
       list_union (List.map Exp.freeVars
                            (filter_by (fun x => B[x ∈ lv]) Z Y))
  | stmtReturn e, anni0 =>
    Exp.freeVars e
  | stmtExtern x f Y s, anni1 d =>
    d \ singleton x ∪ list_union (List.map Exp.freeVars Y)
  | stmtFun F t, anni1 dt =>
    dt
  | _, _ => ∅
  end.

Require Import Subterm.

Lemma list_sig_decomp A (P:A->Prop)
  : list { a : A | P a }
    -> { L : list A | forall n a, get L n a -> P a }.
Proof.
  intros.
  refine (exist _ (@proj1_sig A P ⊝ X) _).
  intros. inv_get. destruct x. eauto.
Defined.

Lemma not_get_nth_default A (L:list A) n d
  : (forall x, get L n x -> False)
    -> nth n L d = d.
Proof.
  intros. general induction n; destruct L; simpl; eauto using get.
  exfalso; eauto using get.
Qed.

Definition liveness_transform_dep (sT:stmt)
           (ZL:list params)
           (DL:list ({ X : set var | X ⊆ occurVars sT}))
      (s:stmt) (ST:subTerm s sT)
      (a:anni ({X : ⦃var⦄ | X ⊆ occurVars sT}))
  : {X : ⦃var⦄ | X ⊆ occurVars sT}.
Proof.
  eapply (exist _ (liveness_transform ZL
                                      (@proj1_sig _ _ ⊝ DL) s
                                      (mapAnni (@proj1_sig _ _) a))).
  destruct s, a as [|[a ?]|[a ?] [a' ?]|a]; simpl in *;
    try now eapply incl_empty.
  - cases; [| cset_tac].
    cset_tac; eauto. eapply subTerm_occurVars; eauto; simpl. cset_tac.
  - repeat cases; eauto. eapply subTerm_occurVars in ST; simpl in *.
    cset_tac. eapply ST; cset_tac.
  - eapply union_incl_split.
    + destruct (get_dec DL (counted l)) as [[[D PD] GetDL]|].
      * erewrite get_nth; eauto using map_get_1; simpl in *.
        cset_tac.
      * rewrite not_get_nth_default;
          intros; inv_get; simpl in *; eauto using get. cset_tac.
    + rewrite <- (subTerm_occurVars ST); simpl.
      eapply list_union_incl; try eapply H0; eauto with cset.
      intros; inv_get. eapply filter_by_get in H; dcr.
      cases in H3.
      eapply incl_list_union; eauto using map_get_1.
  - eapply subTerm_occurVars in ST; simpl in *. eauto.
  - cset_tac; eauto. eapply subTerm_occurVars; eauto; simpl. cset_tac.
  - eauto.
Defined.

Require Import SetOperations.

Lemma liveness_transform_dep_monotone (sT s : stmt) (ST : subTerm s sT)
      (ZL : 〔params〕) (AL AL' : 〔{x : ⦃var⦄ | x ⊆ occurVars sT}〕)
  : AL ⊑ AL' ->
    forall a b : anni ({x : ⦃var⦄ | x ⊆ occurVars sT}),
      a ⊑ b
      -> liveness_transform_dep ZL AL ST a ⊑ liveness_transform_dep ZL AL' ST b.
Proof.
  intros.
  time (inv H0; destruct s; simpl in * |- *; try reflexivity;
            repeat match goal with
                   | [ x : { x : set var | x ⊆ occurVars sT } |- _ ] =>
                     destruct x as [? ?]
                   end; simpl in * |- *; dcr).
  - eapply incl_union_lr.
    + destruct (get_dec AL (counted l)) as [[[D PD] GetDL]|].
      * erewrite get_nth; eauto using map_get_1; simpl in *.
        PIR2_inv. destruct x. simpl in *; dcr.
        erewrite (@get_nth _ (_ ⊝ AL') ); eauto using map_get_1; simpl in *.
        rewrite H1; eauto.
      * rewrite not_get_nth_default; simpl; intros; inv_get; eauto.
        cset_tac.
    + eapply list_union_incl; eauto with cset.
      intros; inv_get. eapply filter_by_get in H1. dcr.
      destruct (get_dec AL (counted l)) as [[[D PD] GetDL]|].
      * cases in H5.
        erewrite get_nth in COND; eauto; simpl in *.
        PIR2_inv. destruct x1. simpl in *.
        exploit get_filter_by. Focus 4.
        eapply incl_list_union. eapply map_get_1.
        eapply H7. reflexivity. eauto. eauto.
        simpl. cases; eauto.
        erewrite get_nth in NOTCOND; eauto. simpl in *.
        eapply NOTCOND. eapply H1; eauto.
      * rewrite not_get_nth_default in H5. simpl in *.
        cases in H5; cset_tac.
        intros; inv_get; eauto.
  - rewrite H1 at 1. repeat cases; eauto.
    cset_tac.
  - rewrite H1; reflexivity.
  - eauto.
  - repeat cases; try (now congruence); eauto.
    cset_tac.
Qed.

Lemma liveness_transform_dep_ext (sT s : stmt) (ST : subTerm s sT)
      (ZL : 〔params〕) (AL AL' : 〔{x : ⦃var⦄ | x ⊆ occurVars sT}〕)
  : AL ≣ AL' ->
    forall a b : anni ({x : ⦃var⦄ | x ⊆ occurVars sT}),
      a ≣ b
      -> liveness_transform_dep ZL AL ST a ≣ liveness_transform_dep ZL AL' ST b.
Proof.
  intros.
  time (destruct s; eauto with cset; inv H0; simpl; try reflexivity;
            repeat match goal with
                   | [ x : { x : set var | x ⊆ occurVars sT } |- _ ] =>
                     destruct x as [[? ?] ?]
                   end; simpl in * |- *; dcr).
  - rewrite H1 at 1. specialize (H1 x).
    repeat cases; try reflexivity.
    exfalso. eapply NOTCOND. eapply H1. eauto.
    exfalso. eapply NOTCOND. eapply H1. eauto.
  - repeat cases; try (now congruence); eauto.
    rewrite H1, H2. reflexivity.
  - eapply eq_union_lr.
    + destruct (get_dec AL (counted l)) as [[[D PD] GetDL]|].
      * erewrite get_nth; eauto using map_get_1; simpl in *.
        PIR2_inv. destruct x. simpl in *; dcr.
        erewrite (@get_nth _ (_ ⊝ AL') ); eauto using map_get_1; simpl in *.
        rewrite H1. reflexivity.
      * rewrite not_get_nth_default; simpl; intros; inv_get; eauto.
        destruct (get_dec AL' (counted l)) as [[[D PD] GetDL]|].
        exfalso. edestruct PIR2_nth_2; eauto; dcr. eauto.
        rewrite (@not_get_nth_default _ (_ ⊝ AL')); simpl; intros; inv_get; eauto.
    + erewrite filter_by_ext; [reflexivity| eauto with len |].
      * intros; inv_get. get_functional.
        destruct (get_dec AL (counted l)) as [[[D PD] GetDL]|]; PIR2_inv.
        erewrite get_nth; [| eauto using map_get_1].
        destruct x. simpl in *.
        erewrite get_nth; [| eauto using map_get_1]. simpl.
        repeat cases; eauto; exfalso; rewrite H2 in *; eauto.
        repeat erewrite not_get_nth_default; intros; inv_get; eauto.
  - rewrite H1; reflexivity.
  - eauto.
Qed.

Definition liveness_analysis :=
  makeBackwardAnalysis (fun s => { x : ⦃var⦄ | x ⊆ occurVars s}) _
                       liveness_transform_dep
                       liveness_transform_dep_monotone
                       (fun s => (@bunded_set_terminating _ _ (occurVars s))).

Require Import FiniteFixpointIteration.

Definition livenessAnalysis s :=
  let a := safeFixpoint (liveness_analysis s) in
  mapAnn (@proj1_sig _ _) (proj1_sig (proj1_sig a)).
