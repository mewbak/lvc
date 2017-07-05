Require Import CSet Le Arith.Compare_dec Var.
Require Import Plus Util Map Get Take LengthEq SafeFirst .
Require Export StableFresh Fresh NRange InfinitePartition PidgeonHole.

Set Implicit Arguments.

Inductive FreshGen (V:Type) `{OrderedType V} (Fi : Type) :=
  {
    fresh :> Fi -> V -> V * Fi;
    fresh_list : Fi -> list V -> list V * Fi;
    domain : Fi -> set V;
    domain_add : Fi -> set V -> Fi;
    empty_domain : Fi
  }.

Arguments FreshGen V {H} Fi.

Inductive FreshGenSpec V `{OrderedType V} Fi (FG:FreshGen V Fi) : Prop :=
  {
    fresh_spec : forall i x, fst (fresh FG i x) ∉ domain FG i;
    fresh_domain_spec : forall i x, {fst (fresh FG i x); (domain FG i)}
                                 ⊆ domain FG (snd (fresh FG i x));
    fresh_list_disj : forall i Z, disj (domain FG i) (of_list (fst (fresh_list FG i Z)));
    fresh_list_domain_spec : forall i Z, of_list (fst (fresh_list FG i Z)) ∪ domain FG i
                                            ⊆ domain FG (snd (fresh_list FG i Z));
    fresh_list_nodup : forall i Z, NoDupA _eq (fst (fresh_list FG i Z));
    fresh_list_len : forall i Z, ❬fst (fresh_list FG i Z)❭ = ❬Z❭;
    domain_add_spec : forall i G, G ∪ domain FG i ⊆ domain FG (domain_add FG i G)
  }.

Create HintDb fresh discriminated.

Definition FG_fast_pos : FreshGen positive positive :=
  @Build_FreshGen var _ var
                  (fun n _ => (n,  succ n))
                  (fun n Z => (range succ n ❬Z❭, (iter ❬Z❭ n succ)))
                  (fun n => map ofNat (nats_up_to (asNat n)))
                  (fun n s => max n (succ (fold max s (ofNat 0))))
                  (ofNat 0).


Local Arguments succ : simpl never.
Local Arguments max : simpl never.

Lemma FGS_fast_pos : FreshGenSpec FG_fast_pos.
  econstructor.
  - intros. simpl. cset_tac'. rewrite <- nats_up_to_in in H. nr. omega.
  - simpl. intros. cset_tac'.
    + eexists (asNat a). nr.
      rewrite <- nats_up_to_in. eauto.
    + revert H1. setoid_rewrite <- nats_up_to_in. intros.
      eexists x. nr. eauto.
  - simpl. intros; hnf; intros. cset_tac'.
    eapply nats_up_to_in in H.
    eapply in_range_x in H0 as [? ?]. nr. omega.
  - simpl. intros. cset_tac'.
    + eapply in_range_x in H0.
      setoid_rewrite <- nats_up_to_in.
      eexists (asNat a). nr. split; eauto. dcr. omega.
    + rewrite <- nats_up_to_in in *.
      eexists x. nr. split; eauto.
      rewrite <- nats_up_to_in.
      omega.
  - intros. eapply range_nodup.
  - intros.
    unfold fresh_list. simpl.
    eauto with len.
  - simpl. cset_tac'.
    + eexists (asNat a). rewrite <- nats_up_to_in.
      nr. split; eauto.
      rewrite <- Max.le_max_r.
      eapply fold_max_lt in H0; eauto.
      eapply order_respecting' in H0. nr. eauto.
    + eapply nats_up_to_in in H1.
      eexists x; split; eauto.
      eapply nats_up_to_in. nr.
      rewrite <- Max.le_max_l. eauto.
      Grab Existential Variables.
      eauto with typeclass_instances.
Qed.

Definition FG_fast : FreshGen nat nat :=
  @Build_FreshGen nat _ nat
                  (fun n _ => (n, S n))
                  (fun n Z => (range succ n ❬Z❭, (n + ❬Z❭)))
                  nats_up_to
                  (fun n s => max n (S (fold Init.Nat.max s 0)))
                  0.


Lemma FGS_fast : FreshGenSpec FG_fast.
  econstructor; simpl.
  - intros. rewrite <- nats_up_to_in. omega.
  - reflexivity.
  - intros; hnf; intros.
    eapply nats_up_to_in in H.
    eapply in_range_x in H0 as [? ?].
    unfold asNat in *; simpl in *; omega.
  - intros. cset_tac'.
    + rewrite <- nats_up_to_in in *.
      eapply in_range_x in H0.
      unfold asNat in *; simpl in *; omega.
    + rewrite <- nats_up_to_in in *. omega.
  - intros. change eq with  (@_eq nat _).
    eapply range_nodup.
  - eauto with len.
  - simpl. cset_tac'.
    eapply nats_up_to_in.
    + rewrite <- Max.le_max_r.
      eapply (@fold_max_lt nat _ _ _ _) in H0.
      unfold succ, ofNat,max in *. simpl in *.
      omega.
    + eapply nats_up_to_in in H0.
      eapply nats_up_to_in.
      rewrite <- Max.le_max_l. eauto.
Qed.

Definition next_even (n:nat) := if [even n] then n else S n.

Lemma next_even_even n
  : even (next_even n).
Proof.
  unfold next_even; cases; eauto.
  edestruct (even_or_successor n); eauto.
Qed.

Lemma even_add x y
  : even x
    -> even y
    -> even (x + y).
Proof.
  revert y. pattern x.
  eapply size_induction with (f:=id); intros.
  destruct x0; simpl; eauto.
  destruct x0; simpl; eauto.
  eapply H; eauto. unfold id. omega.
Qed.

Lemma even_max x y
  : even x
    -> even y
    -> even (max x y).
Proof.
  intros.
  decide (x < y).
  - rewrite max_r; try omega; eauto.
  - rewrite max_l; try omega; eauto.
Qed.

Lemma even_mult2 x
  : even (2 * x).
Proof.
  pattern x.
  eapply size_induction with (f:=id); intros.
  destruct x0; simpl; eauto.
  destruct x0; simpl; eauto. rewrite plus_comm. simpl.
  rewrite <- plus_assoc. simpl.
  exploit (H x0).
  - unfold id. omega.
  - simpl in H0. setoid_rewrite plus_comm in H0 at 2. simpl in *. eauto.
Qed.

Definition FG_even_fast : FreshGen nat {n | even n}.
  refine
    (@Build_FreshGen nat _ {n | even n}
                  (fun n _ => (proj1_sig n, exist _ (S (S (proj1_sig n))) _))
                  (fun n Z => let z := 2 * ❬Z❭ in
                             (range (fun x => succ (succ x)) (proj1_sig n) ❬Z❭,
                              exist _ (proj1_sig n + z) _))
                  (fun n => nats_up_to (proj1_sig n))
                  (fun n s =>
                     exist _ (max (proj1_sig n) (next_even (S (fold Init.Nat.max s 0)))) _)
                  (exist _ 0 _)).
  - simpl. destruct n. eauto.
  - destruct n. subst z.
    eapply even_add; eauto.
    eapply even_mult2.
  - destruct n. eapply even_max; eauto using next_even_even.
  - simpl. eauto.
Defined.

Lemma NoDup_inj A `{OrderedType A} B `{OrderedType B} (L:list A) (f:A -> B)
      `{Proper _ (_eq ==> _eq) f}
  : NoDupA _eq L
    -> injective_on (of_list L) f
    -> NoDupA _eq (f ⊝ L).
Proof.
  intros ND INJ.
  general induction ND; simpl in *; eauto using NoDupA.
  econstructor; eauto using injective_on_incl with cset.
  intro. eapply InA_in in H3.
  eapply H0. eapply of_list_map in H3; eauto. cset_tac'.
  eapply INJ in H4; eauto with cset.
Qed.

Lemma asNat_iter_plus_plus N `{NaturalRepresentationSucc N} n i
  : asNat (iter n i (fun x => succ (succ x))) = 2 * n + asNat i.
Proof.
  general induction n; simpl; eauto.
  rewrite IHn. nr. omega.
Qed.

Lemma in_range_x  V `{NaturalRepresentationSucc V} x k n
  : x ∈ of_list (range (fun x => succ (succ x)) k n) ->
                 asNat x >= asNat k /\ asNat k+2*n > asNat x.
Proof.
  general induction n; simpl in *; dcr.
  - cset_tac.
  - decide (x === k); subst; try omega;
      cset_tac'; nr; try omega.
    eapply IHn in H3; nr; omega.
    eapply IHn in H3; nr; omega.
Qed.

Lemma range_nodup V `{NaturalRepresentationSucc V} i d
  : NoDupA _eq (range (fun x => succ (succ x)) i d).
Proof.
  general induction d; simpl; eauto using NoDupA.
  econstructor; eauto.
  intro.
  rewrite InA_in in H2.
  eapply in_range_x in H2. nr. omega.
Qed.

Lemma FGS_even_fast : FreshGenSpec FG_even_fast.
  econstructor; simpl.
  - intros. rewrite <- nats_up_to_in. omega.
  - intros [] _; simpl. cset_tac.
  - intros; hnf; intros. destruct i; simpl in *.
    eapply nats_up_to_in in H.
    eapply of_list_get_first in H0; dcr. inv_get.
    exploit (@asNat_iter_plus_plus nat _ _ _ x1 x0).
    unfold asNat in *. simpl in *. rewrite H0 in *; clear H0.
    hnf in H2. subst. omega.
  - destruct i; simpl in *.
    intros. cset_tac'.
    + eapply of_list_get_first in H0; dcr.
      exploit Get.get_range; eauto.
      inv_get. len_simpl.
      rewrite <- nats_up_to_in in *. simpl in *. invc H1.
      exploit (@asNat_iter_plus_plus nat _ _ _ x0 x).
      unfold asNat in *. simpl in *.
      rewrite H. omega.
    + rewrite <- nats_up_to_in in *. omega.
  - intros. change eq with (@_eq nat _).
    eapply range_nodup.
  - intros. len_simpl. eauto with len.
  - simpl. cset_tac'.
    eapply nats_up_to_in.
    + rewrite <- Max.le_max_r. unfold next_even.
      eapply (@fold_max_lt nat _ _ _ _) in H0.
      unfold ofNat in *. simpl in *.
      cases; eauto.
    + eapply nats_up_to_in in H0.
      eapply nats_up_to_in.
      rewrite <- Max.le_max_l. eauto.
Qed.

Definition even_pos_fast (p:positive) :=
  match p with
  | (p'~1)%positive => true
  | (p'~0)%positive => false
  | _ => true
  end.

Lemma even_pos_fast_succ p
  : even_pos_fast (Pos.succ p) = negb (even_pos_fast p).
Proof.
  unfold even_pos_fast.
  destruct p; simpl.
  - reflexivity.
  - reflexivity.
  - reflexivity.
Qed.

Lemma even_pos_fast_correct p
  : even (asNat p) = even_pos_fast p.
Proof.
  induction p using Pos.peano_ind.
  - simpl. eauto.
  - rewrite even_pos_fast_succ.
    change Pos.succ with (@succ positive _ _ _).
    nr. rewrite <- IHp.
    rewrite even_not_even. simpl. reflexivity.
Qed.

Definition next_even_pos (n:positive) :=
  if [even_pos_fast n] then n else succ n.

Lemma next_even_pos_even n
  : even (asNat (next_even_pos n)).
Proof.
  unfold next_even_pos.
  rewrite <- even_pos_fast_correct.
  cases; eauto. nr.
  edestruct (even_or_successor (asNat n)); eauto.
Qed.


Definition FG_even_fast_pos : FreshGen positive {n : positive | even (asNat n)}.
  refine
    (@Build_FreshGen positive _ {n :positive| even (asNat n)}
                  (fun n _ => (proj1_sig n, exist _ (succ (succ (proj1_sig n))) _))
                  (fun n Z => let z := ❬Z❭ in
                             (range (fun x => succ (succ x)) (proj1_sig n)  ❬Z❭,
                              exist _ (iter z (proj1_sig n) (fun x => succ (succ x))) _))
                  (fun n => map ofNat (nats_up_to (asNat (proj1_sig n))))
                  (fun n s =>
                     exist _ (max (proj1_sig n) (next_even_pos (succ (fold max s (ofNat 0))))) _)
                  (exist _ (ofNat 0) _)).
  - simpl. nr. destruct n. eauto.
  - destruct n. subst z.
    rewrite asNat_iter_plus_plus.
    eapply even_add; eauto.
    eapply even_mult2.
  - destruct n. nr. eapply even_max; eauto using next_even_pos_even.
  - simpl. eauto.
Defined.

Lemma FGS_even_fast_pos : FreshGenSpec FG_even_fast_pos.
  econstructor; simpl.
  - intros. destruct i.
    cset_tac'. simpl in *. rewrite <- nats_up_to_in in H. subst.
    nr. omega.
  - intros [] _; simpl. nr. cset_tac'.
    + eexists (asNat a). nr. split; eauto.
      rewrite <- nats_up_to_in. omega.
    + rewrite <- nats_up_to_in in H1.
      eexists x0; split; eauto.
      rewrite <- nats_up_to_in. omega.
  - intros; hnf; intros. cset_tac'.
    eapply nats_up_to_in in H. destruct i; simpl in *.
    eapply of_list_get_first in H0; dcr. inv_get.
    exploit (@asNat_iter_plus_plus _ _ _ _ x1 x).
    rewrite <- H2 in H0. nr. subst. omega.
  - intros. destruct i; simpl in *. cset_tac'.
    +  eapply of_list_get_first in H0; dcr.
       exploit Get.get_range; eauto. len_simpl.
       inv_get.
       exploit (@asNat_iter_plus_plus _ _ _ _ x0 x).
       rewrite <- H1 in *.
       exists (2 * x0 + asNat x). split; nr.
       rewrite <- nats_up_to_in in *. simpl in *.
       rewrite asNat_iter_plus_plus. omega.
       symmetry.
       rewrite <- asNat_ofNat_swap. omega.
    + rewrite <- nats_up_to_in in *.
      eexists x0; split; eauto.
      rewrite asNat_iter_plus_plus.
      rewrite <- nats_up_to_in in *.
      omega.
  - intros. change eq with (@_eq positive _).
    eapply range_nodup.
  - intros. eauto with len.
  - simpl. cset_tac'.
    + eexists (asNat a); split; nr; eauto.
      rewrite <- nats_up_to_in.
      rewrite <- Max.le_max_r. unfold next_even_pos.
      eapply (@fold_max_lt positive _ _ _ _) in H0.
      cases; eauto.
      * eapply order_respecting' in H0. eauto.
      * eapply order_respecting' in H0. nr. omega.
    + eapply nats_up_to_in in H1. destruct i; simpl in *.
      nr. eexists x. split; eauto.
      eapply nats_up_to_in.
      rewrite <- Max.le_max_l. eauto.
Qed.
