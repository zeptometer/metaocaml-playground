(* 7. Practice: staging gibonacci

   gib m n1 n2 is the m-th value of the Fibonacci-like sequence whose first
   two values are n1 and n2 (e.g. gib 10 2 1 = 123, from 2, 1, 3, 4, 7, ...).
   The unstaged version below memoizes: a map from m' to the m'-th value,
   so each value is computed once.

   At the bottom of this file, genbody stages gib with respect to m (m is
   known at generation time, n1 and n2 only at run time), and sgib m
   generates code for fun n1 n2 -> gib m n1 n2. Run it and look at the
   generated code: it computes the same values many times.
   Improve genbody so that the generated code computes each value only
   once, as gib does. (Hint: let-insertion. genlet and let_locus from
   example 6 are copied below, or use Codelib.genlet and Codelib.with_locus
   from example 4.) *)

module IntMap = Map.Make (Int)

let gib m n1 n2 =
  let memo = ref IntMap.empty in
  let rec go m =
    match IntMap.find_opt m !memo with
    | Some v -> v
    | None ->
      let v = if m = 0 then n1 else if m = 1 then n2 else go (m - 1) + go (m - 2) in
      memo := IntMap.add m v !memo;
      v
  in
  go m

let () = Printf.printf "gib 10 2 1 = %d\n" (gib 10 2 1)

(* genlet / let_locus with effect handlers, as in example 6 *)
type _ Effect.t += Genlet : 'a code -> 'a code Effect.t

let genlet (c : 'a code) : 'a code = Effect.perform (Genlet c)

let let_locus (body : unit -> 'w code) : 'w code =
  match body () with
  | c -> c
  | effect Genlet c, k ->
    .< let t = .~c in .~(Effect.Deep.continue k .< t >.) >.

(* A first staged version: gib with m static, without let-insertion.
   genbody m qn1 qn2 generates the code for the m-th value of the sequence
   starting from (the values of) qn1 and qn2. The map now holds code, so
   generation is memoized, but each lookup splices the same code again:
   the generated code recomputes the same values over and over. *)
let genbody (m : int) (qn1 : int code) (qn2 : int code) : int code =
  let memo = ref IntMap.empty in
  let rec go m =
    match IntMap.find_opt m !memo with
    | Some v -> v
    | None ->
      let v =
        if m = 0 then qn1
        else if m = 1 then qn2
        else .< .~(go (m - 1)) + .~(go (m - 2)) >.
      in
      memo := IntMap.add m v !memo;
      v
  in
  go m

let sgib m = .< fun n1 n2 -> .~(genbody m .< n1 >. .< n2 >.) >.

(* Generated code for m = 10 *)
let gib10_code = sgib 10

(* Compile it, then use it like any other function *)
let gib10 = Runcode.run gib10_code

let () = Printf.printf "staged: gib10 2 1 = %d\n" (gib10 2 1)
