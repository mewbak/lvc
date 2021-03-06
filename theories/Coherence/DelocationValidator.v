Require Import AllInRel Util Map Envs Exp IL Annotation Coherence DecSolve.
Require Import Liveness.Liveness Restrict Delocation Indexwise.

Set Implicit Arguments.
Unset Printing Records.

Local Hint Extern 1 =>
match goal with
  [ H : annotation _ _ |- annotation _ _ ] => inv H; eassumption
end.

Lemma trs_dec DL s ans_lv ans
  : {trs DL s ans_lv ans} +
    {~ trs DL s ans_lv ans}.
Proof.
  revert DL ans_lv ans.
  sind s.
  time (destruct s; destruct ans; try solve [dec_right]; destruct ans_lv; try solve [dec_right]).
  + destruct a; [ | dec_right];
      destruct (IH s (ltac:(eauto))
                   (restr (getAnn ans_lv \ singleton x) ⊝  DL) ans_lv ans);
      [| dec_right].
    dec_solve.
  + destruct a; [| dec_right];
    destruct (IH s1 (ltac:(eauto)) DL ans_lv1 ans1); [| dec_right];
    destruct (IH s2 (ltac:(eauto)) DL ans_lv2 ans2); [| dec_right].
    dec_solve.
  + destruct (get_dec DL (counted l)) as [[[G'|]]|];[| dec_right | dec_right];
      destruct a; [| dec_right];
        dec_solve.
  + destruct a;[| dec_right].
    dec_solve.
  + ensure (length F = length a);
    ensure (length F = length sa);
    ensure(length F = length sa0).
    destruct (IH s (ltac:(eauto)) (Some ⊝ (getAnn ⊝ sa0) \\ app (A:=var) ⊜ (fst ⊝ F) a ++ DL)
                 ans_lv ans);[| dec_right].
    edestruct (indexwise_R4_dec
                 (R:=fun lvs Zs Za' ans' =>
                       trs (restr (getAnn lvs \ of_list (fst Zs ++ Za'))
                                     ⊝ (Some ⊝ (getAnn ⊝ sa0) \\ app (A:=var) ⊜ (fst ⊝ F) a ++ DL))
                           (snd Zs) lvs ans')
                 (LA:=sa0)
                 (LB:=F)
                 (LC:=a)
                 (LD:=sa)); intros; eauto.
    hnf; intros. eapply IH; eauto.
    dec_solve. dec_right.
Defined.

Instance trs_dec_inst DL s lv Y
: Computable (trs DL s lv Y).
Proof.
  hnf; eauto using trs_dec.
Defined.
