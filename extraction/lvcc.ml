open Parser
open Lexer
open List
open Util
open Names
open Big
open Pmove

let main () =
  let infile = ref "" in
  let outfile = ref "a.s" in
  let optimize = ref true in
  let set_optimize b = optimize := b in
  let set_infile s = infile:=s in
  let speclist = [
    ("-o",Arg.Set_string outfile, "Place the output into <file>");
    ("-O", Arg.Bool set_optimize, "Enable optimization (default is on)")
  ] in
  let print_string a s = Printf.eprintf "%s" (implode s); a in
  let toString_nstmt s = explode (print_nexpr 0 s !ids) in
  let toString_stmt s = explode (print_expr 0 s !ids) in
  let toString_ann s p a = explode (print_ann (fun s -> implode (p s)) 0 a) in
  let toString_set s = explode (print_set !ids s) in
  let toString_list s = explode (print_list (fun x -> print_var x !ids) "," s) in
    Arg.parse speclist set_infile ("usage: lvc [options]");
    try
      let file_chan = open_in !infile in
      let lexbuf = Lexing.from_channel  file_chan in
      let ilin = Parser.expr Lexer.token lexbuf in
      match Lvc.toILF generic_first print_string toString_nstmt toString_stmt toString_ann toString_set toString_list ilin 0 with
      | (Lvc.Success ilf, _) -> 
	 Printf.printf "toILF compilate:\n%s\n\n" (print_expr 0 ilf !ids);
      | (Lvc.Error e, _) -> Printf.printf "Compilation failed:\n%s" (implode e);
    with Parsing.Parse_error ->
        Printf.eprintf "A parsing error occured \n"
      | Sys_error s-> Printf.eprintf "%s\n" s
      | Compiler_error -> Printf.eprintf "The compilation failed\n\n"
      | Range_error e -> Printf.eprintf "The integer %s is not in range\n" e;;

main ();
