Ltac let_unfold id :=
  cbv beta delta [id];
  repeat match goal with
         | [ |- context [ let s := ?e in _ ] ] =>
           let s := fresh s in set (s:=e) in *
         | [ |- context [let (a, b) := ?e in _] ] =>
           let a := fresh a in let b := fresh b in case_eq e; intros b a ?
         | [ H : ?x = (?s, ?t) |- _ ] =>
           assert (fst x = s) by (rewrite H; eauto);
             assert (snd x = t) by (rewrite H; eauto); clear H
         | [ |- context f [ let s := ?e in @?t s ] ] =>
           is_var e;
             let s := eval cbv beta in (t s) in
                 let x := context f[s] in
                 change x
         end.

Ltac let_unfold' id H :=
  cbv beta delta [id] in H;
  repeat match type of H with
         | context [ let s := ?e in _ ] => set (s:=e) in *
         | context f [ let s := ?e in @?t s ] =>
           is_var e;
             let s := eval cbv beta in (t s) in
                 let x := context f[s] in
                 change x in H
         end.

Tactic Notation "refold" :=
  repeat match goal with
         | [ x := ?e |- context f [ ?e ]] =>
           let y := context f[x] in
           change y
         end.
