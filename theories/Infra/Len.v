Require Import Smpl.

Create HintDb len discriminated.

Smpl Create len.
Ltac len_simpl := smpl len; repeat (smpl len).
Hint Extern 0 => len_simpl : len.
