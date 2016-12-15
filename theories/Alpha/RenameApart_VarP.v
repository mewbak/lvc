Require Import Util CSet Var.
Require Import StableFresh.
Require Import IL RenameApart.

Inductive var_P (P:var -> Prop)
  : stmt -> Prop :=
| VarPOpr x b e
  :  var_P P b
     -> P x
     -> For_all P (Exp.freeVars e)
     -> var_P P (stmtLet x e b)
| VarPIf e b1 b2
  :  For_all P (Op.freeVars e)
     -> var_P P b1
     -> var_P P b2
     -> var_P P (stmtIf e b1 b2)
| VarPGoto l Y
  : For_all P (list_union (Op.freeVars ⊝ Y))
    -> var_P P (stmtApp l Y)
| VarPReturn e
  : For_all P (Op.freeVars e)
    -> var_P P (stmtReturn e)
| VarPLet F b
  : (forall n Zs, get F n Zs -> var_P P (snd Zs))
    -> (forall n Zs, get F n Zs -> For_all P (of_list (fst Zs)))
    -> var_P P b
    -> var_P P (stmtFun F b).


Instance For_all_P_Equal X `{OrderedType X} (P:X->Prop) `{Proper _ (_eq ==> iff) P}
  : Proper (Equal ==> iff) (For_all P).
Proof.
  unfold Proper, respectful, For_all; split; intros; eapply H2; cset_tac.
Qed.

Instance For_all_P_Subset X `{OrderedType X} (P:X->Prop) `{Proper _ (_eq ==> iff) P}
  : Proper (Subset ==> flip impl) (For_all P).
Proof.
  unfold Proper, respectful, For_all, flip, impl; intros; eapply H2; eauto.
Qed.

Lemma renameApart_var_P (fresh:StableFresh) (P:var -> Prop) (ϱ:env var) G s
      (freshP:forall x G, P (fresh G x))
      (ren:forall x, x ∈ freeVars s -> P (ϱ x))
  : var_P P (snd (renameApart' fresh ϱ G s)).
Proof.
  revert ϱ G ren.
  sind s; intros; destruct s; simpl;
    repeat let_pair_case_eq; repeat simpl_pair_eqs; subst; simpl in *.
  - econstructor; eauto.
    + eapply IH; eauto.
      intros; lud; eauto. eapply ren. cset_tac.
    + rewrite freeVars_renameExp. unfold lookup_set.
      hnf; intros. cset_tac.
  - econstructor; eauto.
    + rewrite rename_op_freeVars; eauto. unfold lookup_set.
      hnf; intros. cset_tac.
    + eapply IH; eauto. cset_tac.
    + eapply IH; eauto. cset_tac.
  - econstructor.
    rewrite freeVars_rename_op_list. unfold lookup_set.
    hnf; intros. cset_tac.
  - econstructor.
    rewrite rename_op_freeVars; eauto. unfold lookup_set.
    hnf; intros. cset_tac.
  - econstructor; eauto.
    + intros. inv_get.
      edestruct get_fst_renameApartF as [? [? ?]]; eauto; dcr; subst.
      destruct Zs as [Z s']; simpl in *; subst.
      eapply IH; eauto.
      intros. decide (x ∈ of_list (fst x0)).
      * edestruct update_with_list_lookup_in_list; try eapply i; dcr.
        Focus 2.
        rewrite H11.
        exploit fresh_list_stable_get; try eapply H10; eauto; dcr.
        subst. get_functional. eapply freshP; eauto.
        eauto with len.
      * rewrite lookup_set_update_not_in_Z; eauto.
        eapply ren.
        eapply incl_left.
        eapply incl_list_union; [| reflexivity|]; eauto.
        cset_tac.
    + intros.
      intros. inv_get.
      edestruct get_fst_renameApartF as [? [? ?]]; eauto; dcr; subst.
      destruct Zs as [Z s']; simpl in *; subst.
      hnf; intros.
      eapply fresh_list_stable_In in H0; dcr; subst.
      eapply freshP.
    + eapply IH; eauto.
      cset_tac.
Qed.