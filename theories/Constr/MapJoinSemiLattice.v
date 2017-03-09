Require Import CSet CMap CMapDomain CMapPartialOrder.
Require Import Infra.PartialOrder Infra.Lattice Infra.OptionR.

Set Implicit Arguments.

Definition joinMap X `{OrderedType X} Y `{JoinSemiLattice Y}
           (d d':Map [X, Y]) := @map2 _ H _ Y Y Y join d d'.

Lemma leMap_join X `{OrderedType X} Y `{JoinSemiLattice Y} (x y x' y':Map[X, Y])
  : leMap y x
    -> leMap y' x'
    -> leMap (joinMap y y') (joinMap x x').
Proof.
  unfold leMap, joinMap.
  intros LE1 LE2 z.
  repeat rewrite MapFacts.map2_1bis; eauto.
  specialize (LE1 z). specialize (LE2 z).
  revert LE1 LE2.
  case_eq (find z y); case_eq (find z x);
    case_eq (find z y'); case_eq (find z x'); intros; simpl in *;
      clear_trivial_eqs; simpl; repeat cases; try reflexivity;
        eauto using fstNoneOrR, join_struct, join_poLe.
  - econstructor. rewrite H8. eapply join_poLe.
  - econstructor. rewrite H8. rewrite join_commutative. eapply join_poLe.
Qed.

Lemma empty_bottom X `{OrderedType X} Y `{JoinSemiLattice Y}
  :  forall a : Map [X, Y], @empty _ _ _ _ ⊑ a.
Proof.
  intros. econstructor.
Qed.

Lemma joinDom_idem X `{OrderedType X} Y `{JoinSemiLattice Y}
  : forall a : Map [X, Y], joinMap a a ≣ a.
Proof.
  unfold joinMap. intros.
  hnf; intros.
  rewrite MapFacts.map2_1bis; eauto.
  rewrite join_idempotent; eauto.
Qed.

Lemma joinDom_sym X `{OrderedType X} Y `{JoinSemiLattice Y}
  : forall a b : Map [X, Y], joinMap a b ≣ joinMap b a.
Proof.
  unfold joinMap; intros. hnf; intros.
  rewrite !MapFacts.map2_1bis; eauto.
  rewrite join_commutative. reflexivity.
Qed.

Lemma joinDom_assoc X `{OrderedType X} Y `{JoinSemiLattice Y}
  : forall a b c : Map [X, Y], joinMap (joinMap a b) c ≣ joinMap a (joinMap b c).
Proof.
  unfold joinMap; intros. hnf; intros.
  rewrite !MapFacts.map2_1bis; eauto.
  rewrite join_associative. reflexivity.
Qed.

Lemma joinDom_exp X `{OrderedType X} Y `{JoinSemiLattice Y}
  : forall a b : Map [X, Y], a ⊑ joinMap a b.
Proof.
  intros. unfold joinMap. hnf; intros.
  rewrite !MapFacts.map2_1bis; eauto.
  eapply join_poLe.
Qed.

Instance joinDom_eq X `{OrderedType X} Y `{JoinSemiLattice Y}
  : Proper (poEq ==> poEq ==> poEq) (@joinMap X _ Y _ _).
Proof.
  unfold Proper, respectful; intros.
  hnf in H, H0.
  unfold joinMap.
  hnf; intros.
  rewrite !MapFacts.map2_1bis; eauto.
  rewrite H2, H3. reflexivity.
Qed.

Instance joinDom_poLe X `{OrderedType X} Y `{JoinSemiLattice Y}
  : Proper (poLe ==> poLe ==> poLe) (@joinMap X _ Y _ _).
Proof.
  unfold Proper, respectful; intros.
  eapply leMap_join; eauto.
Qed.

Instance map_semilattice X `{OrderedType X} Y `{JoinSemiLattice Y}
  : JoinSemiLattice (Map [X, Y]) := {
  join := @joinMap X _ Y _ _
                                                    }.

- eapply joinDom_idem.
- eapply joinDom_sym.
- eapply joinDom_assoc.
- eapply joinDom_exp.
Defined.


Instance map_lower_bounded X `{OrderedType X} Y `{JoinSemiLattice Y}
  : LowerBounded (Map [X, Y]) :=
  {
    bottom := (@empty X _ _ Y)
  }.
Proof.
  - eapply empty_bottom; eauto.
Qed.


Import Terminating.

Lemma leMap_domain X `{OrderedType X} Y `{PartialOrder Y} x y
  : leMap x y -> domain x ⊆ domain y.
Proof.
  unfold leMap. intros.
  hnf; intros.
  specialize (H1 a).
  eapply domain_find in H2. dcr.
  rewrite H3 in H1. inv H1.
  eapply find_domain. congruence.
Qed.



Instance ltMap_proper X `{OrderedType X} Y `{PartialOrder Y} (d d':Map [X, Y])
  : Proper (_eq ==> iff) (fun x => find x d ⊏ find x d').
Proof.
  unfold Proper, respectful; intros.
  split; intros.
  - rewrite <- H1; eauto.
  - rewrite H1; eauto.
Qed.


Lemma leMap_remove X `{OrderedType X} Y `{PartialOrder Y} (m m':Map [X, Y]) x
  : leMap m m'
    -> leMap (remove x m) (remove x m').
Proof.
  unfold leMap; intros LE y.
  specialize (LE y).
  decide (x === y).
  - rewrite !MapFacts.remove_eq_o; eauto.
  - rewrite !MapFacts.remove_neq_o; eauto.
Qed.
