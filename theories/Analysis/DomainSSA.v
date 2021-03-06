Require Import CSet Le CMap CMapDomain CMapPartialOrder CMapJoinSemiLattice CMapTerminating.

Require Import Plus Util AllInRel CSet OptionR.
Require Import Val Var Envs IL Annotation Infra.Lattice DecSolve.
Require Import CMap WithTop.
Require Import MapNotations ListUpdateAt.
Require Import Terminating OptionR.

Set Implicit Arguments.

Open Scope map_scope.

Definition Dom D := Map [var, D].

Definition domupd D (d:Dom D) x (o:option D) : Dom D :=
  match o with
  | Some xv => (d [- x <- xv -])
  | None => remove x d
  end.

Fixpoint domjoin_list D `{JoinSemiLattice D} (m:Dom D) (A:list var) (B:list (option D)) :=
  match A, B with
  | x::A, y::B =>
    domupd (domjoin_list m A B) x (join (find x m) y)
  | _, _ => m
  end.

Definition domenv D (d:Dom D) (x:var) : option D :=
  find x d.

Lemma domupd_le D `{PartialOrder D} (a b: Dom D) v v' x
  : poLe a b
    -> poLe v v'
    -> poLe (domupd a x v) (domupd b x v').
Proof.
  unfold leMap, domupd; intros.
  inv H1.
  - repeat cases; clear_trivial_eqs; hnf; intros; mlud; eauto.
  - hnf; intros; mlud; eauto.
Qed.

Lemma domjoin_list_le D `{JoinSemiLattice D} (a b: Dom D) Z Y Y'
  : poLe a b
    -> poLe Y Y'
    -> poLe (domjoin_list a Z Y)
            (domjoin_list b Z Y').
Proof.
  general induction Z; simpl domjoin_list; eauto.
  inv H2; eauto.
  - eapply domupd_le.
    + eapply IHZ; eauto.
    + eapply ojoin_poLe; eauto.
Qed.

Lemma domupd_eq D `{PartialOrder D} (a b: Dom D) v v' x
  : poEq a b
    -> poEq v v'
    -> poEq (domupd a x v) (domupd b x v').
Proof.
  unfold eqMap, domupd; intros.
  inv H1.
  - eapply eqMap_remove; eauto.
  - repeat cases; clear_trivial_eqs.
    hnf; intros. mlud; eauto.
    econstructor. eauto.
Qed.

Lemma domjoin_list_eq  D `{JoinSemiLattice D} (a b: Dom D) Z Y Y'
  : poEq a b
    -> poEq Y Y'
    -> poEq (domjoin_list a Z Y)
            (domjoin_list b Z Y').
Proof.
  general induction Z; simpl domjoin_list; eauto.
  inv H2; eauto.
  - eapply domupd_eq
    + eapply IHZ; eauto.
    + eapply ojoin_poEq; eauto.
Qed.

Lemma domjoin_ne D (m:Dom D) x y a
  : x =/= y
    -> find x (domupd m y a) = find x m.
Proof.
  unfold domupd; cases; intros; mlud; eauto.
Qed.

Lemma domjoin_list_ne D `{JoinSemiLattice D} (m:Dom D) x Z Y
  : ~ InA eq x Z
    -> find x (domjoin_list m Z Y) === find x m.
Proof.
  intros NI.
  general induction Z; destruct Y; simpl; eauto.
  erewrite domjoin_ne; eauto.
  intro; eapply NI; econstructor. eapply H1.
Qed.

Lemma domupd_poLe D `{PartialOrder D} (m m' : Map [var, D]) a v
  : poLe (find a m) v
    -> poLe m m'
    -> poLe m (domupd m' a v).
Proof.
  intros. hnf; intros.
  unfold domupd; cases.
  - mlud; eauto. rewrite <- e. eauto.
  - mlud; eauto. rewrite <- e, <- H3. eauto.
Qed.

Lemma domjoin_list_exp  D `{JoinSemiLattice D} (m:Dom D) Z Y
  : poLe m (domjoin_list m Z Y).
Proof.
  general induction Z; destruct Y; simpl domjoin_list; eauto;
    try reflexivity.
  eapply domupd_poLe; eauto.
  eapply join_poLe.
Qed.


Lemma domain_join_sig X `{OrderedType X} Y `{JoinSemiLattice Y}  U
  (x y : {m : Map [X, Y] | domain m [<=] U})
  : domain (proj1_sig x ⊔ proj1_sig y) [<=] U.
Proof.
  destruct x,y; simpl.
  unfold join; simpl.
  unfold joinMap. rewrite domain_join. cset_tac.
Qed.

Definition joinsig X `{OrderedType X} Y `{JoinSemiLattice Y}  U
           (x y : {m : Map [X, Y] | domain m ⊆ U}) :=
  exist (fun m => domain m ⊆ U) (join (proj1_sig x) (proj1_sig y)) (domain_join_sig x y).

Definition joinsig_bound X `{OrderedType X} Y `{JoinSemiLattice Y}  U
  : forall a b: {m : Map [X, Y] | domain m [<=] U}, poLe a b -> poLe (joinsig a b) b.
Proof.
  - hnf; intros [a ?] [b ?]. simpl. eapply joinDom_bound.
Qed.

Definition joinsig_sym X `{OrderedType X} Y `{JoinSemiLattice Y}  U
  : forall a b : {m : Map [X, Y] | domain m [<=] U}, joinsig a b ≣ joinsig b a.
Proof.
  - hnf; intros [a ?] [b ?]. eapply joinDom_sym.
Qed.

Definition joinsig_assoc X `{OrderedType X} Y `{JoinSemiLattice Y}  U
  : forall a b c : {m : Map [X, Y] | domain m [<=] U}, joinsig (joinsig a b) c ≣ joinsig a (joinsig b c).
Proof.
  hnf; intros [a ?] [b ?] [c ?]. eapply joinDom_assoc.
Qed.

Definition joinsig_exp X `{OrderedType X} Y `{JoinSemiLattice Y}  U
  : forall a b : {m : Map [X, Y] | domain m [<=] U}, a ⊑ joinsig a b.
Proof.
  hnf; intros [a ?] [b ?]; simpl. eapply joinDom_exp.
Qed.


Instance map_sig_semilattice_bound X `{OrderedType X} Y `{JoinSemiLattice Y}  U
  : JoinSemiLattice ({ m : Map [X, Y] | domain m ⊆ U}) := {
  join x y := joinsig x y
}.
Proof.
  - eapply joinsig_bound.
  - eapply joinsig_sym.
  - eapply joinsig_assoc.
  - eapply joinsig_exp.
  - simpl. unfold Proper, respectful; intros.
    destruct x,y,x0,y0; unfold poEq in *; simpl in * |- *.
    rewrite H2, H3. reflexivity.
  - simpl. unfold Proper, respectful; intros.
    destruct x,y,x0,y0; unfold poLe in *; simpl in * |- *.
    rewrite H3, H2. reflexivity.
Defined.

Instance map_sig_lower_bounded X `{OrderedType X} Y `{JoinSemiLattice Y} U
  : LowerBounded { m : Map [X, Y] | domain m ⊆ U} :=
  {
    bottom := exist _ (@bottom (Map [X,Y]) _ _) (incl_empty _ _)
  }.
Proof.
  intros [a b]; simpl.
  eapply empty_bottom; eauto.
Defined.

Definition VDom U D := { m : Map [var, D] | domain m ⊆ U}.

Lemma domain_domupd_incl  D (m:Dom D) x v
  : domain (domupd m x v) ⊆ {x; domain m}.
Proof.
  unfold domupd; cases.
  - rewrite domain_add. reflexivity.
  - rewrite domain_remove. cset_tac.
Qed.

Lemma domain_domjoin_list_incl D `{JoinSemiLattice D} (m:Dom D) x v
  : domain (domjoin_list m x v) ⊆ of_list x ∪ domain m.
Proof.
  general induction x; destruct v; simpl.
  - cset_tac.
  - cset_tac.
  - cset_tac.
  - rewrite domain_domupd_incl.
    rewrite IHx; eauto. cset_tac.
Qed.

Lemma domupdd_dom D U (d:VDom U D) x v
  : x \In U -> domain (domupd (proj1_sig d) x v) [<=] U.
Proof.
  destruct d; simpl.
  rewrite domain_domupd_incl. intros. cset_tac.
Qed.

Lemma domjoin_list_dom D `{JoinSemiLattice D} U  (d:VDom U D) Z Y
  : of_list Z ⊆ U -> domain (domjoin_list (proj1_sig d) Z Y) [<=] U.
Proof.
  destruct d; simpl.
  rewrite domain_domjoin_list_incl. intros. cset_tac.
Qed.

Definition domupdd D U (d:VDom U D) x (v:option D) (IN:x ∈ U) : VDom U D :=
  (exist _ (domupd (proj1_sig d) x v) (domupdd_dom d v IN)).

Definition domjoin_listd D `{JoinSemiLattice D}
           U (d:VDom U D) Z Y (IN:of_list Z ⊆ U) : VDom U D :=
  (exist _ (domjoin_list (proj1_sig d) Z Y) (domjoin_list_dom d Z Y IN)).


Lemma option_R_inv x y
  : @OptionR.option_R (withTop Val.val) (withTop Val.val)
         (@poEq (withTop Val.val)
                (@withTop_PO Val.val Val.int_eq Val.Equivalence_eq_int' Val.int_eq_dec)) x y
    -> x = y.
Proof.
  intros. inv H; eauto.
  inv H0; eauto.
  do 2 f_equal. eauto.
Qed.

Lemma add_dead D (G:set var) (R:D->D->Prop) `{Reflexive _ R} (AE:Dom D) x v (NOTIN:x ∉ G)
  : agree_on (@OptionR.option_R _ _ R) G (domenv AE)
             (domenv (add x v AE)).
Proof.
  hnf; intros. unfold domenv.
  mlud. cset_tac. reflexivity.
Qed.

Lemma remove_dead D (G:set var) (R:D->D->Prop) `{Reflexive _ R} (AE:Dom D) x (NOTIN:x ∉ G)
  : agree_on (@OptionR.option_R _ _ R) G (domenv AE)
             (domenv (remove x AE)).
Proof.
  hnf; intros. unfold domenv.
  mlud. cset_tac. reflexivity.
Qed.

Lemma domupd_dead D (G:set var) (R:D->D->Prop) `{Reflexive _ R} x AE v (NOTIN:x ∉ G)
  : agree_on (OptionR.option_R R) G (domenv AE)
             (domenv (domupd AE x v)).
Proof.
  unfold domupd; cases.
  + eapply add_dead; eauto.
  + eapply remove_dead; eauto.
Qed.



Lemma bottom_join_left D `{JoinSemiLattice D} `{@LowerBounded D H} (x:D)
  : poEq (⊥ ⊔ x) x.
Proof.
  symmetry. rewrite join_commutative.
  eapply join_wellbehaved. eapply bottom_least.
Qed.

Lemma bottom_join_right D `{JoinSemiLattice D} `{@LowerBounded D H} (x:D)
  : poEq (x ⊔ ⊥) x.
Proof.
  symmetry.
  eapply join_wellbehaved. eapply bottom_least.
Qed.

Lemma agree_domenv_join_bot U D `{JoinSemiLattice D} (G:set var) (a b:VDom U D) c
      : a === bottom
        -> agree_on poEq G (domenv (proj1_sig b)) (domenv c)
        -> agree_on poEq G (domenv (proj1_sig (join a b))) (domenv c).
Proof.
  destruct a,b;
    unfold domenv, poEq at 1; simpl proj1_sig.
  intros A B.
  hnf; intros z IN.
  eapply poEq_sig_struct' in A.
  rewrite A. rewrite bottom_join_left.
  eapply B. eauto.
Qed.

Lemma agree_domenv_join_bot2 U D `{JoinSemiLattice D} (G:set var) (a b:VDom U D) c
      : agree_on poEq G (domenv (proj1_sig a)) (domenv c)
        -> b === bottom
        -> agree_on poEq G (domenv (proj1_sig (join a b))) (domenv c).
Proof.
  destruct a,b;
    unfold domenv, poEq at 2; simpl proj1_sig.
  intros A B.
  hnf; intros z IN.
  eapply poEq_sig_struct' in B.
  rewrite B. rewrite bottom_join_right.
  eapply A. eauto.
Qed.




Lemma domupd_var_eq D (m:Dom D) x y a
  : x === y
    -> find x (domupd m y a) = a.
Proof.
  unfold domupd; cases; intros; mlud; eauto.
  - exfalso; eauto.
  - exfalso; eauto.
Qed.

Lemma domupd_var_ne D (m:Dom D) x y a
  : x =/= y
    -> find x (domupd m y a) = find x m.
Proof.
  unfold domupd; cases; intros; mlud; eauto.
Qed.

Lemma domupd_list_ne D `{JoinSemiLattice D} (m:Dom D) x Z Y
  : ~ InA eq x Z
    -> find x (domjoin_list m Z Y) === find x m.
Proof.
  intros NI.
  general induction Z; destruct Y; simpl; eauto.
  rewrite domupd_var_ne; eauto.
  intro; eapply NI; econstructor. eapply H1.
Qed.

Lemma domupd_list_get D `{JoinSemiLattice D} (m:Dom D) Z Y x n y
  : NoDupA eq Z
    -> get Z n x
    -> get Y n y
    -> poLe y (find x (domjoin_list m Z Y)).
Proof.
  intros ND GetZ GetY.
  general induction n; simpl domjoin_list.
  - rewrite domupd_var_eq; eauto.
  - inv GetZ; inv GetY.
    simpl domjoin_list.
    rewrite domupd_var_ne; eauto.
    inv ND. intro. eapply H5.
    rewrite <- H1. eapply get_InA; eauto.
Qed.


Lemma domupd_list_agree D `{JoinSemiLattice D} (R:relation (option D)) `{Reflexive _ R} G (AE:Dom D) Z Y
  : agree_on R (G \ of_list Z)
             (domenv AE)
             (domenv (domjoin_list AE Z Y)).

Proof.
  general induction Z; destruct Y; simpl; try reflexivity.
  hnf; intros. cset_tac'.
  unfold domenv.
  rewrite domupd_var_ne; [|symmetry; eauto].
  exploit IHZ; eauto.
  exploit H4; eauto. cset_tac.
Qed.


Lemma poEq_domupd D `{PartialOrder D}
      (m:Dom D) x v
  : find x m === v
    -> poEq m (domupd m x v).
Proof.
  intros. hnf; intros; unfold domupd; cases; mlud; eauto;
  rewrite <- e; eauto.
Qed.

Lemma domenv_proper G
  : Proper (poEq ==> agree_on poEq G) (@domenv _).
Proof.
  unfold Proper, respectful, domenv, agree_on; intros.
  eauto.
Qed.

Lemma find_mapjoin_dist X `{OrderedType X} D `{JoinSemiLattice D} (m m':Map [X, D]) z
  : find z (m ⊔ m') === ((find z m) ⊔ (find z m')).
Proof.
  unfold join; simpl.
  unfold join at 1; simpl.
  unfold joinMap.
  rewrite MapFacts.map2_1bis; eauto.
Qed.

Lemma agree_domenv_join U D `{JoinSemiLattice D} (G:set var) (a b:VDom U D) c
      : agree_on poEq G (domenv (proj1_sig a)) (domenv c)
        -> agree_on poEq G (domenv (proj1_sig b)) (domenv c)
        -> agree_on poEq G (domenv (proj1_sig (join a b))) (domenv c).
Proof.
  destruct a,b;
    unfold domenv; simpl proj1_sig.
  intros A B.
  hnf; intros z IN.
  rewrite find_mapjoin_dist.
  specialize (A z IN).
  specialize (B z IN). cbv beta in *.
  rewrite A, B. rewrite join_idempotent. reflexivity.
Qed.

Lemma domupd_list_agree_poLe D `{JoinSemiLattice D} G (AE:Dom D) Z Y
  : agree_on poLe G
             (domenv AE)
             (domenv (domjoin_list AE Z Y)).

Proof.
  hnf; intros. decide (x ∈ of_list Z).
  - general induction Z; destruct Y; simpl; try reflexivity.
    simpl in *. decide (x = a); subst.
    + unfold domenv.
      rewrite domupd_var_eq; [|symmetry; eauto].
      unfold ojoin; repeat cases; try econstructor; eauto.
      eapply join_poLe.
    + unfold domenv.
      rewrite domupd_var_ne; [|intro; eauto].
      eapply IHZ; eauto. cset_tac.
  - eapply domupd_list_agree; eauto. cset_tac.
Qed.


Lemma domupd_list_get_first D `{JoinSemiLattice D} (m:Dom D) Z Y x n y
  : get Z n x
    -> get Y n y
    -> (forall (n' : nat) (z' : var),
          n' < n -> get Z n' z' -> z' =/= x)
    -> poLe y (find x (domjoin_list m Z Y)).
Proof.
  intros GetZ GetY LEAST.
  general induction n; simpl domjoin_list.
  - rewrite domupd_var_eq; eauto.
  - inv GetZ; inv GetY.
    simpl domjoin_list.
    rewrite domupd_var_ne; eauto using get.
    + eapply IHn; intros; eauto using get.
      eapply (LEAST (S n')); eauto using get. omega.
    + symmetry. eapply (LEAST 0); eauto using get. omega.
Qed.

Lemma poLe_domupdd D `{PartialOrder D} U d d' v v' x IN IN'
  : d ⊑ d'
    -> v ⊑ v'
    -> @domupdd D U d x v IN ⊑ @domupdd D U d' x v' IN'.
Proof.
  intros. eapply poLe_sig_struct.
  eapply domupd_le; eauto.
Qed.

Lemma poEq_domupdd D `{PartialOrder D} U d d' v v' x IN IN'
  : d ≣ d'
    -> v ≣ v'
    -> @domupdd D U d x v IN ≣ @domupdd D U d' x v' IN'.
Proof.
  intros. eapply poEq_sig_struct.
  eapply domupd_eq; eauto.
Qed.

Hint Resolve poLe_domupdd poEq_domupdd.

Lemma domupd_poLe_left D `{PartialOrder D} d d' x v
  : d ⊑ d'
    -> v ⊑ domenv d' x
    -> domupd d x v ⊑ d'.
Proof.
  intros.
  hnf; intros y.
  decide (y === x); eauto; subst.
  - invc e.
    rewrite domupd_var_eq; eauto.
  - rewrite domupd_var_ne; eauto.
Qed.

Lemma domjoin_list_poLe_left D `{JoinSemiLattice D} d d' Z Y
  : d ⊑ d'
    -> (forall n x y, get Z n x -> get Y n y -> y ⊑ domenv d' x)
    -> domjoin_list d Z Y ⊑ d'.
Proof.
  general induction Z; destruct Y; eauto.
  simpl. eapply domupd_poLe_left; eauto using get.
  exploit H2; eauto using get.
  eapply join_poLe_left; eauto.
Qed.


Lemma domjoin_list_notin D `{JoinSemiLattice D} x d Z Y
  : x ∉ of_list Z
    -> MapInterface.find x (domjoin_list d Z Y) = MapInterface.find x d.
Proof.
  intros. general induction Z; destruct Y; simpl in *; eauto.
  rewrite domupd_var_ne.
  rewrite IHZ; eauto. cset_tac. cset_tac.
Qed.

Lemma domjoin_list_get D `{JoinSemiLattice D} x (y y':option D) n d Z Y
  : get Z n x
    -> get Y n y'
    -> y ≣ y'
    -> NoDupA eq Z
    -> domenv (domjoin_list d Z Y) x ≣ ((domenv d x) ⊔ y).
Proof.
  intros. general induction n; simpl in *; eauto.
  - unfold domenv. rewrite domupd_var_eq; eauto.
    rewrite H3. reflexivity.
  - inv H1; inv H2. simpl.
    inv H4.
    eapply NoDupA_get_neq' in H4; [|eauto|eauto| instantiate (2:=0) |eauto using get| eauto using get];
      try omega.
    rewrite <- IHn; eauto using get.
    unfold domenv.
    rewrite domupd_var_ne; eauto. intro. eapply H4. invc H5; eauto.
Qed.


Arguments to_list : simpl never.

Instance poLe_find_proper D `{PartialOrder D}
  : Proper (_eq ==> @poLe (Dom D) _ ==> poLe) (@MapInterface.find var _ _ D).
Proof.
  unfold Proper, respectful; intros. invc H0.
  eapply H1.
Qed.

Instance poEq_find_proper D `{PartialOrder D}
  : Proper (_eq ==> @poEq (Dom D) _ ==> poEq) (@MapInterface.find var _ _ D).
Proof.
  unfold Proper, respectful; intros. invc H0.
  eapply H1.
Qed.

Instance poLe_domenv_proper D `{PartialOrder D}
  : Proper (@poLe (Dom D) _ ==> _eq ==> poLe) (@domenv D).
Proof.
  unfold Proper, respectful; intros. invc H1.
  eapply H0.
Qed.

Instance poEq_domenv_proper D `{PartialOrder D}
  : Proper (@poEq (Dom D) _ ==> _eq ==> poEq) (@domenv D).
Proof.
  unfold Proper, respectful; intros. invc H1.
  eapply H0.
Qed.
