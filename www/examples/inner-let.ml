(* 3. Failed attempt (2): binding the square with a let in place *)

let rec spower n x =
  if n = 0 then .< 1 >.
  else if n = 1 then x
  else if n mod 2 = 1 then .< .~x * .~(spower (n - 1) x) >.
  else .< let x2 = .~x * .~x in .~(spower (n / 2) .< x2 >.) >.

(* Generated code for x^11: nothing is duplicated any more, but each let
   lands where it is generated, in the middle of x * (...), rather than
   at the top of the function body *)
let power11_code = .< fun x -> .~(spower 11 .< x >.) >.

(* Compile it, then use it like any other function *)
let power11 = Runcode.run power11_code

let () = Printf.printf "2^11 = %d\n" (power11 2)
