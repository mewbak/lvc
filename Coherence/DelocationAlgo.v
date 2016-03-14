Require Import CSet Le.

Require Import Plus Util AllInRel Map Take.
Require Import Val Var Env EnvTy IL Annotation Liveness Coherence MoreList Restrict Delocation.

Set Implicit Arguments.

Definition addParam x (DL:list (set var)) (AP:list (set var)) :=
  zip (fun (DL:set var) AP => if [x ∈ DL]
                   then {{x}} ∪ AP else AP) DL AP.

Definition addParams s DL (AP:list (set var)) :=
  zip (fun DL AP => (s ∩ DL) ∪ AP) DL AP.

Definition oget {X} `{OrderedType X} (s:option (set X)) :=
  match s with Some s => s | None => ∅ end.

Definition addAdds s DL (AP:list (option (set var))) :=
  zip (fun (DL:set var) AP => mdo t <- AP; Some ((s ∩ DL) ∪ t)) DL AP.

Lemma addParam_length x DL AP
 : length DL = length AP
   -> length (addParam x DL AP) = length DL.
Proof.
  intros. unfold addParam. eauto with len.
Qed.

Lemma addAdds_length Z DL AP
 : length DL = length AP
   -> length (addAdds Z DL AP) = length DL.
Proof.
  intros. unfold addAdds. eauto with len.
Qed.

Lemma length_tl X (l:list X)
  : length (tl l) = length l - 1.
Proof.
  destruct l; simpl; eauto; omega.
Qed.

Definition lminus (s:set var) L := s \ of_list L.

Lemma addParams_length Z DL AP
 : length DL = length AP
   -> length (addParams Z DL AP) = length DL.
Proof.
  eauto with len.
Qed.

Lemma addParam_zip_lminus_length DL ZL AP x
: length AP = length DL
  -> length DL = length ZL
  -> length (addParam x (zip lminus DL ZL) AP) = length DL.
Proof.
  eauto with len.
Qed.

Lemma addParams_zip_lminus_length DL ZL AP Z
: length AP = length DL
  -> length DL = length ZL
  -> length (addParams Z (zip lminus DL ZL) AP) = length DL.
Proof.
  eauto with len.
Qed.

Lemma fold_addParams_length DL a AP
  : length DL = length AP
    -> length (fold_left (fun AP0 Z => addParams Z DL AP0) a AP) = length DL.
Proof.
  general induction a; simpl; eauto.
  rewrite IHa; eauto with len.
Qed.

Lemma fold_addParams_length_ass DL a AP k
  : length DL = length AP
    -> length DL = k
    -> length (fold_left (fun AP0 Z => addParams Z DL AP0) a AP) = k.
Proof.
  intros; subst; eapply fold_addParams_length; trivial.
Qed.

Hint Resolve fold_addParams_length_ass : len.

Definition ounion {X} `{OrderedType X} (s t: option (set X)) :=
  match s, t with
    | Some s, Some t => Some (s ∪ t)
    | Some s, None => Some s
    | None, Some t => Some t
    | _, _ => None
  end.

Lemma fold_zip_ounion_length X `{OrderedType X} a b
  : (forall n aa, get a n aa -> length aa = length b)
    -> length (fold_left (zip ounion) a b) = length b.
Proof.
  intros LEN.
  general induction a; simpl; eauto.
  rewrite IHa; eauto 10 using get with len.
Qed.


Definition killExcept f (AP:list (set var)) :=
  mapi (fun n x => if [n = counted f] then Some x else None) AP.


Definition oto_list {X} `{OrderedType X} (s:option (set X)) :=
  match s with Some s => to_list s | None => nil end.

Fixpoint computeParameters (DL: list (set var)) (ZL:list (list var)) (AP:list (set var))
         (s:stmt) (an:ann (set var)) {struct s}
: ann (list params) * list (option (set var)) :=
  match s, an with
    | stmtLet x e s, ann1 _ an =>
      let (ar, r) := computeParameters DL ZL (addParam x DL AP) s an in
      (ann1 nil ar, r)
    | stmtIf x s t, ann2 _ ans ant =>
      let (ars, rs) := computeParameters DL ZL AP s ans in
      let (art, rt) := computeParameters DL ZL AP t ant in
      (ann2 nil ars art, zip ounion rs rt)
    | stmtApp f Y, ann0 lv => (ann0 nil, killExcept f AP)
    | stmtReturn x, ann0 _ => (ann0 nil, (mapi (fun _ _ => None) AP))
    | stmtExtern x f e s, ann1 _ an =>
      let (ar, r) := computeParameters DL ZL (addParam x DL AP) s an in
      (ann1 nil ar, r)
    | stmtFun F t, annF lv ans ant =>
      let DL' := zip lminus (List.map getAnn ans) (List.map fst F) in
      let Z : list params := List.map fst F in
      let AP' := addParams (list_union (List.map of_list Z))
                          (DL' ++ DL)
                          (List.map (fun _ => ∅) F ++ AP) in
      let ars_rF :=
          zip (fun Zs a => computeParameters (DL' ++ DL) (Z ++ ZL) AP' (snd Zs) a)
              F ans in
      let (art, rt) := computeParameters (DL' ++ DL) (Z ++ ZL) AP' t ant in
      let rFt := fold_left (zip ounion) (List.map snd ars_rF) rt in
      let ZaF := list_union (List.map oget (take (length F) rFt)) in
      let ur := addAdds ZaF DL (drop (length F) rFt) in
      (annF (List.map (fun _ => to_list ZaF) F) (List.map fst ars_rF) art, ur)
    | s, a => (ann0 nil, nil)
  end.

Local Notation "≽" := (fstNoneOrR (flip Subset)).
Local Notation "≼" := (fstNoneOrR (Subset)).
Local Notation "A ≿ B" := (PIR2 (fstNoneOrR (flip Subset)) A B) (at level 60).

Instance fstNoneOrR_flip_Subset_trans {X} `{OrderedType X} : Transitive ≽.
hnf; intros. inv H; inv H0.
- econstructor.
- inv H1. econstructor. transitivity y0; eauto.
Qed.

Instance fstNoneOrR_flip_Subset_trans2 {X} `{OrderedType X} : Transitive (fstNoneOrR Subset).
hnf; intros. inv H; inv H0.
- econstructor.
- inv H1. econstructor. transitivity y0; eauto.
Qed.

Lemma trs_monotone (DL DL' : list (option (set var))) ZL s lv a
 : trs DL ZL s lv a
   -> DL ≿ DL'
   -> trs DL' ZL s lv a.
Proof.
  intros. general induction H; eauto 30 using trs, restrict_subset2.
  - destruct (PIR2_nth H1 H); eauto; dcr. inv H4.
    econstructor; eauto.
  - econstructor; eauto using restrict_subset2, PIR2_app.
Qed.

Lemma PIR2_restrict A B s
:  A ≿ B
   -> restrict A s ≿ B.
Proof.
  intros. general induction H; simpl.
  - econstructor.
  - econstructor; eauto.
    + inv pf; simpl.
      * econstructor.
      * destruct if. econstructor; eauto. econstructor.
Qed.

Opaque to_list.


(*Lemma trs_monotone3 (DL : list (option (set var))) AP AP' ZL s lv a
 : trs DL (zip (fun Z a => match a with Some a => Z++to_list a | None => Z end) ZL AP) s lv a
   -> PIR2 (fstNoneOrR Subset) AP AP'
   -> trs DL (zip (fun Z a => match a with Some a => Z++to_list a | None => Z end) ZL AP') s lv a.
Proof.
  intros. general induction H; eauto using trs.
  - edestruct get_zip as  [? []]; eauto; dcr.
    destruct (PIR2_nth H1 H4); eauto; dcr.
    exploit zip_get. eapply H2. eapply H6.
    econstructor; eauto.
  - econstructor; eauto.
    + intros. exploit H3; eauto.

      pose proof (H3 (Some ∅::AP) (Some ∅::AP') (Za::ZL0)) as A.
    simpl zip in A.
    rewrite to_list_nil in A. rewrite app_nil_r in A.
    eapply A. reflexivity. econstructor. reflexivity. eauto.
    (*
    simpl. destruct if. econstructor. constructor.
    hnf. cset_tac; intuition. eapply list_eq_restrict; eauto.
    econstructor. econstructor. eapply list_eq_restrict; eauto.*)
    pose proof (IHtrs2 (Some ∅::AP) (Some ∅::AP') (Za::ZL0)) as A.
    simpl zip in A.
    rewrite to_list_nil in A. rewrite app_nil_r in A.
    eapply A. reflexivity. econstructor. reflexivity. eauto.
Qed.
 *)

Definition elem_eq {X} `{OrderedType X} (x y: list X) := of_list x [=] of_list y.

Instance elem_eq_refl {X} `{OrderedType X} : Reflexive elem_eq.
hnf; intros. hnf. cset_tac; intuition.
Qed.


Definition elem_incl {X} `{OrderedType X} (x y: list X) := of_list x [<=] of_list y.

Instance elem_incl_refl {X} `{OrderedType X} : Reflexive elem_incl.
hnf; intros. hnf. cset_tac; intuition.
Qed.


Lemma trs_AP_seteq (DL : list (option (set var))) AP AP' s lv a
 : trs DL AP s lv a
   -> PIR2 elem_eq AP AP'
   -> trs DL AP' s lv a.
Proof.
  intros. general induction H; eauto using trs.
  - destruct (PIR2_nth H1 H0); eauto; dcr.
    econstructor; eauto.
  - econstructor; eauto using PIR2_app.
Qed.



Lemma trs_AP_incl (DL : list (option (set var))) AP AP' s lv a
 : trs DL AP s lv a
   -> PIR2 elem_incl AP AP'
   -> trs DL AP' s lv a.
Proof.
  intros. general induction H; eauto using trs.
  - destruct (PIR2_nth H1 H0); eauto; dcr.
    econstructor; eauto.
  - econstructor; eauto using PIR2_app.
Qed.

Lemma trs_AP_incl' (DL : list (option (set var))) AP AP' s lv a
 : trs DL AP s lv a
   -> PIR2 elem_incl AP AP'
   -> trs DL AP' s lv a.
Proof.
  intros. general induction H; eauto using trs.
  + destruct (PIR2_nth H1 H0); eauto; dcr.
    econstructor; eauto.
  + econstructor; eauto using PIR2_app.
Qed.


Definition map_to_list {X} `{OrderedType X} (AP:list (option (set X)))
  := List.map (fun a => match a with Some a => to_list a | None => nil end) AP.

Lemma PIR2_Subset_of_list (AP AP': list (option (set var)))
: PIR2 (fstNoneOrR Subset) AP AP'
  -> PIR2 (flip elem_incl) (map_to_list AP') (map_to_list AP).
Proof.
  intros. general induction H; simpl.
  + econstructor.
  + econstructor. destruct x, y; cset_tac; intuition.
    - hnf. setoid_rewrite of_list_3. inv pf; eauto.
    - inv pf.
    - hnf; intros; simpl in *.
      exfalso; cset_tac; intuition.
    - eauto.
Qed.

Lemma trs_monotone3' (DL : list (option (set var))) AP AP' s lv a
 : trs DL (List.map oto_list AP) s lv a
   -> PIR2 (fstNoneOrR Subset) AP AP'
   -> trs DL (List.map oto_list AP') s lv a.
Proof.
  intros. eapply trs_AP_incl'; eauto. eapply PIR2_flip.
  eapply PIR2_Subset_of_list; eauto.
Qed.

Lemma PIR2_addParam DL AP x
  : length AP = length DL
    -> PIR2 Subset AP (addParam x DL AP).
Proof.
  intros A.
  eapply length_length_eq in A.
  general induction A.
  - constructor.
  - econstructor.
    + destruct if; cset_tac; intuition.
    + exploit (IHA x0); eauto.
Qed.

Lemma PIR2_map_some {X} R (AP AP':list X)
: length AP = length AP'
  -> PIR2 R AP AP'
  -> PIR2 (fstNoneOrR R) (List.map Some AP) (List.map Some AP').
Proof.
  intros. general induction H0.
  + econstructor.
  + simpl. econstructor.
    - econstructor; eauto.
    - eauto.
Qed.

Lemma PIR2_map_some_option {X} R (AP AP':list X)
: length AP = length AP'
  -> PIR2 R AP AP'
  -> PIR2 (option_eq R) (List.map Some AP) (List.map Some AP').
Proof.
  intros. general induction H0.
  + econstructor.
  + simpl. econstructor.
    - econstructor; eauto.
    - eauto.
Qed.

Lemma PIR2_ounion {X} `{OrderedType X} (A B C:list (option (set X)))
: length A = length B
  -> length B = length C
  -> PIR2 ≽ A C
  -> PIR2 ≽ B C
  -> PIR2 ≽ (zip ounion A B) C.
Proof.
  intros. length_equify.
  general induction H0; inv H1; simpl.
  - econstructor.
  - simpl in *. inv H2; inv H3.
    exploit IHlength_eq; eauto.
    inv pf; inv pf0; simpl; try now (econstructor; [econstructor; eauto| eauto]).
    econstructor; eauto. econstructor. unfold flip in *.
    cset_tac; intuition.
Qed.

Lemma PIR2_ounion' {X} `{OrderedType X} (A B C:list (option (set X)))
: length A = length B
  -> length B = length C
  -> PIR2 ≼ C A
  -> PIR2 ≼ C B
  -> PIR2 ≼ C (zip ounion A B).
Proof.
  intros. length_equify.
  general induction H0; inv H1; simpl.
  - econstructor.
  - simpl in *. inv H2; inv H3.
    exploit IHlength_eq; eauto.
    inv pf; inv pf0; simpl;
    (econstructor; [econstructor; eauto with cset | eauto]).
Qed.

Lemma PIR2_ounion_AB {X} `{OrderedType X} (A A' B B':list (option (set X)))
: length A = length A'
  -> length B = length B'
  -> length A = length B
  -> PIR2 ≼ A A'
  -> PIR2 ≼ B B'
  -> PIR2 ≼ (zip ounion A B) (zip ounion A' B').
Proof.
  intros. length_equify.
  general induction H0; inv H1; inv H2; simpl; econstructor.
  - inv H3; inv H4.
    inv pf; inv pf0; simpl; try econstructor.
    destruct y; simpl; eauto. econstructor. cset_tac; intuition.
    destruct y0; simpl; eauto. econstructor. cset_tac; intuition.
    cset_tac; intuition.
  - inv H3; inv H4. eapply IHlength_eq; eauto.
Qed.

Lemma PIR2_option_eq_Subset_zip {X} `{OrderedType X} (A B C:list (option (set X)))
: length A = length B
  -> length B = length C
  -> PIR2 (option_eq Subset) C A
  -> PIR2 (option_eq Subset) C B
  -> PIR2 (option_eq Subset) C (zip ounion A B).
Proof.
  intros. length_equify.
  general induction H0; inv H1; simpl.
  - econstructor.
  - simpl in *. inv H2; inv H3.
    exploit IHlength_eq; eauto.
    inv pf; inv pf0; simpl;
    now (econstructor; [econstructor; eauto with cset | eauto]).
Qed.

Lemma zip_sym X Y Z (f : X -> Y -> Z) (L:list X) (L':list Y)
: length L = length L'
  -> zip f L L' = zip (fun x y => f y x) L' L.
Proof.
  intros. length_equify. general induction H; simpl; eauto.
  f_equal; eauto.
Qed.

Lemma pair_eta (X Y:Type) (p:X * Y)
  : p = (fst p, snd p).
Proof.
  destruct p; eauto.
Qed.


Lemma live_globals_zip F als DL ZL (LEN1:length F = length als)
  : Liveness.live_globals F als ++ zip pair DL ZL =
    zip pair (List.map getAnn als ++ DL) (List.map fst F ++ ZL).
Proof with eauto with len.
  rewrite zip_app... rewrite zip_map_l, zip_map_r. f_equal.
  rewrite zip_sym...
Qed.

Lemma computeParameters_length DL ZL AP s lv an' LV
:live_sound FunctionalAndImperative (zip pair DL ZL) s lv
  -> computeParameters (zip lminus DL ZL) ZL AP s lv = (an', LV)
  -> length AP = length DL
  -> length DL = length ZL
  -> length LV = length DL.
Proof.
  intros LS CPEQ LEQ LEQ2.
  general induction LS; simpl in *; repeat let_case_eq; inv CPEQ.
  - rewrite LEQ. eapply IHLS; eauto. rewrite addParam_zip_lminus_length; eauto.
  - exploit IHLS1; eauto.
    exploit IHLS2; eauto.
    repeat rewrite zip_length2; congruence.
  - unfold killExcept, mapi. rewrite mapi_length. eauto.
  - unfold mapi. rewrite mapi_length; eauto.
  - rewrite LEQ. eapply IHLS; eauto with len.
  - exploit IHLS.
    + reflexivity.
    + eapply live_globals_zip; eauto.
    + rewrite zip_app. eapply eq. eauto with len.
    + eauto 20 with len.
    + eauto with len.
    + rewrite addAdds_length, zip_length2; eauto.
      rewrite length_drop_minus, zip_length2; eauto.
      rewrite fold_zip_ounion_length.
      rewrite H4. rewrite app_length, map_length. omega.
      * rewrite H4. rewrite app_length, map_length.
        rewrite <- LEQ, <- H.
        intros. inv_map H5.
        destruct x as [an LV]. inv_zip H6.
        rewrite <- zip_app in H9; eauto with len.
        eapply H1 in H9; eauto 20 using pair_eta, live_globals_zip with len.
        simpl. rewrite H9. eauto with len.
Qed.


Inductive ifSndR {X Y} (R:X -> Y -> Prop) : X -> option Y -> Prop :=
  | ifsndR_None x : ifSndR R x None
  | ifsndR_R x y : R x y -> ifSndR R x (Some y).

Lemma PIR2_ifSndR_right {X} `{OrderedType X} A B C
: PIR2 (ifSndR Subset) B A
-> PIR2 Subset C B
-> PIR2 (ifSndR Subset) C A.
Proof.
  intros. general induction H1; simpl in *.
  + inv H0. econstructor.
  + inv H0. inv pf0.
    - econstructor.
      * econstructor.
      * eauto.
    - econstructor; eauto. econstructor; cset_tac; intuition.
Qed.


Lemma ifSndR_zip_ounion {X} `{OrderedType X} A B C
: PIR2 (ifSndR Subset) C A
  -> PIR2 (ifSndR Subset) C B
  -> PIR2 (ifSndR Subset) C (zip ounion A B).
Proof.
  intros.
  general induction H0.
  - inv H1; econstructor.
  - inv H1.
    inv pf; inv pf0; simpl;
    now (econstructor; [econstructor; eauto with cset | eauto]).
Qed.

Lemma ifSndR_fold_zip_ounion {X} `{OrderedType X} A B C
: (forall n a, get A n a -> PIR2 (ifSndR Subset) C a)
  -> PIR2 (ifSndR Subset) C B
  -> PIR2 (ifSndR Subset) C (fold_left (zip ounion) A B).
Proof.
  intros GET LE.
  general induction A; simpl; eauto.
  - eapply IHA; eauto using get, ifSndR_zip_ounion.
Qed.

Lemma ifSndR_addAdds s DL A B
 : length DL = length A
   -> PIR2 (ifSndR Subset) A B
   -> PIR2 (ifSndR Subset) A (addAdds s DL B).
Proof.
  intros. eapply length_length_eq in H.
  general induction H; inv H0; simpl.
  + constructor.
  + econstructor; eauto.
    - inv pf; simpl; econstructor.
      * cset_tac; intuition.
Qed.


Lemma addParams_Subset Z DL AP
: length DL = length AP
  -> PIR2 Subset AP (addParams Z DL AP).
Proof.
  intros. eapply length_length_eq in H.
  general induction H; simpl.
  + econstructor.
  + econstructor; eauto.
Qed.

Lemma drop_fold_zip_ounion X `{OrderedType X} A B k
  : (forall n a, get A n a -> length a = length B)
    -> (drop k (fold_left (zip ounion) A B)) =
      fold_left (zip ounion) (List.map (drop k) A) (drop k B).
Proof with eauto 20 using get with len.
  general induction A; simpl; eauto.
  - rewrite IHA...
    + rewrite drop_zip...
Qed.

Lemma zip_AP_mon X Y `{OrderedType Y}
      (AP:list (set Y)) (DL:list X) (f:X -> set Y  -> set Y)
      (LEN:length DL = length AP)
  : (forall x y, y ⊆ f x y)
    -> PIR2 Subset AP (zip f DL AP).
Proof.
  length_equify.
  general induction LEN; simpl; eauto using PIR2.
Qed.

Lemma computeParameters_AP_LV DL ZL AP s lv an' LV
:live_sound FunctionalAndImperative (zip pair DL ZL) s lv
  -> computeParameters (zip lminus DL ZL) ZL AP s lv = (an', LV)
  -> length AP = length DL
  -> length DL = length ZL
  -> PIR2 (ifSndR Subset) AP LV.
Proof.
  intros LS CPEQ LEQ.
  general induction LS; simpl in * |- *; repeat let_case_eq; invc CPEQ.
  - exploit IHLS; eauto using addParam_zip_lminus_length.
    eapply PIR2_ifSndR_right. eapply H3.
    eapply PIR2_addParam; eauto.
    rewrite zip_length2; eauto.
  - exploit IHLS1; eauto.
    exploit IHLS2; eauto.
    exploit computeParameters_length; try eapply eq; eauto.
    exploit computeParameters_length; try eapply eq0; eauto.
    eapply ifSndR_zip_ounion; eauto.
  - clear_all. unfold killExcept, mapi. generalize 0.
    general induction AP; simpl. econstructor.
    destruct if; eauto using PIR2, @ifSndR.
  - clear_all. unfold mapi. generalize 0.
    general induction AP; simpl; eauto using PIR2, @ifSndR.
  - exploit IHLS; eauto using addParam_zip_lminus_length.
    eapply PIR2_ifSndR_right. eapply H3.
    eapply PIR2_addParam; eauto.
    rewrite zip_length2; eauto.
  - eapply ifSndR_addAdds; eauto 20 with len.
    rewrite drop_fold_zip_ounion.
    eapply ifSndR_fold_zip_ounion.
    + clear IHLS. intros.
      inv_map H5. inv_map H6.
      destruct x0 as (an, LV).
      inv_zip H7. rewrite <- zip_app in H10; eauto with len.
      exploit H1; try eapply H10; clear H1; eauto 20 using live_globals_zip with len.
      rewrite (take_eta (length F) LV) in H11.
      unfold addParams in H11.
      rewrite zip_app in H11; eauto with len.
      rewrite zip_app in H11; eauto with len.
      eapply PIR2_app' in H11.
      * dcr. simpl in *.
        eapply PIR2_ifSndR_right; eauto with len.
        eapply zip_AP_mon; eauto with len.
      * eapply zip_length_ass. eauto with len.
        rewrite take_less_length. eauto with len.
        eapply computeParameters_length in H10; eauto 20 with len.
        rewrite H10. rewrite app_length, map_length. omega.
        rewrite <- live_globals_zip; eauto with len.
    + rewrite <- zip_app in eq; eauto with len.
      exploit IHLS; [ eauto
                    | eapply live_globals_zip; eauto with len
                    | eapply eq
                    | | | ]; eauto 20 with len.
      eapply PIR2_ifSndR_right. eapply PIR2_drop; eauto.
      unfold addParams. rewrite drop_zip; eauto 20 with len.
      rewrite zip_app; eauto with len.
      repeat rewrite drop_length_ass; eauto with len.
      eapply zip_AP_mon; eauto with len.
    + rewrite live_globals_zip in H0; eauto with len.
      intros. inv_map H5. destruct x as [an LV].
      inv_zip H6. rewrite <- zip_app in H9; eauto with len.
      eapply computeParameters_length in H9; eauto 20 with len. simpl.
      rewrite H9.
      rewrite <- zip_app in eq; eauto with len.
      eapply computeParameters_length in eq; eauto 20 with len.
      rewrite <- live_globals_zip; eauto with len.
Qed.

Inductive ifFstR {X Y} (R:X -> Y -> Prop) : option X -> Y -> Prop :=
  | IfFstR_None y : ifFstR R None y
  | IfFstR_R x y : R x y -> ifFstR R (Some x) y.

Lemma ifFstR_zip_ounion {X} `{OrderedType X} A B C
: PIR2 (ifFstR Subset) A C
  -> PIR2 (ifFstR Subset) B C
  -> PIR2 (ifFstR Subset) (zip ounion A B) C.
Proof.
  intros.
  general induction H0.
  - inv H1; econstructor.
  - inv H1.
    inv pf; inv pf0; simpl; try now (econstructor; [econstructor; eauto| eauto]).
    econstructor; eauto. econstructor.
    cset_tac; intuition.
Qed.

Lemma ifFstR_addAdds s A B
: PIR2 (ifFstR Subset) B  A
  -> PIR2 (ifFstR Subset) (addAdds s A B) A.
Proof.
  intros.
  general induction H; simpl.
  + constructor.
  + econstructor; eauto.
    - inv pf; simpl; econstructor.
      * cset_tac; intuition.
Qed.

Lemma addParam_Subset x DL AP
: PIR2 Subset AP DL
  -> PIR2 Subset (addParam x DL AP) DL.
Proof.
  intros. general induction H; simpl.
  - constructor.
  - econstructor. destruct if; eauto.
    + cset_tac.
    + eauto.
Qed.

Lemma addParams_Subset2 Z DL AP
: PIR2 Subset AP DL
  -> PIR2 Subset (addParams Z DL AP) DL.
Proof.
  intros. general induction H; simpl.
  + econstructor.
  + econstructor; eauto.
    cset_tac; intuition.
Qed.


Lemma computeParameters_LV_DL DL ZL AP s lv an' LV
:live_sound FunctionalAndImperative (zip pair DL ZL) s lv
  -> computeParameters (zip lminus DL ZL) ZL AP s lv = (an', LV)
  -> length AP = length DL
  -> length DL = length ZL
  -> PIR2 Subset AP (zip lminus DL ZL)
  -> PIR2 (ifFstR Subset) LV (zip lminus DL ZL).
Proof.
  intros LS CPEQ LEQ.
  general induction LS; simpl in * |- *; repeat let_case_eq; invc CPEQ.
  - exploit IHLS; eauto using addParam_zip_lminus_length.
    eapply addParam_Subset; eauto.
  - exploit IHLS1; eauto.
    exploit IHLS2; eauto.
    exploit computeParameters_length; try eapply eq; eauto.
    exploit computeParameters_length; try eapply eq0; eauto.
    eapply ifFstR_zip_ounion; eauto.
  - revert LEQ H4 H3. clear_all; intros. eapply length_length_eq in LEQ.
    eapply length_length_eq in H3.
    unfold killExcept, mapi. generalize 0.
    general induction LEQ; inv H3; simpl. econstructor. inv H4.
    destruct if; econstructor; eauto. constructor; eauto.
    econstructor.
  - revert LEQ H0. clear_all. unfold mapi. generalize 0. intros.
    eapply length_length_eq in LEQ. eapply length_length_eq in H0.
    general induction LEQ; inv H0; simpl.
    econstructor.
    econstructor; try econstructor; eauto.
  - exploit IHLS; eauto using addParam_zip_lminus_length.
    eapply addParam_Subset; eauto.
  - rewrite <- zip_app in eq; eauto with len.
    eapply ifFstR_addAdds; eauto.

    exploit IHLS; eauto 20 using live_globals_zip with len.
    admit.

    reflexivity. Focus 2. instantiate (6:=getAnn als::DL).
    instantiate (5:=Z::ZL). eapply eq. reflexivity. simpl.
    rewrite addParams_zip_lminus_length; eauto. simpl; eauto. simpl.
    econstructor; eauto. cset_tac; intuition.
    eapply addParams_Subset2; eauto.
    exploit IHLS2. reflexivity. Focus 2. instantiate (6:=getAnn als::DL).
    instantiate (5:=Z::ZL). eapply eq0. reflexivity. simpl. congruence.
    simpl; eauto. econstructor; eauto. cset_tac; intuition.
    inv X; inv X0. simpl.
    eapply ifFstR_zip_ounion; eauto.
    eapply ifFstR_addAdds; eauto.
Qed.

Lemma ounion_comm {X} `{OrderedType X} (s t:option (set X))
  : option_eq Equal (ounion s t) (ounion t s).
Proof.
  destruct s,t; simpl; try now econstructor.
  - econstructor. cset_tac; intuition.
Qed.

Lemma zip_PIR2 X Y (eqA:Y -> Y -> Prop) (f:X -> X -> Y) l l'
  : (forall x y, eqA (f x y) (f y x))
    -> PIR2 eqA (zip f l l') (zip f l' l).
Proof.
  general induction l; destruct l'; simpl; try now econstructor.
  econstructor; eauto.
Qed.

Lemma PIR2_zip_ounion {X} `{OrderedType X} (b:list (option (set X))) b'
  : length b = length b'
    -> PIR2 (fstNoneOrR Subset) b (zip ounion b b').
Proof.
  intros. eapply length_length_eq in H0.
  general induction H0; simpl.
  - econstructor.
  - econstructor; eauto.
    + destruct x,y; simpl; econstructor; cset_tac; intuition.
Qed.

Lemma PIR2_zip_ounion' {X} `{OrderedType X} (b:list (option (set X))) b'
  : length b = length b'
    -> PIR2 (fstNoneOrR Subset) b (zip ounion b' b).
Proof.
  intros. eapply length_length_eq in H0.
  general induction H0; simpl.
  - econstructor.
  - econstructor; eauto.
    + destruct x,y; simpl; econstructor; cset_tac; intuition.
Qed.

Definition ominus (s : set var) (t : option (set var)) := mdo t' <- t; ⎣s \ t' ⎦.

(*
Lemma zip_contra_ounion DL b b'
  :
    length DL = length b
    -> length b = length b'
    -> zip (fun (s : set var) (t : option (set var)) => mdo t' <- t; ⎣s \ t' ⎦)
          DL b
          ≿ zip (fun (s : set var) (t : option (set var)) => mdo t' <- t; ⎣s \ t' ⎦)
          DL (zip ounion b b').
Proof.
  intros. eapply length_length_eq in H. eapply length_length_eq in H0.
  general induction H; inv H0; simpl.
  - reflexivity.
  - econstructor; eauto.
    + destruct y, y0; simpl; econstructor; unfold flip; cset_tac; intuition.
Qed.
*)

Lemma zip_ominus_contra DL b b'
  : length DL = length b
    -> length b = length b'
    -> PIR2 (fstNoneOrR Subset) b b'
    -> zip ominus DL b ≿ zip ominus DL b'.
Proof.
  intros. eapply length_length_eq in H. eapply length_length_eq in H0.
  general induction H; inv H0; simpl.
  - reflexivity.
  - econstructor; eauto.
    + destruct y, y0; simpl; try now econstructor.
      * inv H1. inv pf. econstructor. unfold flip; cset_tac; intuition.
      * inv H1. inv pf.
    + inv H1. eauto.
Qed.

Lemma addParam_x DL AP x n ap' dl
  : get (addParam x DL AP) n ap'
    -> get DL n dl
    -> x ∉ ap' -> x ∉ dl.
Proof.
  unfold addParam; intros.
  edestruct get_zip as [? []]; eauto; dcr. clear H.
  repeat get_functional; subst.
  destruct if in H2; simpl in *.
  + cset_tac; intuition.
  + cset_tac; intuition.
Qed.

Lemma PIR2_not_in LV x DL AP
: length DL = length AP
  -> PIR2 (ifSndR Subset) (addParam x DL AP) LV
  ->  forall (n : nat) (lv0 dl : set var),
       get LV n ⎣lv0 ⎦ -> get DL n dl -> x ∉ lv0 -> x ∉ dl.
Proof.
  intros LEN LEQ. intros. eapply length_length_eq in LEN.
  general induction n; simpl in *.
  - inv H; inv H0. invc LEN. simpl in LEQ. invc LEQ.
    destruct if in pf; inv pf.
    + exfalso; cset_tac; intuition.
    + eauto.
  - invc H; invc H0. invc LEN. simpl in LEQ. invc LEQ.
    eauto.
Qed.

Lemma zip_bounded DL LV lv x
: length DL = length LV
  -> bounded (List.map Some DL) lv
  -> (forall n lv dl, get LV n (Some lv) -> get DL n dl -> x ∉ lv -> x ∉ dl)
  -> bounded (zip (fun (s : set var) (t : option (set var)) => mdo t' <- t; ⎣s \ t' ⎦) DL LV) (lv \ {{ x }} ).
Proof.
  intros. eapply length_length_eq in H.
  general induction H; simpl; eauto.
  destruct y; simpl in * |- *.
  + split.
    - decide (x0 ∈ s).
      * cset_tac; intuition.
      * exploit H1; eauto using get. cset_tac; intuition.
    - destruct H0; eapply IHlength_eq; eauto.
      intros. eauto using get.
  + eapply IHlength_eq; eauto using get.
Qed.


Lemma restrict_zip_ominus DL LV lv x al
:  length DL = length LV
-> (forall n lv dl, get LV n (Some lv) -> get DL n dl -> x ∉ lv -> x ∉ dl)
-> al \ {{x}} ⊆ lv
->  restrict (zip ominus DL LV) al
 ≿ restrict (zip ominus DL LV) (lv \ {{x}}).
Proof.
  intros. eapply length_length_eq in H.
  general induction H; simpl in *.
  - econstructor.
  - econstructor.
    + destruct y; intros; simpl.
      repeat destruct if; try now econstructor.
      * econstructor. reflexivity.
      * decide (x0 ∈ s). exfalso. eapply n.
        hnf; intros. decide (a === x0). rewrite e in H2.
        exfalso; cset_tac; intuition.
        rewrite <- H1.
        cset_tac; intuition.
        exploit H0; eauto using get.
        exfalso. eapply n. rewrite <- H1. cset_tac; intuition.
      * econstructor.
    + eapply IHlength_eq; eauto using get.
Qed.

Lemma restrict_zip_ominus' DL LV lv x al
:  length DL = length LV
-> (forall n lv dl, get LV n (Some lv) -> get DL n dl -> x ∉ lv -> x ∉ dl)
-> al \ {{x}} ⊆ lv
->  restrict (zip ominus DL LV) al
 ≿ restrict (zip ominus DL LV) (lv \ {{x}}).
Proof.
  intros. eapply length_length_eq in H.
  general induction H; simpl in *.
  - econstructor.
  - econstructor.
    + destruct y; intros; simpl.
      repeat destruct if; try now econstructor.
      * econstructor. reflexivity.
      * decide (x0 ∈ s). exfalso. eapply n.
        hnf; intros. decide (a === x0). rewrite e in H2.
        exfalso; cset_tac; intuition.
        rewrite <- H1.
        cset_tac; intuition.
        exploit H0; eauto using get.
        exfalso. eapply n. rewrite <- H1. cset_tac; intuition.
      * econstructor.
    + eapply IHlength_eq; eauto using get.
Qed.

Lemma get_mapi_impl X Y L (f:nat->X->Y) n x k
 : get L n x
   -> get (mapi_impl f k L) n (f (n+k) x).
Proof.
  intros. general induction H; simpl; eauto using get.
  econstructor. orewrite (S (n + k) = n + (S k)). eauto.
Qed.

Lemma get_mapi X Y L (f:nat->X->Y) n x
 : get L n x
   -> get (mapi f L) n (f n x).
Proof.
  intros. exploit (get_mapi_impl f 0 H); eauto.
  orewrite (n + 0 = n) in X0. eauto.
Qed.

Lemma killExcept_get l AP s
: get AP (counted l) s ->
  get (killExcept l AP) (counted l) (Some s).
Proof.
  intros. exploit (get_mapi (fun (n : nat) (x : set var) => if [n = counted l] then ⎣x ⎦ else ⎣⎦) H); eauto.
  destruct if in X; eauto.
  exfalso; eauto.
Qed.

Lemma restrict_get L s t n
: get L n (Some s)
  -> s ⊆ t
  -> get (restrict L t) n (Some s).
Proof.
  intros. general induction H; simpl.
  + destruct if.
    - econstructor.
    - exfalso; eauto.
    + econstructor; eauto.
Qed.

Transparent addAdds.


Lemma PIR2_addAdds s DL b
: length DL = length b
  -> PIR2 ≼ b (addAdds s DL b).
Proof.
  intros. eapply length_length_eq in H.
  general induction H.
  - econstructor.
  - simpl. econstructor.
    + destruct y.
      * econstructor. cset_tac; intuition.
      * constructor.
    + eauto.
Qed.



Lemma computeParameters_trs DL ZL AP s an' LV lv
: length DL = length ZL
  -> length ZL = length AP
  -> live_sound FunctionalAndImperative (zip pair DL ZL) s lv
  -> computeParameters (zip lminus DL ZL) ZL AP s lv = (an', LV)
  -> PIR2 Subset AP (zip lminus DL ZL)
  -> trs (restrict (zip ominus (zip lminus DL ZL) LV) (getAnn lv))
        (List.map oto_list LV)  s lv an'.
Proof.
  intros. general induction H1; simpl in *.
  - let_case_eq. inv H5.
    eapply trsExp.
    eapply trs_monotone.
    eapply IHlive_sound; try eapply eq; eauto using addParam_Subset.
    rewrite addParam_length. rewrite zip_length.
    rewrite <- H3. rewrite Min.min_idempotent. eauto.
    rewrite zip_length2; congruence.
    exploit computeParameters_AP_LV; eauto; try congruence.
    eapply addParam_zip_lminus_length; congruence.
    exploit computeParameters_length; eauto; try congruence.
    eapply addParam_zip_lminus_length; congruence.
    rewrite restrict_comp_meet.
    assert (SEQ:lv ∩ (lv \ {{x}}) [=] lv \ {{x}}) by (cset_tac; intuition).
    rewrite SEQ. eapply restrict_zip_ominus; eauto.
    rewrite zip_length2; eauto.
    eapply PIR2_not_in; try eapply X. rewrite zip_length2; congruence.
  - repeat let_case_eq. invc H4.
    exploit computeParameters_length; eauto; try congruence. congruence.
    exploit computeParameters_length; try eapply eq; eauto; try congruence.
    congruence.
    econstructor.
    + eapply trs_monotone.
      eapply trs_monotone3'.
      eapply IHlive_sound1; try eapply eq; eauto; try congruence.
      eapply PIR2_zip_ounion. congruence.
      eapply restrict_subset2; eauto.
      eapply zip_ominus_contra; try congruence.
      rewrite zip_length2; congruence.
      rewrite zip_length2; congruence.
      eapply PIR2_zip_ounion; congruence.
    + eapply trs_monotone.
      eapply trs_monotone3'.
      eapply IHlive_sound2; try eapply eq0; eauto.
      eapply PIR2_zip_ounion'. congruence.
      eapply restrict_subset2; eauto.
      eapply zip_ominus_contra; eauto.
      rewrite zip_length2; congruence.
      rewrite zip_length2; congruence.
      eapply PIR2_zip_ounion'; congruence.
  - edestruct get_zip as [? [? []]]; dcr; eauto. inv H10.
    edestruct (get_length_eq _ H9 H4).
    exploit killExcept_get; eauto.
    exploit (zip_get lminus). eapply H7. apply H9.
    exploit (zip_get ominus). eapply X0. eapply X.
    exploit map_get_1. eapply X.
    econstructor.
    eapply restrict_get. eapply X1. unfold lminus.
    simpl in *. cset_tac; intuition.
    eapply X2.
  - econstructor.
  - let_case_eq. inv H5.
    eapply trsExtern.
    eapply trs_monotone.
    eapply IHlive_sound; try eapply eq; eauto using addParam_Subset.
    rewrite addParam_length. rewrite zip_length.
    rewrite <- H3. rewrite Min.min_idempotent. eauto.
    rewrite zip_length2; congruence.
    exploit computeParameters_AP_LV; eauto; try congruence.
    eapply addParam_zip_lminus_length; congruence.
    exploit computeParameters_length; eauto; try congruence.
    eapply addParam_zip_lminus_length; congruence.
    rewrite restrict_comp_meet.
    assert (SEQ:lv ∩ (lv \ {{x}}) [=] lv \ {{x}}) by (cset_tac; intuition).
    rewrite SEQ. eapply restrict_zip_ominus; eauto.
    rewrite zip_length2; eauto.
    eapply PIR2_not_in; try eapply X. rewrite zip_length2; congruence.
  - repeat let_case_eq. invc H4.
    exploit (computeParameters_length (getAnn als::DL) (Z::ZL)); try eapply eq0; simpl; eauto; try congruence.
    exploit (computeParameters_length (getAnn als::DL) (Z::ZL)); try eapply eq; simpl; eauto; try congruence.
    rewrite addParams_zip_lminus_length; congruence.
    exploit (computeParameters_LV_DL (getAnn als::DL) (Z::ZL)); try eapply eq;
    simpl; eauto.
    rewrite addParams_zip_lminus_length; congruence.
    econstructor; eauto. cset_tac; intuition.
    eapply addParams_Subset2; eauto.
    exploit (computeParameters_LV_DL (getAnn als::DL) (Z::ZL)); try eapply eq0;
    simpl; eauto.
    congruence.
    econstructor; eauto. cset_tac; intuition.
    econstructor.
    + inv X1; inv X2.
      exploit trs_monotone3'.
      eapply (IHlive_sound1 (getAnn als::DL) (Z::ZL)); simpl; eauto; try congruence.
      simpl. rewrite addParams_zip_lminus_length; congruence.
      econstructor. cset_tac; intuition.
      eapply addParams_Subset2; eauto.
      instantiate (1:= (ounion x x0 :: zip ounion (addAdds (oget (ounion x x0))
                              (zip lminus DL ZL) XL) XL0)).
      simpl.
      econstructor.  unfold lminus in *.
      inv pf; inv pf0; econstructor; simpl.
      clear_all; cset_tac; intuition.
      clear_all; cset_tac; intuition.
      simpl in *.
      transitivity (zip ounion XL XL0).
      eapply PIR2_zip_ounion; congruence.
      eapply PIR2_ounion_AB; try congruence; try reflexivity.
      rewrite addAdds_length. rewrite zip_length2; congruence.
      rewrite zip_length2; congruence.
      eapply PIR2_addAdds. repeat rewrite zip_length2; eauto; congruence.
      eapply trs_monotone. simpl.
      simpl addAdds in X3.
      destruct (ounion x x0). simpl in *.
      assert (s0 ∩ (getAnn als \ of_list Z) ∪ s0 [=] s0).
      cset_tac; intuition. eapply trs_AP_seteq. eapply X3.
      econstructor; try reflexivity.
      simpl in X3. eapply X3.
      simpl.
      econstructor. destruct if.
      destruct x, x0; simpl; try now econstructor.
      * repeat destruct if; unfold lminus in * |- *. econstructor.
      unfold flip; clear_all. repeat rewrite of_list_app.
      rewrite of_list_3. cset_tac; intuition.
      exfalso; intuition.
      * unfold lminus. destruct if.
        econstructor.
        unfold flip; clear_all. repeat rewrite of_list_app.
        rewrite of_list_3. cset_tac; intuition.
        econstructor.
      * exfalso. eapply n. reflexivity.
      * rewrite restrict_comp_meet.
        assert (lv ∩ (getAnn als \ of_list (Z ++ oto_list (ounion x x0)))
               [=] (getAnn als \ of_list (Z ++ oto_list (ounion x x0)))).
        repeat rewrite of_list_app. cset_tac; intuition.
        rewrite H4.
        exploit (computeParameters_AP_LV (getAnn als::DL) (Z::ZL)); try eapply eq; simpl; eauto; simpl; eauto; try congruence.
        rewrite addParams_zip_lminus_length; congruence.
        simpl in *.
        assert (length XL = length XL0) by congruence. inv X4.
        revert H2 H3 H6 pf pf0 H H7 H8 H10. clear_all.
        repeat rewrite of_list_app.
        intros.
        length_equify.
        general induction H; inv H0; inv H1; inv H5; inv H6; inv H7; simpl; try econstructor; eauto.
        inv H2; inv H3; inv pf; inv pf0; inv pf1; simpl; try now econstructor.
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. repeat rewrite of_list_3. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. repeat rewrite of_list_3. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. repeat rewrite of_list_3. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. repeat rewrite of_list_3. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. repeat rewrite of_list_3. cset_tac; intuition. }
        {repeat destruct if; try now (econstructor; hnf; cset_tac; intuition).
        exfalso. eapply n. repeat rewrite of_list_3. cset_tac; intuition. }
   +  inv X1; inv X2.
      exploit trs_monotone3'.
      eapply (IHlive_sound2 (getAnn als::DL) (Z::ZL)); simpl; eauto; simpl; try congruence.
      econstructor. cset_tac; intuition. eauto.
      instantiate (1:= (ounion x x0 :: zip ounion (addAdds (oget (ounion x x0))
                              (zip lminus DL ZL) XL) XL0)).
      simpl. econstructor.
      destruct x,x0; simpl; econstructor.
      clear_all; cset_tac; intuition.
      clear_all; cset_tac; intuition.
      simpl.       simpl in *.
      transitivity (zip ounion XL XL0).
      eapply PIR2_zip_ounion'; eauto; congruence.
      eapply PIR2_ounion_AB; try congruence; try reflexivity.
      rewrite addAdds_length. rewrite zip_length2; congruence.
      rewrite zip_length2; congruence.
      eapply PIR2_addAdds. repeat rewrite zip_length2; eauto; congruence.
      eapply trs_monotone. simpl in X1.
      simpl. destruct (ounion x x0). simpl in *.
      eapply trs_AP_seteq. eapply X3.
      econstructor; try reflexivity.
      eapply X3.
      econstructor. destruct x,x0. simpl.
      destruct if. unfold lminus. econstructor.
      unfold flip; clear_all. repeat rewrite of_list_app.
      rewrite of_list_3. cset_tac; intuition.
      econstructor.
      simpl. econstructor.
      simpl. destruct if.
      constructor. unfold flip, lminus; clear_all. repeat rewrite of_list_app.
      rewrite of_list_3. cset_tac; intuition.
      econstructor.
      simpl. simpl in *. econstructor.
      eapply restrict_subset2; eauto.
      eapply zip_ominus_contra.
      rewrite zip_length2; eauto. simpl in *; congruence.
      rewrite zip_length2; eauto.
      rewrite addAdds_length. rewrite zip_length2; eauto.
      repeat rewrite zip_length2; eauto.
      simpl. simpl in *. eauto; congruence.
      rewrite addAdds_length. rewrite zip_length2; eauto.
      simpl. simpl in *. eauto; congruence.
      repeat rewrite zip_length2; eauto.
      simpl. simpl in *. eauto; congruence.
      eapply PIR2_trans. eapply fstNoneOrR_flip_Subset_trans2.
      reflexivity. simpl.
      eapply PIR2_zip_ounion'.
      rewrite addAdds_length. rewrite zip_length2; eauto.
      rewrite zip_length2; eauto. symmetry; simpl in *; congruence.
Qed.

Print Assumptions computeParameters_trs.

Definition oemp X `{OrderedType X} (s : option (set X)) :=
  match s with
    | ⎣s0 ⎦ => s0
    | ⎣⎦ => ∅
  end.

Arguments oemp [X] {H} s.

Lemma additionalParameters_live_monotone (LV':list (option (set var))) DL ZL s an' LV lv
: length DL = length ZL
  -> live_sound FunctionalAndImperative (zip pair DL ZL) s lv
  -> additionalParameters_live LV s lv an'
  -> PIR2 (ifFstR Subset) LV' (zip lminus DL ZL)
  -> additionalParameters_live (List.map (@oemp var _) LV') s lv an'.
Proof.
  intros. general induction H1; invt live_sound; eauto using additionalParameters_live.
  - edestruct get_zip as [? [? []]]; dcr; subst; eauto. invc H8.
    edestruct PIR2_nth_2; eauto. eapply zip_get; eauto.
    dcr.
    econstructor.
    eapply map_get_1; eauto. simpl in *. rewrite <- H9.
    inv H12; simpl. cset_tac; intuition. eapply H5.
  - econstructor; eauto.
    exploit (IHadditionalParameters_live1 (Some (of_list Za)::LV') (getAnn ans_lv::DL) (Z::ZL0)); simpl; try congruence.
    econstructor; eauto. econstructor. unfold lminus.
    rewrite H. reflexivity.
    eapply X.
    exploit (IHadditionalParameters_live2 (Some (of_list Za)::LV') (getAnn ans_lv::DL) (Z::ZL0)); simpl; try congruence.
    econstructor; eauto. econstructor. rewrite H; reflexivity.
    eauto.
Qed.

Lemma computeParameters_live DL ZL AP s an' LV lv
: length DL = length ZL
  -> length ZL = length AP
  -> live_sound FunctionalAndImperative (zip pair DL ZL) s lv
  -> computeParameters (zip lminus DL ZL) ZL AP s lv = (an', LV)
  -> PIR2 Subset AP (zip lminus DL ZL)
  -> additionalParameters_live (List.map (@oemp _ _) LV) s lv an'.
Proof.
  intros.
  general induction H1; simpl in *.
  - let_case_eq; inv H5.
    econstructor. eapply IHlive_sound; try eapply eq; eauto using addParam_Subset.
    rewrite addParam_length; rewrite zip_length2; eauto; congruence.
  - repeat let_case_eq; invc H4.
    exploit computeParameters_LV_DL; try eapply eq0; eauto. congruence.
    exploit computeParameters_LV_DL; try eapply eq; eauto. congruence.
    econstructor; eauto.
    eapply additionalParameters_live_monotone; eauto.
    eapply ifFstR_zip_ounion; eauto.
    eapply additionalParameters_live_monotone; eauto.
    eapply ifFstR_zip_ounion; eauto.
  - edestruct get_zip as [? [? []]]; dcr; subst; eauto. invc H10.
    edestruct PIR2_nth_2; eauto. eapply zip_get; eauto. dcr.
    econstructor. eapply map_get_1; eauto. eapply killExcept_get; eauto.
    simpl. rewrite <- H0. eapply H11.
  - econstructor.
  - let_case_eq; inv H5.
    econstructor. eapply IHlive_sound; try eapply eq; eauto using addParam_Subset.
    rewrite addParam_length; rewrite zip_length2; eauto; congruence.
  - repeat let_case_eq. invc H4.
    exploit (computeParameters_LV_DL (getAnn als::DL) (Z::ZL)); try eapply eq; eauto; simpl; try congruence. rewrite addParams_length, zip_length2; try congruence.
    rewrite zip_length2; congruence.
    econstructor; eauto. cset_tac; intuition. eapply addParams_Subset2. eauto.
    exploit (computeParameters_LV_DL (getAnn als::DL) (Z::ZL)); try eapply eq0; eauto; simpl; try congruence.
    econstructor; eauto. cset_tac; intuition.
    econstructor. simpl in X,X0.
    inv X; inv X0. simpl. inv pf; inv pf0; simpl.
    eapply incl_empty.
    rewrite of_list_3; eauto.
    rewrite of_list_3; eauto.
    rewrite of_list_3. rewrite H4, H6. rewrite union_idem. reflexivity.
    exploit (IHlive_sound1 (getAnn als::DL) (Z::ZL));
      simpl; eauto.
    simpl. rewrite addParams_length, zip_length2; eauto.
    rewrite zip_length2; congruence.
    constructor. cset_tac; intuition.
    eapply addParams_Subset2; eauto.
    eapply (@additionalParameters_live_monotone
              (Some (of_list (oto_list (ounion (hd ⎣⎦ b0) (hd ⎣⎦ b1))))
                             ::
                             (zip ounion
                                  (addAdds (oget (ounion (hd ⎣⎦ b0) (hd ⎣⎦ b1)))
                                           (zip lminus DL ZL) (tl b0)) (tl b1)))
               (getAnn als::DL) (Z::ZL)).
    simpl. congruence. eauto. eauto. simpl.
    econstructor. constructor. unfold lminus. unfold oto_list.
    simpl in X, X0. inv X; inv X0; simpl.
    inv pf; inv pf0; simpl.
    eapply incl_empty.
    rewrite of_list_3. eauto.
    rewrite of_list_3. eauto.
    rewrite of_list_3. rewrite H6. rewrite H4. rewrite union_idem. reflexivity.
    eapply ifFstR_zip_ounion; eauto.
    eapply ifFstR_addAdds.
    simpl in X, X0. inv X; inv X0; simpl.
    simpl. congruence.
    simpl in X, X0. inv X; inv X0; simpl.
    simpl. congruence.
    exploit (IHlive_sound2 (getAnn als::DL) (Z::ZL)); simpl; eauto.
    simpl. congruence.
    constructor. cset_tac; intuition. eauto.
    eapply (@additionalParameters_live_monotone
              (Some (of_list (oto_list (ounion (hd ⎣⎦ b0) (hd ⎣⎦ b1))))::
                    zip ounion
             (addAdds (oget (ounion (hd ⎣⎦ b0) (hd ⎣⎦ b1)))
                (zip lminus DL ZL) (tl b0)) (tl b1)) (getAnn als::DL) (Z::ZL)).
    simpl. congruence.
    eauto. eauto. simpl.
    econstructor. constructor. unfold lminus. unfold oto_list.
    simpl in X, X0. inv X; inv X0; simpl.
    inv pf; inv pf0; simpl.
    eapply incl_empty.
    rewrite of_list_3. eauto.
    rewrite of_list_3. eauto.
    rewrite of_list_3. rewrite H6. rewrite H4. rewrite union_idem. reflexivity.
    eapply ifFstR_zip_ounion; eauto.
    eapply ifFstR_addAdds.
    simpl in X, X0. inv X; inv X0; simpl. eauto.
    simpl in X, X0. inv X; inv X0; simpl. eauto.
Qed.
