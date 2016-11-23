Require Import CMap MapNotations CSet Le Arith.Compare_dec.

Require Import Plus Util Status Take Subset1.
Require Import Val Var Env IL Annotation Liveness Fresh MoreList SetOperations.
Require Import Coherence Allocation RenamedApart AllocationAlgo.

Set Implicit Arguments.

Lemma least_fresh_P_spec c G x
  : (~ x <= c -> x ∉ G)
    -> least_fresh_P c G x ∉ G.
Proof.
  unfold least_fresh_P; cases; eauto using least_fresh_spec.
Qed.

Lemma least_fresh_P_gt c G x
  : ~ x <= c
    -> least_fresh_P c G x = x.
Proof.
  intros; unfold least_fresh_P; cases; try omega; eauto.
Qed.

Lemma least_fresh_P_le c G x
  : x <= c
    -> least_fresh_P c G x = least_fresh G.
Proof.
  intros; unfold least_fresh_P; cases; try omega; eauto.
Qed.

Definition sep (c:var) (G:set var) (ϱ:var -> var) :=
  (forall x, x ∈ G -> ~ x <= c -> ϱ x === x)
  /\ (forall x, x ∈ G -> x <= c -> ϱ x <= c).

Instance sep_morphism_impl
  : Proper (eq ==> Equal ==> eq ==> impl) sep.
Proof.
  unfold Proper, respectful, impl; intros; subst.
  destruct H2; split; intros.
  eapply H; eauto. rewrite H0; eauto.
  eapply H1; eauto. rewrite H0; eauto.
Qed.

Instance sep_morphism_iff
  : Proper (eq ==> Equal ==> eq ==> iff) sep.
Proof.
  unfold Proper, respectful; intros; subst.
  split; rewrite H0; eauto.
Qed.

Instance sep_morphism_Subset_impl
  : Proper (eq ==> Subset ==> eq ==> flip impl) sep.
Proof.
  unfold Proper, respectful, flip, impl; intros; subst.
  destruct H2; split; intros; eauto.
Qed.

Instance sep_morphism_Subset_impl'
  : Proper (eq ==> flip Subset ==> eq ==> impl) sep.
Proof.
  unfold Proper, respectful, flip, impl; intros; subst.
  destruct H2; split; intros; eauto.
Qed.

Lemma sep_incl c lv lv' ϱ
  : sep c lv ϱ
    -> lv' ⊆ lv
    -> sep c lv' ϱ.
Proof.
  intros A B. rewrite B; eauto.
Qed.

Lemma sep_agree c D ϱ ϱ'
  : agree_on eq D ϱ ϱ'
    -> sep c D ϱ
    -> sep c D ϱ'.
Proof.
  intros AGR [GT LE]; split; intros.
  - rewrite <- AGR; eauto.
  - rewrite <- AGR; eauto.
Qed.


Hint Resolve sep_incl sep_agree.

Lemma sep_lookup_set c (G:set var) (ϱ:var -> var) x
      (SEP:sep c G ϱ) (NotIn:x ∉ G)
  : ~ x <= c -> x ∉ lookup_set ϱ G.
Proof.
  destruct SEP as [GT LE].
  intros Gt. unfold lookup_set; intro In.
  eapply map_iff in In; eauto.
  destruct In as [y [In EQ]]. hnf in EQ; subst.
  decide (y <= c).
  - exfalso. eauto.
  - exploit GT; eauto.
Qed.

Print Scopes.

Require Import MapNotations.

Lemma sep_update c lv (x:var) (ϱ:Map[var,var])
      (SEP : sep c (lv \ singleton x) (findt ϱ 0))
      (CARD : cardinal (filter (fun x => B[x <= c]) (map (findt ϱ 0) (lv \ singleton x))) < c)
  : sep c lv (findt (ϱ [-x <- least_fresh_P c (map (findt ϱ 0) (lv \ singleton x)) x -]) 0).
Proof.
  destruct SEP as [GT LE].
  split; intros.
  - unfold findt.
    decide (x === x0).
    + rewrite MapFacts.add_eq_o; eauto.
      rewrite least_fresh_P_gt. eauto.
      hnf in e; congruence.
    + rewrite MapFacts.add_neq_o; eauto.
      exploit GT; eauto. cset_tac.
  - unfold findt.
    decide (x === x0).
    + rewrite MapFacts.add_eq_o; eauto.
      rewrite least_fresh_P_le.
      * rewrite (@least_fresh_filter_small c); eauto.
        unfold findt in CARD. unfold var in *. omega.
      * hnf in e; congruence.
    + rewrite MapFacts.add_neq_o; eauto.
      cases; try omega.
      rewrite <- LE; eauto.
      unfold findt. rewrite <- Heq; eauto.
      cset_tac.
Qed.

Lemma sep_nd c G ϱ G'
      (SEP:sep c G (findt ϱ 0)) (Disj: disj G' G)
  : forall x : nat, x > c -> x ∈ G' -> x ∈ map (findt ϱ 0) G -> False.
Proof.
  intros. cset_tac. destruct SEP as [GT LE].
  decide (x0 <= c).
  - exploit LE; eauto; try omega.
  - exploit GT; eauto. cset_tac.
    eapply Disj; eauto; congruence.
Qed.

Lemma sep_lookup_list c (G s:set var) (ϱ:var -> var) x
      (SEP:sep c (G \ s) ϱ)
  : x > c -> x ∈ s -> x ∉ map ϱ (G \ s).
Proof.
  destruct SEP as [GT LE].
  intros Gt. intros In InMap.
  eapply map_iff in InMap; eauto.
  destruct InMap as [y [In' EQ]]. hnf in EQ; subst.
  decide (y <= c).
  - exploit LE; eauto. omega.
  - cset_tac.
Qed.

Lemma sep_update_list c ϱ lv Z
      (AL:forall x, x > c -> x ∈ of_list Z -> x ∈ map (findt ϱ 0) (lv \ of_list Z) -> False)
      (ND: NoDupA eq Z)
      (Card: crd c (map (findt ϱ 0) (lv \ of_list Z)) Z)
      (SEP:sep c (lv \ of_list Z) (findt ϱ 0))
  : sep c lv (findt (ϱ [-Z <-- fresh_list_P c (map (findt ϱ 0) (lv \ of_list Z)) Z -]) 0).
Proof.
  destruct SEP as [GT LE].
  eapply sep_agree.
  setoid_rewrite <- map_update_list_update_agree'; eauto with len.
  reflexivity.
  split; intros.
  - decide (x ∈ of_list Z).
    + edestruct update_with_list_lookup_in_list; try eapply i; dcr.
      Focus 2.
      rewrite H4. cset_tac.
      edestruct fresh_list_get; try eapply H3; inv_get; eauto.
      dcr. inv_get. exfalso; eauto.
      eauto with len.
    + rewrite lookup_set_update_not_in_Z; eauto.
      eapply GT; eauto with cset. cset_tac.
  - decide (x ∈ of_list Z).
    + edestruct update_with_list_lookup_in_list; try eapply i; dcr.
      Focus 2.
      rewrite H4. cset_tac.
      edestruct fresh_list_get; try eapply H3; inv_get; eauto.
      dcr. inv_get.
      eauto with len.
    + rewrite lookup_set_update_not_in_Z; eauto.
      eapply LE; eauto with cset. cset_tac.
Qed.

(** ** the algorithm produces a locally injective renaming *)

Require Import AnnP.
Definition bounded_below
           (c : nat)
           (k : nat)
  : ⦃nat⦄ -> Prop
  :=
    fun a => cardinal (filter (fun x => B[x <= c]) a) <= k.


Instance bounded_in_equal_morph
  : Proper (eq ==> eq ==> Equal ==> iff) bounded_below.
Proof.
  unfold Proper, respectful, bounded_below; intros; subst.
  rewrite H1. reflexivity.
Qed.

Instance bounded_in_subset_morph
  : Proper (eq ==> eq ==> Equal ==> impl) bounded_below.
Proof.
  unfold Proper, respectful, bounded_below, impl, flip; intros; subst.
  rewrite <- H1. rewrite <- H2. reflexivity.
Qed.


Instance bounded_in_equal_ptw
  : Proper (eq ==> eq ==> pointwise_relation _ iff) bounded_below.
Proof.
  unfold Proper, respectful, pointwise_relation; intros; subst.
  reflexivity.
Qed.

Instance bounded_in_impl_ptw'
  : Proper (eq ==> eq ==> pointwise_relation _ impl) bounded_below.
Proof.
  unfold Proper, respectful, pointwise_relation, impl, flip; intros; subst.
  eauto.
Qed.

Instance ann_P_impl A
  : Proper (@pointwise_relation _ _ impl ==> eq ==> impl) (@ann_P A).
Proof.
  unfold Proper, respectful, impl; intros; subst.
  general induction H1; eauto using ann_P.
Qed.

Instance ann_P_iff A
  : Proper (@pointwise_relation _ _ iff ==> eq ==> iff) (@ann_P A).
Proof.
  unfold Proper, respectful, impl; intros; subst; split; intros.
  eapply ann_P_impl; eauto.
  eapply pointwise_subrelation; eauto using iff_impl_subrelation.
  eapply ann_P_impl; eauto.
  eapply pointwise_subrelation; eauto using iff_impl_subrelation.
  eapply pointwise_symmetric; eauto using CRelationClasses.iff_Symmetric.
Qed.

Lemma filter_difference X `{OrderedType X} (p:X->bool) `{Proper _ (_eq ==> eq) p} s t
  : filter p (s \ t) [=] filter p s \ filter p t.
Proof.
  cset_tac. eapply H3; cset_tac.
Qed.

Lemma sep_filter_map_comm (c:var) lv (ϱ:var -> var)
  : sep c lv ϱ
    -> map ϱ (filter (fun x => B[x <= c]) lv) [=] filter (fun x => B[x <= c]) (map ϱ lv).
Proof.
  intros [GT LE]. cset_tac.
  - eexists x; cset_tac.
    exploit GT; eauto. cset_tac. omega.
Qed.

Lemma subset_filter X `{OrderedType X} (p:X->bool) `{Proper _ (_eq ==> eq) p} (lv lv':set X)
  : lv ⊆ lv'
    -> filter p lv ⊆ filter p lv'.
Proof.
  cset_tac.
Qed.

Lemma filter_get X (p:X->bool) (Z:list X) x n
  : get Z n x
    -> p x
    -> { n : nat | get (List.filter p Z) n x }.
Proof.
  intros. eapply get_getT in H.
  general induction H; simpl; cases; eauto using get.
  edestruct IHgetT; eauto using get.
Qed.

Lemma of_list_filter X `{OrderedType X} (p:X->bool) `{Proper _ (_eq ==> eq) p} L
  : of_list (List.filter p L) [=] filter p (of_list L).
Proof.
  cset_tac.
  - eapply of_list_get_first in H1; dcr; cset_tac; inv_get.
    rewrite H3. eapply get_in_of_list; eauto.
  - eapply of_list_get_first in H1; dcr; cset_tac; inv_get.
    rewrite H3. cset_tac.
  - eapply of_list_get_first in H2; dcr; cset_tac; inv_get.
    rewrite H4 in *.
    edestruct filter_get; eauto.
    eapply get_in_of_list; eauto.
Qed.


Lemma crd_of_list (c:var) k (LT:k < c) (lv:set var) Z ϱ
      (SEP:sep c (lv \ of_list Z) ϱ)
      (Card:cardinal (filter (fun x => B[x <= c]) lv) <= k)
      (Incl: of_list Z ⊆ lv)
  : crd c (map ϱ (lv \ of_list Z)) Z.
Proof.
  unfold crd. rewrite <- sep_filter_map_comm; eauto.
  rewrite cardinal_map; eauto.
  rewrite filter_difference; [|clear; intuition].
  rewrite cardinal_difference'.
  - unfold var in *.
    assert (cardinal (filter (fun x => B[x <= c]) lv) >=
            cardinal (filter (fun x => B[x <= c]) (of_list Z))). {
      eapply subset_cardinal. eapply subset_filter. clear; intuition. eauto.
    }
    unfold var in *. rewrite of_list_filter. omega. clear; intuition.
  - eapply subset_filter; eauto.
Qed.
Lemma regAssign_correct k c (LE:k < c) (ϱ:Map [var,var]) ZL Lv s alv ϱ' al
      (LS:live_sound FunctionalAndImperative ZL Lv s alv)
      (inj:injective_on (getAnn alv) (findt ϱ 0))
      (SEP:sep c (getAnn alv) (findt ϱ 0))
      (allocOK:regAssign c s alv ϱ = Success ϱ')
      (incl:getAnn alv ⊆ fst (getAnn al))
      (sd:renamedApart s al)
      (BND:ann_P (bounded_below c k) alv)
: locally_inj (findt ϱ' 0) s alv.
Proof.
  intros.
  general induction LS; simpl in *; try monadS_inv allocOK; invt renamedApart; invt ann_P;
    pe_rewrite; simpl in *.
  - exploit IHLS; try eapply allocOK; pe_rewrite; eauto with cset.
    + eapply injective_on_agree; [| eapply map_update_update_agree].
      eapply injective_on_incl.
      eapply injective_on_fresh; eauto using injective_on_incl.
      eapply least_fresh_P_spec; eauto.
      eapply sep_lookup_set; eauto.
      eauto with cset.
    + eapply sep_update; eauto.
      hnf in H4. rewrite <- sep_filter_map_comm; eauto.
      rewrite cardinal_map; eauto.
      rewrite H0. unfold var in *. omega.
    + pe_rewrite. eauto with cset.
    + exploit regAssign_renamedApart_agree;
      try eapply allocOK; simpl; eauto using live_sound.
      rewrite H9 in *; simpl in *.
      econstructor; eauto using injective_on_incl.
      * eapply injective_on_agree; try eapply inj.
        eapply agree_on_incl.
        eapply agree_on_update_inv.
        rewrite map_update_update_agree; eauto.
        pe_rewrite.
        revert H5 incl; clear_all; cset_tac; intuition.
  - exploit regAssign_renamedApart_agree;
    try eapply EQ; simpl; eauto using live_sound.
    exploit regAssign_renamedApart_agree;
      try eapply EQ0; simpl; eauto using live_sound.
    pe_rewrite.
    simpl in *.
    exploit IHLS1; try eapply EQ; eauto using injective_on_incl.
    rewrite H11; simpl. rewrite <- incl; eauto.
    exploit IHLS2; try eapply EQ0; eauto using injective_on_incl.
    eapply injective_on_incl; eauto.
    eapply injective_on_agree; eauto using agree_on_incl.
    eapply sep_agree; eauto using agree_on_incl.
    rewrite H12; simpl. rewrite <- incl; eauto.
    econstructor; eauto.
    assert (agree_on eq D (findt ϱ 0) (findt ϱ' 0)). etransitivity; eauto.
    eapply injective_on_agree; eauto. eauto using agree_on_incl.
    eapply locally_inj_live_agree. eauto. eauto. eauto.
    rewrite H11; simpl; eauto.
    exploit regAssign_renamedApart_agree'; try eapply EQ0; simpl; eauto using live_sound.
    pe_rewrite.
    eapply agree_on_incl. eauto. instantiate (1:=D ∪ Ds).
    pose proof (renamedApart_disj H9).
    pe_rewrite.
    revert H6 H17; clear_all; cset_tac; intuition; eauto.
    pe_rewrite. rewrite <- incl; eauto.
  - econstructor; eauto.
  - econstructor; eauto.

  - exploit regAssign_renamedApart_agreeF;
    eauto using regAssign_renamedApart_agree'. reflexivity.
    exploit regAssign_renamedApart_agree;
      try eapply EQ0; simpl; eauto using live_sound.
    instantiate (1:=D) in H4.
    assert (AGR:agree_on _eq lv (findt ϱ 0) (findt x 0)). {
      eapply agree_on_incl; eauto.
      rewrite disj_minus_eq; eauto. simpl in *.
      symmetry. rewrite <- list_union_disjunct.
      intros; inv_get. edestruct H8; eauto; dcr.
      unfold defVars. symmetry. eapply disj_app; split; eauto.
      symmetry; eauto.
      exploit H7; eauto. eapply renamedApart_disj in H20.
      eapply disj_1_incl; eauto. rewrite H19. eauto with cset.
    }
    exploit (IHLS k c); try eapply EQ0; eauto.
    + eapply injective_on_incl; eauto.
      eapply injective_on_agree; eauto.
    + pe_rewrite. etransitivity; eauto.
    + assert (DDISJ:forall n  DD' Zs, get F n Zs -> get ans n DD' ->
                              disj D (defVars Zs DD')).
      {
        eapply renamedApart_disj in sd. eauto using defVars_disj_D.
      }

      econstructor; eauto.
      * {
          intros. edestruct get_length_eq; try eapply H6; eauto.
          edestruct (regAssignF_get c (fst (getAnn x0) ∪ snd (getAnn x0) ∪ getAnn alv)); eauto; dcr.
          rewrite <- map_update_list_update_agree in H24; eauto.
          exploit (H1 _ _ _ H17 H18 k c); try eapply H19; eauto.
          - assert (getAnn alv \ of_list (fst Zs) ∪ of_list (fst Zs) [=] getAnn alv).
            edestruct H2; eauto.
            revert H20; clear_all; cset_tac; intuition.
            eapply injective_on_agree.
            Focus 2.
            eapply agree_on_incl.
            eauto. rewrite <- incl_right.
            rewrite disj_minus_eq; eauto.
            eapply renamedApart_disj in sd.
            simpl in *.
            rewrite <- H20. symmetry. rewrite disj_app. split; symmetry.
            eapply disj_1_incl. eapply disj_2_incl. eapply sd.
            rewrite <- H13. eapply incl_union_left.
            hnf; intros ? A. eapply list_union_get in A. destruct A. dcr.
            inv_get.
            eapply incl_list_union; eauto using zip_get.
            reflexivity. cset_tac.
            edestruct H2; eauto; dcr. rewrite <- incl. eauto.
            eapply disj_1_incl.
            eapply defVars_take_disj; eauto. unfold defVars.
            eauto with cset.
            setoid_rewrite <- H20 at 1.
            eapply injective_on_fresh_list; eauto with len.
            eapply injective_on_incl; eauto.
            eapply H2; eauto.
            eapply disj_intersection.
            eapply disj_2_incl. eapply fresh_list_P_spec.
            eapply sep_nd; eauto.
            edestruct H2; eauto. clear; hnf; intros; cset_tac.
            edestruct H8; eauto.
            edestruct H2; eauto; dcr.
            exploit H15; eauto. eapply ann_P_get in H26. hnf in H26.
            eapply crd_of_list; eauto.
            reflexivity.
            edestruct H8; eauto.
            eapply fresh_list_nodup; eauto.
            eapply sep_nd; eauto.
            edestruct H2; eauto. clear; hnf; intros; cset_tac.
            edestruct H8; eauto.
            edestruct H2; eauto; dcr.
            eapply crd_of_list; eauto.
            exploit H15; eauto. eapply ann_P_get in H26. eauto.
          - edestruct H2; eauto.
            rewrite map_update_list_update_agree' in H24; eauto with len.
            eapply sep_agree.
            eapply agree_on_incl; eauto.
            edestruct H8; eauto; dcr. rewrite H25. rewrite <- incl. rewrite <- H23.
            eapply not_incl_minus. clear; cset_tac.
            assert (getAnn alv [=] of_list (fst Zs) ∪ getAnn alv \ of_list (fst Zs)). {
              revert H20; clear; cset_tac.
            }
            rewrite H26. symmetry; eapply disj_app; split.
            symmetry. eapply disj_1_incl.
            eapply defVars_take_disj; eauto. unfold defVars. cset_tac.
            symmetry.

            eapply disj_1_incl. eapply D_take_disj; eauto.
            rewrite <- incl, <- H23. eauto.
            edestruct H8; eauto; dcr.
            eapply sep_update_list; eauto.
            intros ? ? ?.
            eapply sep_lookup_list; eauto using sep_incl.
            edestruct H2; eauto; dcr.
            eapply crd_of_list; eauto.
            exploit H15; eauto. eapply ann_P_get in H31. eauto.
          - edestruct H8; eauto; dcr. rewrite H20.
            exploit H2; eauto; dcr. rewrite incl in H29; simpl in *.
            rewrite <- H29. clear_all; cset_tac; intuition.
          - eapply locally_inj_live_agree; try eapply H20; eauto.
            eapply regAssign_renamedApart_agreeF in H21;
              eauto using get_drop, drop_length_stable; try reflexivity.
            + eapply regAssign_renamedApart_agree' in EQ0; simpl; eauto using live_sound.
              etransitivity; eapply agree_on_incl; try eassumption.
              * rewrite disj_minus_eq. reflexivity.
                {
                  edestruct H8; eauto; dcr. rewrite H23.
                  rewrite union_comm. rewrite <- union_assoc.
                  symmetry; rewrite disj_app; split; symmetry.
                  - eapply disj_1_incl. eapply defVars_drop_disj; eauto.
                    unfold defVars. eauto with cset.
                  - eapply renamedApart_disj in sd; simpl in sd.
                    eapply disj_2_incl; eauto.
                    rewrite <- H13. eapply incl_union_left.
                    rewrite <- drop_zip; eauto.
                    eapply list_union_drop_incl; eauto.
                }
              * pe_rewrite.
                rewrite disj_minus_eq. reflexivity.
                {
                  edestruct H8; eauto; dcr. rewrite H23.
                  rewrite union_comm. rewrite <- union_assoc.
                  symmetry; rewrite disj_app; split; symmetry.
                  rewrite union_comm; eauto.
                  eapply renamedApart_disj in H10. pe_rewrite. eapply H10.
                }
            + intros.
              eapply regAssign_renamedApart_agree'; eauto using get_drop, drop_get.
            + intros. edestruct H8; eauto; dcr. rewrite H23.
              exploit H2; eauto; dcr. rewrite incl in H30. simpl in *.
              revert H30; clear_all; cset_tac; intuition.
              decide (a ∈ of_list (fst Zs)); intuition.
          - eauto with len.
        }
      * eapply injective_on_agree; try eapply inj; eauto.
        etransitivity; eapply agree_on_incl; eauto. pe_rewrite. eauto.
Qed.


Require Import Restrict RenamedApart_Liveness LabelsDefined.

(** ** Theorem 8 from the paper. *)
(** One could prove this theorem directly by induction, however, we exploit that
    under the assumption of the theorem, the liveness information [alv] is also
    sound for functional liveness and we can thus rely on theorem [regAssign_correct]
    above, which we did prove by induction. *)

Lemma regAssign_correct' k c (LE:k < c) s ang ϱ ϱ' (alv:ann (set var)) ZL Lv
  : renamedApart s ang
  -> live_sound Imperative ZL Lv s alv
  -> bounded (Some ⊝ Lv \\ ZL) (fst (getAnn ang))
  -> ann_R Subset1 alv ang
  -> noUnreachableCode isCalled s
  -> injective_on (getAnn alv) (findt ϱ 0)
  -> regAssign c s alv ϱ = Success ϱ'
  -> sep c (getAnn alv) (findt ϱ 0)
  -> ann_P (bounded_below c k) alv
  -> locally_inj (findt ϱ' 0) s alv.
Proof.
  intros.
  eapply renamedApart_live_imperative_is_functional in H0; eauto using bounded_disjoint, renamedApart_disj, meet1_Subset1, live_sound_annotation, renamedApart_annotation.
  eapply regAssign_correct; eauto using locally_inj_subset, meet1_Subset, live_sound_annotation, renamedApart_annotation.
  eapply ann_R_get in H2. destruct (getAnn ang); simpl; cset_tac.
Qed.