Require Import Util CSet IL Annotation StableFresh InfinitePartition VarP.
Require Import RenameApart RenamedApartAnn RenameApart_VarP FreshGen Range Setoid.

Set Implicit Arguments.

Definition rename_apart_to_part {Fi} (FG:FreshGen Fi) (FGS:FreshGenSpec FG) (s:stmt) :=
  let xlfi := (fresh_list FG (empty_domain FG) (to_list (freeVars s))) in
  let s' := (renameApart' FG (snd xlfi)
                       (id [to_list (freeVars s) <-- fst xlfi])
                       s) in
  (snd s', renamedApartAnn (snd s') (of_list (fst xlfi))).

Opaque to_list.

Lemma rename_apart_to_part_renamedApart {Fi} (FG:FreshGen Fi) (FGS:FreshGenSpec FG) s
  : RenamedApart.renamedApart (fst (rename_apart_to_part FGS s))
                              (snd (rename_apart_to_part FGS s)).
Proof.
  unfold rename_apart_to_part. simpl.
  eapply renameApart'_renamedApart; eauto.
  - rewrite update_with_list_lookup_set_incl; eauto with len.
    rewrite fresh_list_len; eauto.
    rewrite of_list_3; eauto.
  - rewrite <- fresh_list_domain_spec; eauto with cset.
Qed.


Lemma rename_apart_to_part_occurVars {Fi} (FG:FreshGen Fi) (FGS:FreshGenSpec FG) s
  : fst (getAnn (snd (rename_apart_to_part FGS s)))
        ∪ snd (getAnn (snd (rename_apart_to_part FGS s)))
        [=] occurVars (fst (rename_apart_to_part FGS s)).
Proof.
  unfold rename_apart_to_part; simpl.
  rewrite occurVars_freeVars_definedVars.
  rewrite snd_renamedApartAnn.
  eapply eq_union_lr; eauto.
  rewrite fst_renamedApartAnn.
  rewrite freeVars_renamedApart'; eauto.
  - rewrite update_with_list_lookup_list_eq; eauto with len.
    + rewrite fresh_list_len; eauto.
    + eapply nodup_to_list_eq.
    + rewrite of_list_3; eauto.
  - rewrite update_with_list_lookup_list_eq; eauto with len.
    + rewrite <- fresh_list_domain_spec; eauto.
    + rewrite fresh_list_len; eauto.
    + eapply nodup_to_list_eq.
    + rewrite of_list_3; eauto.
Qed.

Lemma FG_even_fast_inf_subset fi x
  :  even_inf_subset (fst (FG_even_fast fi x)).
Proof.
  hnf. simpl. destruct fi; simpl. cases; eauto.
Qed.

Lemma even_fast_list_even fi
  :  forall Z x, x \In of_list (fst (fresh_list FG_even_fast fi Z)) ->
            even_inf_subset x.
Proof.
  intros.
  unfold fresh_list in H. simpl in *.
  eapply of_list_map in H; eauto. cset_tac'.
  eapply of_list_map in H; eauto. cset_tac'.
  eapply in_range_x in H as [? ?]. destruct fi; simpl in *.
  eapply even_add; eauto. eapply even_mult2.
Qed.

Lemma rename_to_subset_even s
  : For_all (inf_subset_P even_inf_subset)
            (occurVars (fst (rename_apart_to_part FGS_even_fast s))).
Proof.
  eapply var_P_occurVars.
  eapply renameApart_var_P; eauto using FGS_even_fast.
  - intros. eapply FG_even_fast_inf_subset.
  - intros.
    eapply even_fast_list_even; eauto.
  - intros. rewrite <- of_list_3 in H.
    eapply (update_with_list_lookup_in_list id _ (fst (fresh_list FG_even_fast (empty_domain FG_even_fast) (to_list (freeVars s))))) in H; dcr.
    + rewrite H2.
      eapply even_fast_list_even.
      eapply get_in_of_list; eauto.
    + rewrite fresh_list_len; eauto using FGS_even_fast.
Qed.
