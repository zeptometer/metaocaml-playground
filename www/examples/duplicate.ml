(* 2. Failed attempt (1): squaring by splicing the same code twice *)

let rec spower n x =
  if n = 0 then .< 1 >.
  else if n = 1 then x
  else if n mod 2 = 1 then .< .~x * .~(spower (n - 1) x) >.
  else let x2 = spower (n / 2) x in .< .~x2 * .~x2 >.

(* Generated code for x^11: .~x2 is spliced twice, so the code it stands
   for is copied, and the same computation is done twice *)
let power11_code = .< fun x -> .~(spower 11 .< x >.) >.

(* Compile it, then use it like any other function *)
let power11 = Runcode.run power11_code

let () = Printf.printf "2^11 = %d\n" (power11 2)
