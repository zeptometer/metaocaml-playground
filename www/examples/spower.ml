(* Welcome to the MetaOCaml playground!
   .< e >.   quotes e as code (a value of type 'a code)
   .~ e      splices the code value e into a quotation
   Runcode.run c   compiles and runs the code value c *)

(* A staged power function: the recursion happens at generation time *)
let rec spower n x =
  if n = 0 then .< 1 >.
  else if n mod 2 = 0 then .< let y = .~(spower (n / 2) x) in y * y >.
  else .< .~x * .~(spower (n - 1) x) >.

(* Generated code for x^7 *)
let power7_code = .< fun x -> .~(spower 7 .< x >.) >.

(* Compile it, then use it like any other function *)
let power7 = Runcode.run power7_code

let () = Printf.printf "2^7 = %d\n" (power7 2)
