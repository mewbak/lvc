Require Import List Map Env AllInRel Exp MoreList.
Require Import IL Annotation.
Require Import Liveness.Liveness.
Require Import ExpVarsBounded SpillSound OneOrEmpty.



Set Implicit Arguments.

(** * Register Liveness *)

Fixpoint reg_live 
         (ZL : list params)
         (Lv : list ⦃var⦄)
         (G : ⦃var⦄)
         (s : stmt)
         (sl : spilling)
         {struct s}
  : ann ⦃var⦄
  :=
    match s, sl with
    | stmtLet x e s, ann1 (Sp, L, _) sl'
      => let lv_s := reg_live ZL Lv (singleton x) s sl' in
        (* subtracting L might lead to unnecessary gaps in the liveness, but this is ok:
           variables are killed from the register directly after their last use *)
        ann1 (G ∪ Sp ∪ (((getAnn lv_s) \ singleton x ∪ Exp.freeVars e) \ L)) lv_s

    | stmtReturn e, ann0 (Sp, L, _)
      => ann0 (G ∪ Sp ∪ (Op.freeVars e \ L))

    | stmtIf e s1 s2, ann2 (Sp, L, _) sl1 sl2
      => let lv1 := reg_live ZL Lv ∅ s1 sl1 in
        let lv2 := reg_live ZL Lv ∅ s2 sl2 in
        ann2 (G ∪ Sp ∪ ((getAnn lv1 ∪ getAnn lv2 ∪ Op.freeVars e) \ L)) lv1 lv2

    | stmtApp f Y, ann0 (Sp, L, (_,Sl)::nil)
      => let blv := nth (counted f) Lv ∅ in
        let Z   := nth (counted f) ZL nil in
        ann0 (G ∪ Sp ∪ (((list_union (Op.freeVars ⊝ Y) \ Sl) ∪ blv \ of_list Z) \ L))

    | stmtFun F t, annF (Sp, L, rms) sl_F sl_t
      => let lv_t := reg_live (fst ⊝ F ++ ZL) (fst ⊝ rms ++ Lv) ∅ t sl_t in
        let lv_F := (fun ps sl_s => reg_live (fst ⊝ F   ++ ZL)
                                          (fst ⊝ rms ++ Lv)
                                          (of_list (fst ps))
                                          (snd ps)
                                           sl_s
                    ) ⊜ F sl_F in
        annF (G ∪ Sp ∪ ((getAnn lv_t ∪ G) \ L)) lv_F lv_t

    | _,_ => ann0 G
    end
.



Inductive rlive_sound
  : list params -> list (set var) -> stmt -> spilling -> ann (set var) -> Prop :=
| RLiveLet ZL Lv x e s Sp L sl lv (al:ann (set var))
  :  Sp ⊆ lv
     -> rlive_sound ZL Lv s sl al
     -> live_exp_sound e (lv ∪ L)
     -> (getAnn al \ singleton x) ⊆ lv ∪ L
     -> x ∈ getAnn al
     -> rlive_sound ZL Lv (stmtLet x e s) (ann1 (Sp,L,nil) sl) (ann1 lv al)
| RLiveIf Lv ZL e s1 s2 Sp L sl1 sl2 lv al1 al2
  :  Sp ⊆ lv
     -> rlive_sound ZL Lv s1 sl1 al1
     -> rlive_sound ZL Lv s2 sl2 al2
     -> live_op_sound e (lv ∪ L)
     -> getAnn al1 ⊆ lv ∪ L
     -> getAnn al2 ⊆ lv ∪ L
     -> rlive_sound ZL Lv (stmtIf e s1 s2) (ann2 (Sp,L,nil) sl1 sl2) (ann2 lv al1 al2)
| RLiveApp ZL Lv l Y Sp L R' M' lv blv Z
  : Sp ⊆ lv
    -> get ZL (counted l) Z
    -> get Lv (counted l) blv
    -> (blv \ of_list Z) ⊆ lv ∪ L
    -> (forall n y, get Y n y -> live_op_sound y (lv ∪ M' ∪ L))
    -> rlive_sound ZL Lv (stmtApp l Y) (ann0 (Sp,L,(R',M')::nil)) (ann0 lv)
| RLiveReturn ZL Lv e Sp L lv
  : Sp ⊆ lv
    -> live_op_sound e (lv ∪ L)
    -> rlive_sound ZL Lv (stmtReturn e) (ann0 (Sp,L,nil)) (ann0 lv)
| RLiveFun ZL Lv F t lv Sp L rms sl_F sl_t als alb
  : Sp ⊆ lv
    -> rlive_sound (fst ⊝ F ++ ZL) (getAnn ⊝ als ++ Lv) t sl_t alb
    -> length F = length als
    -> (forall n Zs a sl_s, get F n Zs ->
                 get als n a ->
                 get sl_F n sl_s ->
                 rlive_sound (fst ⊝ F ++ ZL) (getAnn ⊝ als ++ Lv) (snd Zs) sl_s a)
    -> (forall n Zs a, get F n Zs -> (* do I need this? *)
                 get als n a ->
                 (of_list (fst Zs)) ⊆ getAnn a) (* don't add L here *)
    -> getAnn alb ⊆ lv ∪ L
    -> rlive_sound ZL Lv (stmtFun F t) (annF (Sp,L,rms) sl_F sl_t) (annF lv als alb)
.


Lemma reg_live_G_eq
      (G : ⦃var⦄)
      (Lv : list ⦃var⦄)
      (ZL : list params)
      (s : stmt)
      (sl : spilling)
  :
    getAnn (reg_live ZL Lv G s sl)
           [=]
           getAnn (reg_live ZL Lv ∅ s sl) ∪ G
.
Proof.
  general induction s;
    destruct sl;
    try destruct a;
    try destruct p;
    simpl; eauto; try cset_tac.
  induction l0; simpl; eauto.
  - cset_tac.
  - destruct a. destruct l0; simpl; cset_tac. 
Qed.



(* remove ? 
Lemma reconstr_live_remove_G
      Lv ZL G s sl G'
  :
    getAnn (reconstr_live Lv ZL G s sl) \ G
           ⊆ getAnn (reconstr_live Lv ZL G' s sl)
.
Proof.
  destruct s, sl, a; simpl; cset_tac.
Qed.
*)



Lemma reg_live_G
      (Lv : list (set var))
      (ZL : list (params))
      (G : set var)
      (s : stmt)
      (sl : spilling)
  :
    G ⊆ getAnn (reg_live ZL Lv G s sl)
.
Proof.
  induction s,sl; destruct a,p;
    simpl; eauto with cset.
  - simpl. induction l0; simpl; eauto with cset.
    destruct a,l0; simpl; cset_tac.
Qed.

Require Import Subterm.

Inductive subAnno (X:Type) : ann X -> ann X -> Prop :=
    subAnno_refl (a : ann X) : subAnno a a
  | subAnno1 (a b : ann X) (x : X) :
      subAnno a b -> subAnno a (ann1 x b)
  | subAnno21 (a b b' : ann X) (x : X) :
      subAnno a b -> subAnno a (ann2 x b b')
  | subAnno22 (a b b' : ann X) (x : X) :
      subAnno a b'-> subAnno a (ann2 x b b')
  | subAnnoF1 (a b : ann X) (bF : list (ann X)) (x : X) :
      subAnno a b -> subAnno a (annF x bF b)
  | subAnnoF2 (a b b' : ann X) (bF : list (ann X)) (x : X) (n : nat) :
      get bF n b' -> subAnno a b' -> subAnno a (annF x bF b)
.



Lemma reg_live_sound k ZL Λ rlv (R M : ⦃var⦄) G s sl
  : spill_sound k ZL Λ (R,M) s sl
    -> (forall s' sl',
          subTerm s' s
          -> subAnno sl' sl
          -> match s',sl' with
            | stmtFun F t, annF (_,rms) sl_F _ =>
              forall Zs sl_s rm' n, get rlv n rm'
                              -> get F n Zs
                              -> get sl_F n sl_s
                              -> rm' = getAnn (reg_live ZL rlv (of_list (fst Zs)) (snd Zs) sl_s)
            | _,_ => True
            end)
    -> PIR2 Subset rlv (fst ⊝ Λ) 
    -> rlive_sound ZL rlv s sl (reg_live ZL rlv G s sl)
.
Proof.
  intros spillSnd inR.
  general induction spillSnd.
  - econstructor.
    + apply union_incl_left; clear;cset_tac.
    + eapply IHspillSnd; eauto.
      intros; apply inR; econstructor; eauto.
    + apply live_exp_sound_incl with (lv':=Exp.freeVars e).
      * apply live_freeVars.
      * setoid_rewrite <-incl_right at 4. clear;cset_tac.
    + setoid_rewrite <-incl_right at 3. clear; cset_tac.
    + apply reg_live_G. clear; cset_tac.
  - econstructor.
    + clear; cset_tac.
    + apply live_op_sound_incl with (lv':=Op.freeVars e).
      * apply Op.live_freeVars.
      * clear; cset_tac.
  - econstructor.
    + setoid_rewrite <-incl_right at 3. clear; cset_tac.
    + eapply IHspillSnd1; eauto.
      intros; apply inR; econstructor; eauto.
    + eapply IHspillSnd2; eauto.
      intros; apply inR; econstructor 4; eauto.
    + apply live_op_sound_incl with (lv':=Op.freeVars e).
      * apply Op.live_freeVars.
      * setoid_rewrite <-incl_right at 4. clear; cset_tac.
    + setoid_rewrite <-incl_right at 2. clear; cset_tac.
    + setoid_rewrite <-incl_right at 2. clear; cset_tac.
  - assert (H8' := H8). eapply PIR2_flip in H8'. eapply PIR2_nth in H8'.
    destruct H8', H9.
    econstructor; eauto.
    + clear; cset_tac.
    + simpl. erewrite !get_nth; eauto. clear; cset_tac.
    + intros. inv_get.
      apply live_op_sound_incl with (lv':=Op.freeVars y).
      * apply Op.live_freeVars.
      * erewrite !get_nth; eauto. 
        erewrite <-incl_list_union with (s:=Op.freeVars y); eauto; clear; cset_tac.
    + eauto.
  - econstructor.
    + setoid_rewrite <-incl_right at 3. clear; cset_tac.
    + assert (PIR2 Subset (rlv) (fst ⊝  Λ)) as pir2 by admit.
      set (fix1 := fun (ps : params * stmt) (sl_s : spilling) => _ ).
     Lemma rlive_sound_monotone
     : forall (ZL : 〔params〕) (LV LV' : 〔⦃nat⦄〕) (s : stmt) (sl : spilling) (rlv : ann ⦃nat⦄),
          rlive_sound ZL LV s sl rlv -> PIR2 Subset LV' LV -> rlive_sound ZL LV' s sl rlv.
       Admitted.

     eapply rlive_sound_monotone with (LV := fst ⊝ rms ++ rlv).
     eapply IHspillSnd; eauto.
      * admit.
      * rewrite List.map_app. apply PIR2_app; [apply PIR2_refl|]; eauto.
      * apply PIR2_app; [|apply PIR2_refl;eauto].
        apply PIR2_get. intros; inv_get.
        -- destruct x. destruct s, x2; subst fix1; simpl. simpl.
        assert (fix1 ⊜ F sl_F = rms
        (*apply map_ext_get.*)  apply zip_ext_PIR2. subst fix1. destruct 
        
      specialize (inR (stmtFun F t) (annF (Sp,L,rms) sl_F sl_t)). simpl in inR.
      Require Import ReconstrLiveSmall.
      rewrite <- inR.
    + admit. (* THIS will most likely need another invariant *)
    + intros; inv_get. admit.
    + intros; inv_get. apply reg_live_G. 
    + clear; cset_tac.

