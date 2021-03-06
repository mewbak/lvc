Require Import Util LengthEq Map CSet AllInRel MoreList.
Require Import Var Val Exp Envs IL NaturalRep.
Require Import Sim SimTactics Infra.Status Position.

Set Implicit Arguments.

Inductive bstmt : Type :=
| bstmtLet    (e: exp) (s : bstmt)
| bstmtIf     (e : op) (s : bstmt) (t : bstmt)
| bstmtApp    (l : lab) (Y:args)
| bstmtReturn (e : op)
| bstmtFun    (F : list (nat * bstmt)) (t : bstmt).

Fixpoint op_eval (E:list val) (e:op) : option val :=
  match e with
    | Con v => Some v
    | Var x => nth_error E (asNat x)
    | UnOp o e => mdo v <- op_eval E e;
        unop_eval o v
    | BinOp o e1 e2 => mdo v1 <- op_eval E e1;
        mdo v2 <- op_eval E e2;
        binop_eval o v1 v2
  end.

(** *** Functional Semantics *)
Module F.

  Inductive block : Type :=
    blockI {
      block_E : list val;
      block_Z : nat;
      block_s : bstmt;
      block_n : nat
    }.

  Definition labenv := list block.
  Definition state : Type := (labenv * list val * bstmt)%type.

  Definition mkBlock E n f :=
    blockI E (fst f) (snd f) n.

  Inductive step : state -> event -> state -> Prop :=
  | stepExp L E e b v
    (def:op_eval E e = Some v)
    : step (L, E, bstmtLet (Operation e) b) EvtTau (L, v::E, b)

  | stepExtern L E f Y s vl v
    (def:omap (op_eval E) Y = Some vl)
    : step  (L, E, bstmtLet (Call f Y) s)
            (EvtExtern (ExternI f vl v))
            (L, v::E, s)

  | stepIfT L E
    e b1 b2 v
    (def:op_eval E e = Some v)
    (condTrue: val2bool v = true)
    : step (L, E, bstmtIf e b1 b2) EvtTau (L, E, b1)

  | stepIfF L E
    e b1 b2 v
    (def:op_eval E e = Some v)
    (condFalse: val2bool v = false)
    : step (L, E, bstmtIf e b1 b2) EvtTau (L, E, b2)

  | stepGoto L E l Y blk vl
    (Ldef:get L (counted l) blk)
    (len:block_Z blk = length Y)
    (def:omap (op_eval E) Y = Some vl) E'
    (updOk:(List.app vl  (block_E blk)) = E')
    : step  (L, E, bstmtApp l Y)
            EvtTau
            (drop (counted l - block_n blk) L, E', block_s blk)

  | stepLet L E
    F t
    : step (L, E, bstmtFun F t) EvtTau ((mapi (mkBlock E) F++L)%list, E, t).

  Lemma step_internally_deterministic
  : internally_deterministic step.
  Proof.
    hnf; intros.
    inv H; inv H0; split; eauto; try get_functional; try congruence.
  Qed.

  Lemma step_externally_determined
  : externally_determined step.
  Proof.
    hnf; intros.
    inv H; inv H0; eauto; try get_functional; try congruence.
  Qed.

  Lemma step_dec
  : reddec2 step.
  Proof.
    hnf; intros. destruct x as [[L V] []].
    - destruct e.
      + case_eq (op_eval V e); intros. left. do 2 eexists. eauto 20 using step.
        right. stuck.
      + case_eq (omap (op_eval V) Y); intros; try now (right; stuck).
        left; eexists (EvtExtern (ExternI f l default_val)). eexists; eauto using step.
    - case_eq (op_eval V e); intros.
      left. case_eq (val2bool v); intros; do 2 eexists; eauto using step.
      right. stuck.
    - destruct (get_dec L (counted l)) as [[blk A]|?].
      decide (block_Z blk = length Y).
      case_eq (omap (op_eval V) Y); intros; try now (right; stuck).
      + left. do 2 eexists. econstructor; eauto.
      + right. stuck2.
      + right. stuck2.
    - right. stuck2.
    - left. eexists. eauto using step.
  Qed.

End F.

Fixpoint exp_idx (symb:list var) (e:op) : status op :=
  match e with
    | Con v => Success (Con v)
    | Var x => sdo x <- option2status (pos symb x 0) "labIndices: Undeclared variable";
        Success (Var (ofNat x))
    | UnOp o e => sdo e <- exp_idx symb e;
        Success (UnOp o e)
    | BinOp o e1 e2 => sdo e1 <- exp_idx symb e1;
        sdo e2 <- exp_idx symb e2;
        Success (BinOp o e1 e2)
  end.

Fixpoint stmt_idx (symb: list var) (s:stmt) : status bstmt :=
  match s with
    | stmtLet x (Operation e) s =>
      sdo e <- exp_idx symb e;
        sdo s' <- (stmt_idx (x::symb) s); Success (bstmtLet (Operation e) s')
    | stmtLet x (Call f Y) s =>
      sdo Y <- smap (exp_idx symb) Y;
      sdo s' <- (stmt_idx (x::symb) s); Success (bstmtLet (Call f Y) s')
    | stmtIf e s1 s2 =>
      sdo e <- exp_idx symb e;
      sdo s1' <- (stmt_idx symb s1);
      sdo s2' <- (stmt_idx symb s2);
      Success (bstmtIf e s1' s2')
    | stmtApp l Y =>
      sdo Y <- smap (exp_idx symb) Y;
      Success (bstmtApp l Y)
    | stmtReturn e =>
      sdo e <- exp_idx symb e;
      Success (bstmtReturn e)
    | stmtFun F s2 =>
      sdo F' <- smap (fun sZ => sdo s <- stmt_idx (fst sZ ++ symb) (snd sZ); Success (length (fst sZ), s)) F;
      sdo s2' <- stmt_idx (symb) s2;
      Success (bstmtFun F' s2')
  end.

Definition state_result X (s:X*list val*bstmt) : option val :=
  match s with
    | (_, E, bstmtReturn e) => op_eval E e
    | _ => None
  end.

Instance statetype_F : StateType F.state := {
  step := F.step;
  result := (@state_result F.labenv);
  step_dec := F.step_dec;
  step_internally_deterministic := F.step_internally_deterministic;
  step_externally_determined := F.step_externally_determined
}.

Ltac single_step_ILDB :=
  match goal with
  | [ H : agree_on _ ?E ?E', I : val2bool (?E ?x) = true |- step (_, ?E', bstmtIf ?x _ _) _ ] =>
    econstructor; eauto; rewrite <- H; eauto; cset_tac; intuition
  | [ H : agree_on _ ?E ?E', I : val2bool (?E ?x) = false |- step (_, ?E', bstmtIf ?x _ _) _ ] =>
    econstructor 3; eauto; rewrite <- H; eauto; cset_tac; intuition
  | [ H : val2bool _ = false |- @StateType.step _ statetype_F _ _ _ ] =>
    econstructor 4; try eassumption; try reflexivity
  | [ H : val2bool _ = true |- @StateType.step _ statetype_F _ _ _ ] =>
    econstructor 3; try eassumption; try reflexivity
  | [ H : step (?L, _ , bstmtApp ?l _) _, H': get ?L (labN ?l) _ |- _] =>
    econstructor; try eapply H'; eauto
  | [ H': get ?F (labN ?l) _ |- @StateType.step _ _ (mapi _ ?F ++ _, _, bstmtApp ?l _) _ _] =>
    econstructor; [ try solve [simpl; eauto using get_app, get_mapi]
                  | simpl; eauto with len
                  | try eassumption; eauto; try reflexivity
                  | reflexivity]
  | [ |- @StateType.step _ _ (?L, _ , bstmtApp _ _) _ _] =>
    econstructor; [ try eassumption; try solve [simpl; eauto using get]
                  | simpl; eauto with len
                  | try eassumption; eauto; try reflexivity
                  | reflexivity]
  | [ |- @StateType.step _ _ (_, ?E, bstmtLet (Operation ?e) _) _ _] =>
    econstructor; eauto
  | [ |- @StateType.step _ _ (_, ?E, bstmtFun _ _) _ _] =>
    econstructor; eauto
  end.

Smpl Add single_step_ILDB : single_step.

Lemma exp_idx_ok E E' e e' (symb:list var)
      (Edef:forall x v, E x = Some v -> exists n, get symb n x)
      (Eagr:forall x n, pos symb x 0 = Some n -> exists v, get E' n v /\ E x = Some v)
      (EQ:exp_idx symb e = Success e')
: Ops.op_eval E e = op_eval E' e'.
Proof.
  general induction e; eauto; simpl in * |- *; try monadS_inv EQ.
  - eapply option2status_inv in EQ0. simpl.
    exploit Eagr; eauto. dcr.
    rewrite H2. erewrite get_nth_error; eauto.
    rewrite asNat_ofNat. eauto.
  - erewrite IHe; eauto. reflexivity.
  - erewrite IHe1; eauto. erewrite IHe2; eauto. reflexivity.
Qed.

Definition vars_exist (E:onv val) symb := forall x v, E x = Some v -> exists n, get symb n x.
Definition defs_agree symb (E:onv val) E' :=
  forall x n, pos symb x 0 = Some n -> exists v, get E' n v /\ E x = Some v.


Inductive approx : IL.F.block -> F.block -> Prop :=
| Approx E (Z:list var) s E' s' symb n :
    stmt_idx (Z ++ symb) s = Success s'
    -> vars_exist E symb
    -> defs_agree symb E E'
    -> approx (IL.F.blockI E Z s n) (F.blockI E' (length Z) s' n).

Inductive stmtIdxSim : IL.F.state -> F.state -> Prop :=
  | labIndicesSimI (L:IL.F.labenv) L' E E' s s' symb
    (EQ:stmt_idx symb s = Success s')
    (LA:PIR2 approx L L')
    (Edef:vars_exist E symb)
    (Eagr:defs_agree symb E E')
  : stmtIdxSim (L, E, s) (L', E', s').

Lemma vars_exist_update (E:onv val) symb x v
: vars_exist E symb
  -> vars_exist (E [x <- ⎣v ⎦]) (x :: symb).
Proof.
  unfold vars_exist; intros.
  lud. invc H1. eexists; eauto using get.
  edestruct H; eauto using get.
Qed.

Lemma vars_exist_update_list (E:onv val) symb Z vl
: length Z = length vl
  -> vars_exist E symb
  -> vars_exist (E [Z <-- List.map Some vl]) (Z ++ symb).
Proof.
  intros; length_equify.
  general induction H; simpl; eauto using vars_exist_update.
Qed.

Lemma defs_agree_update symb E E' x v
: defs_agree symb E E'
  -> defs_agree (x :: symb) (E [x <- ⎣v ⎦]) (v :: E').
Proof.
  unfold defs_agree; intros.
  simpl in H0. cases in H0.
  - invc COND.
    eexists; split; eauto using get. lud; congruence.
  - exploit (pos_ge _ _ _ H0).
    edestruct H; eauto; dcr.
    eapply pos_sub with (k':=1).
    orewrite (n = 1 + (n - 1)) in H0. eauto.
    eexists; split; eauto using get. lud; try congruence.
    orewrite (n = S (n -1)). econstructor; eauto.
    lud; eauto.
Qed.

Lemma defs_agree_update_list (E:onv val) E' symb Z vl
: length Z = length vl
  -> defs_agree symb E E'
  -> defs_agree (Z ++ symb) (E [Z <-- List.map Some vl]) (vl ++ E').
Proof.
  intros. length_equify.
  general induction H; simpl; eauto using defs_agree_update.
Qed.

Lemma stmt_idx_sim σ1 σ2
  : stmtIdxSim σ1 σ2 -> sim bot3 Bisim σ1 σ2.
Proof.
  revert σ1 σ2. pcofix stmt_idx_sim; intros.
  destruct H0; destruct s; simpl in *; try monadS_inv EQ.
  - destruct e; monadS_inv EQ.
    + case_eq (Ops.op_eval E e); intros.
      * pone_step. erewrite <- exp_idx_ok; eauto.
        right.
        eapply stmt_idx_sim; econstructor; eauto using vars_exist_update, defs_agree_update.
      * pno_step. erewrite <- exp_idx_ok in def; eauto. congruence.
    + case_eq (omap (Ops.op_eval E) Y); intros.
      assert (omap (op_eval E') x0 = ⎣l ⎦).
      erewrite omap_agree_2; try eapply H; eauto using smap_length.
      intros. exploit (smap_spec _ EQ0); eauto. dcr. get_functional; subst.
      erewrite exp_idx_ok; eauto.
      * pextern_step.
        -- eexists (ExternI f l default_val); eexists; try (now (econstructor; eauto)).
        -- assert (vl = l) by congruence; subst.
           eauto using vars_exist_update, defs_agree_update.
        -- right. apply stmt_idx_sim; econstructor; eauto using vars_exist_update, defs_agree_update.
        -- assert (vl = l) by congruence; subst.
           eauto using vars_exist_update, defs_agree_update.
        -- right. eapply stmt_idx_sim; econstructor; eauto using vars_exist_update, defs_agree_update.
      * pno_step.
        pose proof (smap_spec _ EQ0).
        assert (omap (Ops.op_eval E) Y = Some vl).
        erewrite omap_agree_2; eauto using smap_length.
        intros. eapply exp_idx_ok; eauto. edestruct H0; eauto; dcr.
        get_functional; subst; eauto. symmetry; eapply smap_length; eauto.
        congruence.
  - case_eq (Ops.op_eval E e); intros.
    * case_eq (val2bool v); intros; pone_step; eauto.
      erewrite <- exp_idx_ok; eauto.
      right. eapply stmt_idx_sim; econstructor; eauto.
      erewrite <- exp_idx_ok; eauto.
      right. eapply stmt_idx_sim; econstructor; eauto.
    * pno_step.
      erewrite <- exp_idx_ok in def; eauto. congruence.
      erewrite <- exp_idx_ok in def; eauto. congruence.
  - destruct (get_dec L (counted l)) as [[blk A]|?].
    edestruct PIR2_nth; eauto; dcr.
    decide (length (IL.F.block_Z blk) = length Y).
    case_eq (omap (Ops.op_eval E) Y); intros.
    + assert (omap (op_eval E') x = ⎣l0 ⎦).
      erewrite omap_agree_2; try eapply H; eauto using smap_length.
      intros. exploit (smap_spec _ EQ0); eauto. dcr. get_functional; subst.
      erewrite exp_idx_ok; eauto.
      pone_step; eauto. inv H1; eauto; simpl. exploit smap_length; eauto.
      simpl in *. congruence.
      inv H1; simpl in *.
      assert (length Z = length l0) by eauto with len.
      right. eapply stmt_idx_sim; econstructor;
      eauto using PIR2_drop, vars_exist_update_list, defs_agree_update_list.
    + pno_step.
      pose proof (smap_spec _ EQ0).
      assert (omap (Ops.op_eval E) Y = Some vl).
      erewrite omap_agree_2; eauto using smap_length.
      intros. eapply exp_idx_ok; eauto. edestruct H2; eauto; dcr.
      get_functional; subst; eauto. symmetry; eapply smap_length; eauto.
      congruence.
    + pno_step.
      invt approx; simpl in *; subst. exploit smap_length; eauto. congruence.
    + pno_step; eauto. edestruct PIR2_nth_2; eauto; dcr. eauto.
  - pno_step. simpl.
    erewrite <- exp_idx_ok; eauto.
  - pone_step. right. eapply stmt_idx_sim. econstructor; eauto.
    eapply PIR2_app; eauto.
    pose proof (smap_spec _ EQ0). simpl in H.
    eapply smap_length in EQ0.
    eapply PIR2_get; intros; repeat rewrite mapi_length; try congruence.
    inv_get; simpl.
    edestruct H; eauto; dcr. monadS_inv H3. get_functional; subst.
    econstructor; eauto.
Qed.
