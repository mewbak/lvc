Require Import List Map Env AllInRel Exp AppExpFree RenamedApart.
Require Import IL Annotation InRel AutoIndTac.
Require Import Liveness LabelsDefined.
Require Import Spilling DoSpill DoSpillRm SpillUtil ReconstrLive AnnP InVD SetUtil.



Lemma reconstr_live_G_eq
      (G : ⦃var⦄)
      (Lv : list ⦃var⦄)
      (ZL : list params)
      (s : stmt)
      (a : lvness_fragment)
  :
    getAnn (reconstr_live Lv ZL G s a)
           [=]
           getAnn (reconstr_live Lv ZL ∅ s a) ∪ G
.
Proof.
  general induction s;
    destruct a;
    try destruct a;
    simpl; eauto; cset_tac.
Qed.



(* remove ? *)
Lemma reconstr_live_remove_G
      Lv ZL G s sl G'
  :
    getAnn (reconstr_live Lv ZL G s sl) \ G
           ⊆ getAnn (reconstr_live Lv ZL G' s sl)
.
Proof.
  destruct s, sl, a; simpl; cset_tac.
Qed.




Lemma reconstr_live_G
      (Lv : list (set var))
      (ZL : list (params))
      (G : set var)
      (s : stmt)
      (a : ann (option (list (set var))))
  :
    G ⊆ getAnn (reconstr_live Lv ZL G s a)
.
Proof.
  induction s,a; simpl; eauto with cset.
  - destruct a; simpl; eauto.
Qed.
