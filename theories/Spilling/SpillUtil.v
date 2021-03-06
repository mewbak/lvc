Require Import List Map CSet Envs AllInRel Exp AppExpFree.
Require Import IL Annotation AutoIndTac Liveness.Liveness LabelsDefined.

Notation "'spilling'"
  := (ann (⦃var⦄ * ⦃var⦄ * list (⦃var⦄ * ⦃var⦄))).

Notation "'getSp' sl" := (fst (fst (getAnn sl))) (at level 40).
Notation "'getL' sl" := (snd (fst (getAnn sl))) (at level 40).

Notation "'getRm' sl" := (snd (getAnn sl)) (at level 40, only parsing).


(** * SpillUtil *)

(* move somewhere *)
Lemma tl_list_incl (X : Type) `{OrderedType X} (L : list X)
  : of_list (tl L) ⊆ of_list L.
Proof.
  general induction L; simpl; eauto with cset.
Qed.

Lemma tl_set_incl (X : Type) `{OrderedType X} (s : set X)
  : of_list (tl (elements s)) ⊆ s .
Proof.
  rewrite tl_list_incl.
  hnf. intros. eapply elements_iff. cset_tac.
Qed.

Definition sub_spill (sl' sl : spilling) :=
    sl' = setTopAnn sl (getAnn sl') (*Note that rm=rm' *)
    /\ fst (fst (getAnn sl')) ⊆ fst (fst (getAnn sl))
    /\ snd (fst (getAnn sl')) ⊆ snd (fst (getAnn sl))
    /\ snd (getAnn sl') = snd (getAnn sl).


Function count (sl : spilling)
  := cardinal (fst (fst (getAnn sl))) + cardinal (snd (fst (getAnn sl))).

(* TODO move somewhere *)
Lemma get_get_eq (X : Type) (L : list X) (n : nat) (x x' : X)
  : get L n x -> get L n x' -> x = x' .
Proof.
  intros get_x get_x'.
  induction get_x; inversion get_x'.
  - reflexivity.
  - apply IHget_x. assumption.
Qed.

Lemma sub_spill_refl sl
  : sub_spill sl sl .
Proof.
  unfold sub_spill.
  repeat split.
    simpl; eauto.
  - unfold setTopAnn.
    destruct sl; destruct a; destruct p;
      simpl; reflexivity.
  - reflexivity.
  - reflexivity.
Qed.

Lemma of_list_tl_hd (L : list var)
  : L <> nil
    ->  of_list L [=] of_list (tl L) ∪ singleton (hd default_var L) .
Proof.
  intro N.
  induction L; simpl; eauto.
  - isabsurd.
  - cset_tac.
Qed.

Lemma tl_hd_set_incl (s t : ⦃var⦄)
  : s \ of_list (tl (elements t)) ⊆ s \ t ∪ singleton (hd default_var (elements t)) .
Proof.
  hnf.
  intros a H.
  apply diff_iff in H.
  destruct H as [in_s not_in_tl_t].
  apply union_iff.
  decide (a ∈ t).
  - right.
    rewrite <- of_list_elements in i.
    rewrite of_list_tl_hd in i.
    + apply union_iff in i.
      destruct i.
      * contradiction.
      * eauto.
    + intro N.
      apply elements_nil_eset in N.
      rewrite of_list_elements in i.
      rewrite N in i.
      isabsurd.
  - left.
    cset_tac.
Qed.

Lemma nth_zip (X Y Z : Type) (L : list X) (L': list Y)
      (x : X) (x' : Y) (d : Z) (f : X -> Y -> Z) n
  : get L n x
    -> get L' n x'
    -> nth n (f ⊜ L L') d = f x x'.
Proof.
  intros get_x get_x'.
  general induction n;
    simpl; eauto; isabsurd;
      inv get_x;
      inv get_x'.
  - simpl. apply IHn; eauto.
Qed.

Lemma count_zero_Empty_Sp (sl : spilling)
  : count sl = 0 -> Empty (getSp sl) .
Proof.
  intro count_zero.
  apply cardinal_Empty.
  unfold count in count_zero.
  omega.
Qed.

Lemma count_zero_cardinal_Sp (sl : spilling)
  : count sl = 0
    -> cardinal (getSp sl) = 0 .
Proof.
  intro count_zero.
  unfold count in count_zero.
  omega.
Qed.

Lemma count_zero_cardinal_L (sl : spilling)
  : count sl = 0
    -> cardinal (getL sl) = 0 .
Proof.
  intro count_zero.
  unfold count in count_zero.
  omega.
Qed.

Lemma count_zero_Empty_L (sl : spilling)
  : count sl = 0 -> Empty (getL sl) .
Proof.
  intro count_zero.
  apply cardinal_Empty.
  unfold count in count_zero.
  omega.
Qed.

Lemma Empty_Sp_L_count_zero (sl : spilling)
  : Empty (getSp sl)
    -> Empty (getL sl)
    -> count sl = 0 .
Proof.
  intros Empty_Sp Empty_L.
  apply cardinal_Empty in Empty_Sp.
  apply cardinal_Empty in Empty_L.
  unfold count.
  omega.
Qed.

Definition clear_L (sl : spilling)
  := setTopAnn sl (getSp sl, ∅, getRm sl) .

Lemma count_clearL (sl : spilling)
  : count (clear_L sl) = cardinal (getSp sl) .
Proof.
  unfold count.
  unfold clear_L.
  rewrite getAnn_setTopAnn.
  simpl.
  rewrite empty_cardinal.
  omega.
Qed.

Definition merge (RM : set var * set var) :=
  fst RM ∪ snd RM.

Lemma getAnn_als_EQ_merge_rms
      (Lv : 〔⦃var⦄〕)
      (als : 〔ann ⦃var⦄〕)
      (Λ : 〔⦃var⦄ * ⦃var⦄〕)
      (pir2 : PIR2 Equal (merge ⊝ Λ) Lv)
      (rms : 〔⦃var⦄ * ⦃var⦄〕)
      (H23 : PIR2 Equal (merge ⊝ rms) (getAnn ⊝ als))
  :
    PIR2 Equal (merge ⊝ (rms ++ Λ)) (getAnn ⊝ als ++ Lv)
.
Proof.
  rewrite List.map_app. apply PIR2_app; eauto.
Qed.

Lemma al_sub_RfMf
      (als : list (ann ⦃var⦄))
      (rms : list (⦃var⦄ * ⦃var⦄))
      (al : ann ⦃var⦄)
      (R M : ⦃var⦄)
      (n : nat)
  : get rms n (R,M)
    -> get als n al
    -> PIR2 Equal (merge ⊝ rms) (getAnn ⊝ als)
    -> getAnn al ⊆ R ∪ M.
Proof.
  intros get_rm get_al H16.
  general induction get_rm;
    try invc get_al; invc H16;
      unfold merge in *; simpl in *; eauto.
  rewrite pf; eauto.
Qed.

Lemma al_eq_RfMf

      (als : list (ann ⦃var⦄))
      (rms : list (⦃var⦄ * ⦃var⦄))
      (al : ann ⦃var⦄)
      (R M : ⦃var⦄)
      (n : nat)
  : get rms n (R,M)
    -> get als n al
    -> merge ⊝ rms = getAnn ⊝ als
    -> getAnn al [=] R ∪ M .
Proof.
  intros get_rm get_al H16.
  general induction get_rm;
    try invc get_al; invc H16;
      simpl in *; eauto.
Qed.


Definition slot_merge
           (slot : var -> var)
           (RM : set var * set var)
  := fst RM ∪ map slot (snd RM).


Lemma slot_merge_app
      (L1 L2: list (set var * set var))
      (slot : var -> var)
  :
    slot_merge slot ⊝ L1 ++ slot_merge slot ⊝ L2
      = slot_merge slot ⊝ (L1 ++ L2)
.
Proof.
  intros.
  unfold slot_merge.
  rewrite List.map_app; eauto.
Qed.

Lemma nth_rfmf
      (l : lab)
      (Λ : 〔⦃var⦄ * ⦃var⦄〕)
      (slot : var -> var)
      (R_f M_f : ⦃var⦄)
      (H15 : get Λ (counted l) (R_f, M_f))
  : nth (counted l) (slot_merge slot ⊝ Λ) ∅ [=] R_f ∪ map slot M_f .
Proof.
  eapply get_nth with (d:=(∅,∅)) in H15 as H15'.
  simpl in H15'.
  assert ((fun RM
           => fst RM ∪ map slot (snd RM)) (nth l Λ (∅,∅))
          = (fun RM
             => fst RM ∪ map slot (snd RM)) (R_f,M_f))
    as H_sms. {
    f_equal; simpl; [ | f_equal];
      rewrite H15'; simpl; eauto.
  }
  unfold slot_merge.
  rewrite <- map_nth in H_sms.
  simpl in H_sms.
  assert (l < length ((fun RM : ⦃var⦄ * ⦃var⦄
                       => fst RM ∪ map slot (snd RM)) ⊝ Λ))
    as l_len. {
    apply get_length in H15.
    clear - H15; eauto with len.
  }
  assert (nth l ((fun RM : ⦃var⦄ * ⦃var⦄
                  => fst RM ∪ map slot (snd RM)) ⊝ Λ) ∅
          = R_f ∪ map slot M_f)
    as H_sms'. {
    rewrite nth_indep with (d':=∅ ∪ map slot ∅).
    * exact H_sms.
    * eauto with len.
  }
  simpl.
  rewrite H_sms'.
  reflexivity.
Qed.



(* the following lemmata & definitions could be extracted *)
Definition clear_SpL (sl : spilling) := setTopAnn sl (∅,∅,snd (getAnn sl)).


Definition reduce_Sp (sl : spilling) :=
  setTopAnn sl (of_list (tl (elements (getSp sl))), getL sl, snd (getAnn sl)).


Definition reduce_L (sl : spilling) :=
    setTopAnn sl (getSp sl, of_list (tl (elements (getL sl))), snd (getAnn sl)).

Lemma count_clear_zero (sl : spilling)
  : count (clear_SpL sl) = 0.
Proof.
  unfold count.
  unfold clear_SpL.
  rewrite getAnn_setTopAnn.
  simpl.
  apply empty_cardinal.
Qed.

Definition clear_Sp (sl : spilling) :=
    setTopAnn sl (∅,getL sl,getRm sl).

Lemma count_clearSp (sl : spilling)
  : count (clear_Sp sl) = cardinal (getL sl).
Proof.
  unfold count.
  unfold clear_Sp.
  rewrite getAnn_setTopAnn.
  simpl.
  rewrite empty_cardinal.
  reflexivity.
Qed.

Lemma getSp_clearSp (sl : spilling)
  : getSp clear_Sp sl = ∅.
Proof.
  unfold clear_Sp.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma getL_clearSp (sl : spilling)
  : getL clear_Sp sl = getL sl.
Proof.
  unfold clear_Sp.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma getSp_clear (sl : spilling)
  : getSp clear_SpL sl = ∅.
Proof.
  unfold clear_SpL.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma getL_clear (sl : spilling)
  : getL clear_SpL sl = ∅.
Proof.
  unfold clear_SpL.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma getRm_clear (sl : spilling)
  : getRm clear_SpL sl = getRm sl.
Proof.
  unfold clear_SpL.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma getRm_clearSp (sl : spilling)
  : getRm clear_Sp sl = getRm sl.
Proof.
  unfold clear_Sp.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Definition setSp (sl : spilling) (Sp : ⦃var⦄) : spilling :=
    setTopAnn sl (Sp,getL sl,getRm sl) .

Lemma clear_clearSp (sl : spilling)
  : clear_SpL (clear_Sp sl) = clear_SpL sl.
Proof.
  unfold clear_SpL.
  unfold clear_Sp.
  rewrite setTopAnn_setTopAnn.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma clearSp_clearSp (sl : spilling)
  : clear_Sp (clear_Sp sl) = clear_Sp sl.
Proof.
  unfold clear_Sp.
  rewrite getAnn_setTopAnn.
  rewrite setTopAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.

Lemma setSp_getSp (sl : spilling)
  : setSp sl (getSp sl) = sl.
Proof.
  unfold setSp.
  unfold setTopAnn.
  destruct sl;
    destruct a;
    destruct p;
    simpl;
    reflexivity.
Qed.

Lemma getSp_setSp (sl : spilling) (Sp : ⦃var⦄)
  : getSp (setSp sl Sp) = Sp.
Proof.
  unfold setSp.
  rewrite getAnn_setTopAnn.
  simpl.
  reflexivity.
Qed.
