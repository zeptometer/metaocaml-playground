(* 5. let-insertion by writing the generator in CPS *)

(* spower n x k passes x^n to the continuation k; since k is called
   inside the let, the rest of the code can refer to the bound variable *)
let rec spower n x k =
  if n = 0 then k .< 1 >.
  else if n = 1 then k x
  else if n mod 2 = 1 then spower (n - 1) x (fun y -> k .< .~x * .~y >.)
  else .< let x2 = .~x * .~x in .~(spower (n / 2) .< x2 >. k) >.

(* Generated code for x^11 *)
let power11_code = .< fun x -> .~(spower 11 .< x >. (fun y -> y)) >.

(* Compile it, then use it like any other function *)
let power11 = Runcode.run power11_code

let () = Printf.printf "2^11 = %d\n" (power11 2)
