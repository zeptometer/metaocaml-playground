(* 6. let-insertion with OCaml 5 effect handlers: our own genlet / let_locus.
   genlet performs an effect; the handler at let_locus inserts the let and
   resumes the generator with the new variable. *)

type _ Effect.t += Genlet : 'a code -> 'a code Effect.t

let genlet (c : 'a code) : 'a code = Effect.perform (Genlet c)

let let_locus (body : unit -> 'w code) : 'w code =
  match body () with
  | c -> c
  | effect Genlet c, k ->
    .< let t = .~c in .~(Effect.Deep.continue k .< t >.) >.

(* The generator is the same as in example 4, without the locus argument *)
let rec spower n x =
  if n = 0 then .< 1 >.
  else if n = 1 then x
  else if n mod 2 = 1 then .< .~x * .~(spower (n - 1) x) >.
  else spower (n / 2) (genlet .< .~x * .~x >.)

(* Generated code for x^11; the lets are inserted at let_locus *)
let power11_code = .< fun x -> .~(let_locus (fun () -> spower 11 .< x >.)) >.

(* Compile it, then use it like any other function *)
let power11 = Runcode.run power11_code

let () = Printf.printf "2^11 = %d\n" (power11 2)
