(* Welcome to the MetaOCaml playground!
   .< e >.   quotes e as code (a value of type 'a code)
   .~ e      splices the code value e into a quotation
   Runcode.run c   compiles and runs the code value c *)

(* 1. A staged power function: the recursion over n happens at generation
   time, leaving only the multiplications in the generated code *)
let rec spower n x =
  if n = 0 then .< 1 >.
  else .< .~x * .~(spower (n - 1) x) >.

(* Generated code for x^11: fun x -> x * x * ... * x * 1 *)
let power11_code = .< fun x -> .~(spower 11 .< x >.) >.

(* Compile it, then use it like any other function *)
let power11 = Runcode.run power11_code

let () = Printf.printf "2^11 = %d\n" (power11 2)
