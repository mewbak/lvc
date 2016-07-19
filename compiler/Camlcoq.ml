(* *********************************************************************)
(*                                                                     *)
(*              The Compcert verified compiler                         *)
(*                                                                     *)
(*          Xavier Leroy, INRIA Paris-Rocquencourt                     *)
(*                                                                     *)
(*  Copyright Institut National de Recherche en Informatique et en     *)
(*  Automatique.  All rights reserved.  This file is distributed       *)
(*  under the terms of the GNU General Public License as published by  *)
(*  the Free Software Foundation, either version 2 of the License, or  *)
(*  (at your option) any later version.  This file is also distributed *)
(*  under the terms of the INRIA Non-Commercial License Agreement.     *)
(*                                                                     *)
(* *********************************************************************)

(* Library of useful Caml <-> Coq conversions *)

open Datatypes
open BinNums
open BinNat
open BinInt
open BinPos

(* Coq's [positive] type and some of its operations *)

module P = struct

  type t = positive = Coq_xI of t | Coq_xO of t | Coq_xH

  let one = Coq_xH
  let succ = Pos.succ
  (*  let pred = Pos.pred *)
  let add = Pos.add
  (* let sub = Pos.sub *)
  let eq x y = (Pos.compare x y = Eq)
  let lt x y = (Pos.compare x y = Lt)
  let gt x y = (Pos.compare x y = Gt)
  let le x y = (Pos.compare x y <> Gt)
  let ge x y = (Pos.compare x y <> Lt)
  let compare x y = match Pos.compare x y with Lt -> -1 | Eq -> 0 | Gt -> 1

  let rec to_int = function
  | Coq_xI p -> let n = to_int p in n + n + 1
  | Coq_xO p -> let n = to_int p in n + n
  | Coq_xH -> 1

  let rec of_int n =
    if n land 1 = 0 then
      if n = 0 then assert false else Coq_xO (of_int (n lsr 1))
    else
      if n = 1 then Coq_xH else Coq_xI (of_int (n lsr 1))

  let rec to_int32 = function
  | Coq_xI p -> Int32.add (Int32.shift_left (to_int32 p) 1) 1l
  | Coq_xO p -> Int32.shift_left (to_int32 p) 1
  | Coq_xH -> 1l

  let rec of_int32 n =
    if Int32.logand n 1l = 0l then
      if n = 0l
      then assert false
      else Coq_xO (of_int32 (Int32.shift_right_logical n 1))
    else
      if n = 1l
      then Coq_xH
      else Coq_xI (of_int32 (Int32.shift_right_logical n 1))

  let rec to_int64 = function
  | Coq_xI p -> Int64.add (Int64.shift_left (to_int64 p) 1) 1L
  | Coq_xO p -> Int64.shift_left (to_int64 p) 1
  | Coq_xH -> 1L

  let rec of_int64 n =
    if Int64.logand n 1L = 0L then
      if n = 0L
      then assert false
      else Coq_xO (of_int64 (Int64.shift_right_logical n 1))
    else
      if n = 1L
      then Coq_xH
      else Coq_xI (of_int64 (Int64.shift_right_logical n 1))

  let (+) = add
  (*  let (-) = sub *)
  let (=) = eq
  let (<) = lt
  let (<=) = le
  let (>) = gt
  let (>=) = ge

end

(* Coq's [Z] type and some of its operations *)

module Z = struct

  type t = coq_Z = Z0 | Zpos of positive | Zneg of positive

  let zero = Z0
  let one = Zpos Coq_xH
  let mone = Zneg Coq_xH
  (*  let succ = Z.succ *)
  let pred = Z.pred
  let neg = Z.opp
  let add = Z.add
  let sub = Z.sub
  let mul = Z.mul
  let eq x y = (Z.compare x y = Eq)
  let lt x y = (Z.compare x y = Lt)
  let gt x y = (Z.compare x y = Gt)
  let le x y = (Z.compare x y <> Gt)
  let ge x y = (Z.compare x y <> Lt)
  let compare x y = match Z.compare x y with Lt -> -1 | Eq -> 0 | Gt -> 1

  let to_int = function
  | Z0 -> 0
  | Zpos p -> P.to_int p
  | Zneg p -> - (P.to_int p)

  let of_sint n =
    if n = 0 then Z0 else
    if n > 0 then Zpos (P.of_int n)
    else Zneg (P.of_int (-n))

  let of_uint n =
    if n = 0 then Z0 else Zpos (P.of_int n)

  let to_int32 = function
  | Z0 -> 0l
  | Zpos p -> P.to_int32 p
  | Zneg p -> Int32.neg (P.to_int32 p)

  let of_sint32 n =
    if n = 0l then Z0 else
    if n > 0l then Zpos (P.of_int32 n)
    else Zneg (P.of_int32 (Int32.neg n))

  let of_uint32 n =
    if n = 0l then Z0 else Zpos (P.of_int32 n)

  let to_int64 = function
  | Z0 -> 0L
  | Zpos p -> P.to_int64 p
  | Zneg p -> Int64.neg (P.to_int64 p)

  let of_sint64 n =
    if n = 0L then Z0 else
    if n > 0L then Zpos (P.of_int64 n)
    else Zneg (P.of_int64 (Int64.neg n))

  let of_uint64 n =
    if n = 0L then Z0 else Zpos (P.of_int64 n)

  let of_N = Z.of_N

  let rec to_string_rec base buff x =
    if x = Z0 then () else begin
      let (q, r) = Z.div_eucl x base in
      to_string_rec base buff q;
      let d = to_int r in
      Buffer.add_char buff (Char.chr
        (if d < 10 then Char.code '0' + d
                         else Char.code 'A' + d - 10))
    end

  let to_string_aux base x =
    match x with
    | Z0 -> "0"
    | Zpos _ ->
        let buff = Buffer.create 10 in
        to_string_rec base buff x;
        Buffer.contents buff
    | Zneg p ->
        let buff = Buffer.create 10 in
        Buffer.add_char buff '-';
        to_string_rec base buff (Zpos p);
        Buffer.contents buff

  let dec = to_string_aux (of_uint 10)

  let hex = to_string_aux (of_uint 16)

  let to_string = dec

  let (+) = add
  let (-) = sub
  let ( * ) = mul
  let (=) = eq
  let (<) = lt
  let (<=) = le
  let (>) = gt
  let (>=) = ge
end


(* Alternate names *)

let camlint_of_coqint : Integers.Int.int -> int32 = Z.to_int32
let coqint_of_camlint : int32 -> Integers.Int.int = Z.of_uint32

(* Atoms (positive integers representing strings) *)

type atom = positive

let atom_of_string = (Hashtbl.create 17 : (string, atom) Hashtbl.t)
let string_of_atom = (Hashtbl.create 17 : (atom, string) Hashtbl.t)
let next_atom = ref Coq_xH

let intern_string s =
  try
    Hashtbl.find atom_of_string s
  with Not_found ->
    let a = !next_atom in
    next_atom := Pos.succ !next_atom;
    Hashtbl.add atom_of_string s a;
    Hashtbl.add string_of_atom a s;
    a
let extern_atom a =
  try
    Hashtbl.find string_of_atom a
  with Not_found ->
    Printf.sprintf "$%d" (P.to_int a)

let first_unused_ident () = !next_atom

(* Strings *)

let camlstring_of_coqstring (s: char list) =
  let r = Bytes.create (List.length s) in
  let rec fill pos = function
  | [] -> r
  | c :: s -> Bytes.set r pos c; fill (pos + 1) s
  in Bytes.to_string (fill 0 s)

let coqstring_of_camlstring s =
  let rec cstring accu pos =
    if pos < 0 then accu else cstring (s.[pos] :: accu) (pos - 1)
  in cstring [] (String.length s - 1)

let coqstring_uppercase_ascii_of_camlstring s =
  let rec cstring accu pos =
    if pos < 0 then accu else
    let d = if s.[pos] >= 'a' && s.[pos] <= 'z' then
      Char.chr (Char.code s.[pos] - 32)
    else
      s.[pos] in
    cstring (d :: accu) (pos - 1)
  in cstring [] (String.length s - 1)
