(* The toplevel web worker, set up the same way as BER MetaOCaml's own
   toplevel plugin (bertop.ml in the BER MetaOCaml distribution). *)

open Longident

let () =
  (* Print [Trx.code] as plain [code] (the -short-paths behaviour). *)
  Clflags.real_paths := false

(* Implicitly [open Codelib], as the [metaocaml] toplevel does. This can't go
   through [Clflags.open_modules]: the initial environment is built before the
   .cmi files are fetched (the worker is linked with --no-cmis), so Codelib
   would not be found. Run it as a phrase once setup has loaded them. *)
let open_codelib () =
  if not (Js_of_ocaml_toplevel.Direct.use Format.std_formatter "open Codelib;;")
  then prerr_endline "error while opening Codelib"

let install_printers () =
  Topdirs.dir_install_printer Format.std_formatter
    (Ldot (Lident "Codelib", "print_code"));
  Topdirs.dir_install_printer Format.std_formatter
    (Ldot (Lident "Codelib", "print_closed_code"))

let () =
  Js_top_worker.Worker.after_setup :=
    fun () ->
      open_codelib ();
      install_printers ();
      Printf.printf "        BER MetaOCaml version %s\n" Trx.meta_version

let () = Js_top_worker.Worker.run ()
