(* 4. let-insertion with MetaOCaml's genlet and an explicit locus *)

(* genlet ~locus:l c binds c with a let at the locus l, and returns the
   bound variable: squarings are shared instead of being duplicated *)
let rec spower l n x =
  if n = 0 then .< 1 >.
  else if n = 1 then x
  else if n mod 2 = 1 then .< .~x * .~(spower l (n - 1) x) >.
  else spower l (n / 2) (Codelib.genlet ~locus:l .< .~x * .~x >.)

(* Generated code for x^11; the lets are inserted at with_locus *)
let power11_code =
  .< fun x -> .~(Codelib.with_locus (fun l -> spower l 11 .< x >.)) >.

(* Compile it, then use it like any other function *)
let power11 = Runcode.run power11_code

let () = Printf.printf "2^11 = %d\n" (power11 2)
