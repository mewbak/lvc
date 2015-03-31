Require Import Arith Coq.Lists.List Setoid Coq.Lists.SetoidList Omega Containers.OrderedTypeEx.
Require Export Infra.Option EqDec AutoIndTac Computable.

Set Implicit Arguments.

Tactic Notation "inv" hyp(A) := inversion A ; subst.
Tactic Notation "invc" hyp(A) := inversion A ; subst ; clear A.

Ltac invt ty :=
  match goal with
      | h: ty |- _ => inv h
      | h: ty _ |- _ => inv h
      | h: ty _ _ |- _ => inv h
      | h: ty _ _ _ |- _ => inv h
      | h: ty _ _ _ _ |- _ => inv h
      | h: ty _ _ _ _ _ |- _ => inv h
      | h: ty _ _ _ _ _ _ |- _ => inv h
      | h: ty _ _ _ _ _ _ _ |- _ => inv h
      | h: ty _ _ _ _ _ _ _ _ |- _ => inv h
      | h: ty _ _ _ _ _ _ _ _ _ |- _ => inv h
  end.

Definition iffT (A B : Type) := ((A -> B) * (B -> A))%type.

Notation "A <=> B" := (iffT A B) (at level 95, no associativity) : type_scope.

Class Defaulted (V:Type) := {
  default_el : V
}.

Ltac eq e := assert e; eauto; subst; trivial.

Ltac crush := intros; subst; simpl in *; solve [
    eauto
  | contradiction
  | match goal with [H : ?s |- _] => now(inversion H; eauto) end
  | (constructor; eauto)
  | (constructor 2; eauto)
  | (constructor 3; eauto)
  | intuition
  ].

Tactic Notation "You are here" := fail.

(** * Reflecting boolean statements to Prop *)

Require Export Basics Tactics Morphisms Morphisms_Prop.

Lemma bool_extensionality (x y:bool)
  : (x -> y) -> (y -> x) -> x = y.
Proof.
  destruct x,y; intros; eauto. destruct H; eapply I.  destruct H0; eapply I.
Qed.

Lemma toImpl (A B: Prop)
  : (A -> B) -> impl A B.
Proof.
  eauto.
Qed.

Ltac bool_to_prop_assumption H :=
  match goal with
    | [ H : context [Is_true (?x && ?y)] |- _ ]
      => rewrite (toImpl (@andb_prop_elim x y)) in H
    | [ H : context [Is_true (?x || ?y)] |- _ ]
      => rewrite (toImpl (@orb_prop_elim x y)) in H
    | [ H : Is_true (false) |- _ ] => inv H
    | [ H : context [not (?t)] |- _ ] =>
      match t with
        | context [Is_true (?x && ?y)] =>
          rewrite <- (toImpl (@andb_prop_intro x y)) in H
        | context [Is_true (?x || ?y)] =>
          rewrite <- (toImpl (@orb_prop_intro x y)) in H
        | context [Is_true (negb ?x)] =>
          rewrite <- (toImpl (@negb_prop_intro x)) in H
      end
    | [ H : context [Is_true (negb ?x)] |- _ ]
      => rewrite (toImpl (@negb_prop_elim x)) in H
    | _ => fail
  end.

Lemma true_prop_intro
  : Is_true (true) = True.
Proof.
  eauto.
Qed.

Lemma false_prop_intro
  : Is_true (false) = False.
Proof.
  eauto.
Qed.

Ltac bool_to_prop_goal :=
  match goal with
   | [ _ : _ |- context [Is_true (?x && ?y)] ]
     => rewrite <- (toImpl (@andb_prop_intro x y))
   | [ _ : _ |- context [not (Is_true (?x && ?y))] ]
     => rewrite (toImpl (@andb_prop_elim x y))
   | [ _ : _ |- context [Is_true (?x || ?y)] ]
     => rewrite <- (toImpl (@orb_prop_intro x y))
   | [ _ : _ |- context [not (Is_true (?x || ?y))] ]
     => rewrite (toImpl (@orb_prop_elim x y))
   | [  _ : _ |- context [Is_true (negb ?x)] ]
     => rewrite <- (toImpl (@negb_prop_intro x))
   | [  _ : _ |- context [Is_true (true)] ]
     => rewrite true_prop_intro
   | [  _ : _ |- context [Is_true (false)] ]
     => rewrite false_prop_intro
   | _ => fail
  end.

Tactic Notation "bool_to_prop" :=
  repeat bool_to_prop_goal.

Tactic Notation "bool_to_prop" "in" hyp (H) :=
  repeat (bool_to_prop_assumption H).

Tactic Notation "bool_to_prop" "in" "*" :=
  repeat (match goal with
    | [ H : _ |- _ ] => bool_to_prop in H
  end).

Ltac isabsurd :=
  try now (hnf; intros; match goal with
                 [ H : _ |- _ ] => exfalso; inversion H; try congruence
               end).

Ltac destr_assumption H :=
  repeat match goal with
           | [ H : _ /\ _  |- _ ] => destruct H
         end.

Ltac destr :=
  intros; repeat match goal with
                   | |- _ /\ _  => split
                 end.

Tactic Notation "destr" "in" hyp(H) :=
  destr_assumption H.

Tactic Notation "destr" "in" "*" :=
  repeat (match goal with
    | [ H : _ |- _ ] => destr in H
  end).

Tactic Notation "beq_to_prop" :=
  match goal with
    | [ H : ?Q = true |- Is_true ?Q] => rewrite H; eapply I
    | [ H : Is_true ?Q |- ?Q = true] => destruct Q; try destruct H; reflexivity
    | [ H : Is_true ?Q, H' : ?Q = false |- _ ] => rewrite H' in H; destruct H
    | [ H : Is_true ?Q |- not ((?Q) = false) ] => let X:= fresh "H" in
      intro X; rewrite X in H; destruct H
    | [ H : ?Q = false |- not (Is_true (?Q)) ] => rewrite H; cbv; trivial
    | [ H : ?Q, H' : not (?Q) |- _ ] => exfalso; apply H'; apply H
    | [ H : not (?Q = false) |- Is_true (?Q) ] =>
      destruct Q; solve [ apply I | exfalso; eapply H; trivial ]
    | |- Is_true true => eapply I
    | [ H : not (Is_true (?Q)) |- ?Q = false ] =>
      destruct Q; solve [ exfalso; eapply H; eapply I | reflexivity ]
  end.


Tactic Notation "cbool" :=
  simpl in *; bool_to_prop in *; destr in *; bool_to_prop; destr; beq_to_prop; isabsurd.

Global Instance inst_eq_dec_list {A} `{EqDec A eq} : EqDec (list A) eq.
hnf. eapply list_eq_dec. eapply equiv_dec.
Defined.


(** * Omega Rewrite *)

Tactic Notation "orewrite" constr(A) :=
  let X := fresh "OX" in assert A as X by omega; rewrite X; clear X.

Tactic Notation "orewrite" constr(A) "in" hyp(H) :=
  let X := fresh "OX" in assert A as X by omega; rewrite X in H; clear X.


(** * Misc. Tactics *)

Ltac on_last_hyp tac :=
  match goal with [ H : _ |- _ ] => first [ tac H | fail 1 ] end.

Ltac revert_until id :=
  on_last_hyp ltac:(fun id' =>
    match id' with
      | id => idtac
      | _ => revert id' ; revert_until id
    end).

Tactic Notation "simplify" "if" :=
  match goal with
    | [ H : Is_true (?P) |- context [if ?P then _ else _]] =>
      let X := fresh in assert (P = true) as X by cbool; rewrite X; clear X
    | [ H : not (Is_true (?P)) |- context [if ?P then _ else _]] =>
      let X := fresh in assert (P = false) as X by cbool; rewrite X; clear X
  end.

Tactic Notation "simplify" "if" "in" "*" :=
  match goal with
    | [ H : Is_true (?P), H' : context [if ?P then _ else _] |- _ ] =>
      let X := fresh in assert (P = true) as X by cbool; rewrite X in H'; clear X
    | [ H : not (Is_true (?P)), H' : context [if ?P then _ else _] |- _ ] =>
      let X := fresh in assert (P = false) as X by cbool; rewrite X in H'; clear X
  end.


Ltac eqassumption :=
  match goal with
    | [ H : ?C ?t |- ?C ?t' ] =>
      let X := fresh in
        cut (C t' = C t);
          [ rewrite X; apply H |
            f_equal; try congruence ]
    | [ H : ?C ?t1 ?t2 |- ?C ?t1' ?t2' ] =>
      let X := fresh in
        cut (C t1' t2' = C t1 t2);
          [ intros X; rewrite X; apply H |
            f_equal; try congruence ]
    | [ H : ?C ?t1 ?t2 ?t3 |- ?C ?t1' ?t2' ?t3'  ] =>
      let X := fresh in
        cut (C t1' t2' t3' = C t1 t2 t3);
          [ intros X; rewrite X; apply H |
            f_equal; try congruence ]
    | [ H : ?C ?t1 ?t2 ?t3 ?t4 |- ?C ?t1' ?t2' ?t3' ?t4' ] =>
      let X := fresh in
        cut (C t1' t2' t3' t4' = C t1 t2 t3 t4);
          [ intros X; rewrite X; apply H |
            f_equal; try congruence ]
  end.


Definition fresh {X} `{Equivalence X} (x:X) (Y:list X) : Prop :=
  ~InA R x Y.

Fixpoint unique X `{Equivalence X} (Y:list X) : Prop :=
  match Y with
    | nil => True
    | cons x Y' => fresh x Y' /\ unique Y'
  end.

Ltac let_case_eq :=
  match goal with
    | [ H : context [let (_, _) := ?e in _] |- _ ] =>
      let a := fresh "a" in let b := fresh "b" in let eq := fresh "eq" in
        case_eq e; intros a b eq; rewrite eq in H
  end.

Ltac let_pair_case_eq :=
  match goal with
    | [ |- context [let (_, _) := ?e in _] ] => case_eq e; intros
    | [ H : ?x = (?s, ?t) |- _ ] =>
      assert (fst x = s) by (rewrite H; eauto);
      assert (snd x = t) by (rewrite H; eauto); clear H
  end.

Ltac simpl_pair_eqs :=
  match goal with
    | [ H : ?P = (?x, ?y) |- _ ] => assert (fst P = x) by (rewrite H; eauto);
      assert (snd P = y) by (rewrite H; eauto); clear H
  end.


Ltac scofix :=
repeat match goal with
           [H : _ |- _] =>
           match H with
             | _ => revert H
           end
       end; cofix; intros.

Ltac stuck :=
  let A := fresh "A" in let v := fresh "v" in intros [v A]; inv A; isabsurd.

Ltac stuck2 :=
  let A := fresh "A" in
  let v := fresh "v" in
  let evt := fresh "evt" in
  intros [v [evt A]]; inv A; isabsurd.


Lemma modus_ponens P Q
: P -> (P -> Q) -> Q.
tauto.
Defined.

Tactic Notation "exploiT" tactic(tac) :=
  eapply modus_ponens;[ tac | intros].

Ltac exploit H :=
  eapply modus_ponens;
  [
    let H' := fresh "exploitH" in
    pose proof H as H'; hnf in H';
      eapply H'; clear H'
  | intros].

Tactic Notation "exploiT" constr(ty) :=
  match goal with
      | H: ty |- _ => exploit H
      | H: ty _ |- _ => exploit H
      | H: ty _ _ |- _ => exploit H
      | H: ty _ _ _ |- _ => exploit H
      | H: ty _ _ _ _ |- _ => exploit H
      | H: ty _ _ _ _ _ |- _ => exploit H
      | H: ty _ _ _ _ _ _ |- _ => exploit H
      | H: ty _ _ _ _ _ _ _ |- _ => exploit H
      | H: ty _ _ _ _ _ _ _ _ |- _ => exploit H
      | H: ty _ _ _ _ _ _ _ _ _ |- _ => exploit H
  end.

Definition foo A B C := (A -> ~ B \/ C).

Lemma test (A B C D : Prop) (a:A) (b:B)

: foo A B C
  -> (C -> D)
  ->  D.
Proof.
  intros. exploiT foo. eauto. exploit H. eauto. firstorder.
Qed.

Instance prod_eq_fst_morphism X Y R R'
: Proper (@prod_eq X Y R R' ==> R) fst.
Proof.
  unfold Proper, respectful; intros.
  inv H; simpl; eauto.
Qed.

Instance prod_eq_snd_morphism X Y R R'
: Proper (@prod_eq X Y R R' ==> R') snd.
Proof.
  unfold Proper, respectful; intros.
  inv H; simpl; eauto.
Qed.

Lemma list_eq_length A R l l'
  : @list_eq A R l l' -> length l = length l'.
Proof.
  intros. general induction H; simpl; eauto.
Qed.

Inductive option_R (A B : Type) (eqA : A -> B -> Prop)
: option A -> option B -> Prop :=
| option_R_Some a b : eqA a b -> option_R eqA ⎣a⎦ ⎣b⎦.


Lemma option_R_refl A R `{Reflexive A R} : forall x, option_R R ⎣x⎦ ⎣x⎦.
intros; eauto using option_R.
Qed.

Instance option_R_sym A R `{Symmetric A R} : Symmetric (option_R R).
hnf; intros ? [] []; eauto using option_R.
Qed.

Instance option_R_trans A R `{Transitive A R} : Transitive (option_R R).
hnf; intros. inv H0; inv H1; econstructor; eauto.
Qed.

Section PolyIter.
  Variable A : Type.

  Fixpoint iter n (s:A) (f: nat -> A-> A) :=
    match n with
        | 0 => s
        | S n => iter n (f n s) f
    end.

End PolyIter.

Require Le Arith.Compare_dec.

Instance le_comp (a b: nat) : Computable (lt a b).
eapply Arith.Compare_dec.lt_dec.
Defined.

Hint Extern 20 => match goal with
                   | [ H: ?a /\ ?b |- ?b ] => eapply H
                   | [ H: ?a /\ ?b |- ?a ] => eapply H
                 end.

Instance instance_option_eq_trans_R X {R: relation X} `{Transitive _ R}
 : Transitive (option_eq R).
Proof.
  hnf; intros. inv H0; inv H1.
  + econstructor.
  + econstructor; eauto.
Qed.

Instance instance_option_eq_refl_R X {R: relation X} `{Reflexive _ R}
 : Reflexive (option_eq R).
Proof.
  hnf; intros. destruct x.
  + econstructor; eauto.
  + econstructor.
Qed.

Instance instance_option_eq_sym_R X {R: relation X} `{Symmetric _ R}
 : Symmetric (option_eq R).
Proof.
  hnf; intros. inv H0.
  + econstructor.
  + econstructor; eauto.
Qed.

Instance plus_le_morpism
: Proper (Peano.le ==> Peano.le ==> Peano.le) Peano.plus.
Proof.
  unfold Proper, respectful.
  intros. omega.
Qed.

Instance plus_S_morpism
: Proper (Peano.le ==> Peano.le) S.
Proof.
  unfold Proper, respectful.
  intros. omega.
Qed.

Instance le_lt_morph
: Proper (Peano.ge ==> Peano.le ==> impl) Peano.lt.
Proof.
  unfold Proper, respectful, impl; intros; try omega.
Qed.

Instance le_lt_morph'
: Proper (eq ==> Peano.le ==> impl) Peano.lt.
Proof.
  unfold Proper, respectful, flip, impl; intros; try omega.
Qed.

Instance le_lt_morph''
: Proper (Peano.le ==> eq ==> flip impl) Peano.lt.
Proof.
  unfold Proper, respectful, flip, impl; intros; try omega.
Qed.

(** ** List Length automation *)

Lemma length_map_2 X Y Z (L:list X) (L':list Y) (f:Y->Z)
: length L = length L'
  -> length L = length (List.map f L').
Proof.
  intros. rewrite map_length; eauto.
Qed.

Lemma length_map_1 X Y Z (L:list Y) (L':list X) (f:Y->Z)
: length L = length L'
  -> length (List.map f L) = length L'.
Proof.
  intros. rewrite map_length; eauto.
Qed.

Create HintDb len discriminated.

Hint Resolve length_map_1 length_map_2 : len.


(*
*** Local Variables: ***
*** coq-load-path: (("../" "Lvc")) ***
*** End: ***
*)
