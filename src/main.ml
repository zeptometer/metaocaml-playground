(* Page script of the MetaOCaml playground.
   Adapted from the ocaml.org playground (ISC licence, see LICENSE). *)

open Brr
open Code_mirror
open Lwt.Syntax

module Toplevel_api = Js_top_worker_rpc.Toplevel_api_gen
module Toprpc = Js_top_worker_client.W

let get_el_by_id s =
  match Document.find_el_by_id G.document (Jstr.v s) with
  | Some v -> v
  | None ->
      Console.warn [ Jstr.v "Failed to get element by id"; Jstr.v s ];
      invalid_arg s

let output_el () = get_el_by_id "output"

let timeout_container () =
  El.set_children (output_el ())
    [ El.p [ El.txt' "The toplevel was stopped: the previous execution timed out. Reload the page to start a new one." ] ]

let cmi_urls () = List.map (fun cmi -> "stdlib/" ^ cmi) Cmis.cmis

let initialise worker_url callback =
  let rpc = Js_top_worker_client.start worker_url 100000 callback in
  let* _ = Toprpc.init rpc Toplevel_api.{ cmas = []; cmi_urls = cmi_urls () } in
  Lwt.return rpc

let or_raise = function
  | Ok v -> v
  | Error (Toplevel_api.InternalError e) -> failwith e

let with_rpc rpc f v = Lwt.bind rpc (fun r -> Lwt.map or_raise @@ f r v)
let async_raise f = Lwt.async (fun () -> Lwt.map or_raise @@ f ())

let script_data s =
  let script = get_el_by_id "playground-script" in
  Option.value ~default:"" (Option.map Jstr.to_string (El.at (Jstr.v s) script))

(* Syntax highlighting: CodeMirror's legacy OCaml mode. *)
let ocaml_language =
  Stream.Language.define (Stream.Language.of_jv (Jv.get Jv.global "__CM__mllike"))

let dark_theme_ext =
  let dark = Jv.get Jv.global "__CM__dark" in
  Extension.of_jv @@ Jv.get dark "oneDark"

let render_output cls = function
  | None -> None
  | Some output -> Some (El.pre ~at:[ At.class' (Jstr.v cls) ] [ El.txt' output ])

let handle_output (o : Toplevel_api.exec_result) =
  let output = output_el () in
  let output_elements =
    List.filter_map
      (fun (c, o) -> render_output c o)
      [ ("out-stdout", o.stdout); ("out-stderr", o.stderr); ("out-result", o.caml_ppf) ]
  in
  El.append_children output [ El.div ~at:[ At.class' (Jstr.v "out-block") ] output_elements ];
  (* keep the latest output in view *)
  Jv.set (El.to_jv output) "scrollTop" (Jv.get (El.to_jv output) "scrollHeight")

(* Share links: the code is kept base64-encoded in the URL fragment. *)
module Codec = struct
  let ( let+ ) = Result.bind

  let replace ~find ~replace s = Jstr.cuts ~sep:find s |> Jstr.concat ~sep:replace

  let from_window () =
    let uri = Window.location G.window in
    let params = Uri.fragment_params uri in
    let from_code jstr =
      let unspace = replace ~find:(Jstr.v " ") ~replace:(Jstr.v "+") jstr in
      Result.to_option
      @@ let+ dec = Base64.decode unspace in
         let+ code = Base64.data_utf_8_to_jstr dec in
         Ok (Jstr.to_string code)
    in
    let from_rawcode jstr = Some (Jstr.to_string jstr) in
    List.find_map
      (fun (k, f) -> Option.bind (Uri.Params.find (Jstr.v k) params) f)
      [ ("code", from_code); ("rawcode", from_rawcode) ]

  let to_window s =
    let data = Base64.data_utf_8_of_jstr s in
    let+ bin = Base64.encode data in
    let query = Uri.Params.of_assoc [ (Jstr.v "code", bin) ] in
    let uri = Uri.with_fragment_params (Window.location G.window) query in
    Window.set_location G.window uri;
    Ok ()
end

(* Examples: www/examples/<name>.ml, listed in the #examples menu of
   index.html. The first one in the menu is the page's default code. *)
module Examples = struct
  let select () = get_el_by_id "examples"
  let selected () = Jv.to_string (Jv.get (El.to_jv (select ())) "value")
  (* An unknown name leaves the default (first) example selected. *)
  let set_selected name =
    let sel = El.to_jv (select ()) in
    Jv.set sel "value" (Jv.of_string name);
    if selected () = "" then Jv.set sel "selectedIndex" (Jv.of_int 0)

  let fetch name k =
    let open Brr_io.Fetch in
    let fail e = Console.error [ Jstr.v "Failed to load example"; Jstr.v name; e ] in
    Fut.await (url (Jstr.v ("examples/" ^ name ^ ".ml"))) @@ function
    | Error e -> fail (Jv.of_error e)
    | Ok r when not (Response.ok r) -> fail (Jv.of_int (Response.status r))
    | Ok r -> (
        Fut.await (Body.text (Response.as_body r)) @@ function
        | Error e -> fail (Jv.of_error e)
        | Ok text -> k (Jstr.to_string text))

  (* [#example=<name>] in the URL *)
  let from_window () =
    let params = Uri.fragment_params (Window.location G.window) in
    Option.map Jstr.to_string (Uri.Params.find (Jstr.v "example") params)
end

let setup () =
  let exts = [| dark_theme_ext; Editor.View.line_wrapping (); ocaml_language |] in
  let shared_code = Codec.from_window () in
  let _state, view =
    Edit.init ~doc:(Jstr.v (Option.value ~default:"" shared_code)) ~exts ()
  in
  let load_example name =
    Examples.fetch name (fun code -> Edit.set view ~doc:(Jstr.v code) ~exts)
  in
  (* A shared #code=… link takes precedence over #example=…; with neither,
     the first example in the menu (selected by default) is loaded. *)
  (match shared_code with
  | Some _ -> ()
  | None ->
      Option.iter Examples.set_selected (Examples.from_window ());
      load_example (Examples.selected ()));
  ignore
    (Ev.listen Ev.change
       (fun _ -> load_example (Examples.selected ()))
       (El.as_target (Examples.select ())));
  let rpc = initialise (script_data "data-worker-url") timeout_container in
  let* o = with_rpc rpc Toprpc.setup () in
  handle_output o;
  let run_button = get_el_by_id "run" in
  El.set_at (Jstr.v "disabled") None run_button;
  let running = ref false in
  let run () =
    if not !running then begin
      running := true;
      El.set_class (Jstr.v "loading") true run_button;
      async_raise (fun () ->
          let* o = with_rpc rpc Toprpc.exec (Edit.get_doc view ^ ";;") in
          El.set_class (Jstr.v "loading") false run_button;
          running := false;
          handle_output o;
          Lwt.return (Ok ()))
    end
  in
  let listen id f = ignore (Ev.listen Ev.click (fun _ -> f ()) (El.as_target (get_el_by_id id))) in
  listen "run" run;
  listen "clear" (fun () -> El.set_children (output_el ()) []);
  (* Share: put the code in the URL, copy the URL, and say so on the button
     for a second. *)
  let share_button = get_el_by_id "share" in
  let share_reset = ref None in
  let flash_share msg =
    Option.iter G.stop_timer !share_reset;
    El.set_children share_button [ El.txt' msg ];
    El.set_class (Jstr.v "flash") true share_button;
    share_reset :=
      Some
        (G.set_timeout ~ms:1000 (fun () ->
             share_reset := None;
             El.set_class (Jstr.v "flash") false share_button;
             El.set_children share_button [ El.txt' "Share" ]))
  in
  listen "share" (fun () ->
      Console.log_if_error ~use:() (Codec.to_window @@ Jstr.v (Edit.get_doc view));
      let clipboard = Brr_io.Clipboard.of_navigator G.navigator in
      Fut.await
        (Brr_io.Clipboard.write_text clipboard (Window.location G.window |> Uri.to_jstr))
        (function
          | Ok () -> flash_share "Copied!"
          | Error e ->
              Console.error [ Jstr.v "Failed to copy the link"; e ];
              flash_share "Copy failed"));
  (* Ctrl-Enter / Cmd-Enter runs the code *)
  ignore
    (Ev.listen Ev.keydown
       (fun e ->
         let k = Ev.as_type e in
         if Jstr.equal (Ev.Keyboard.key k) (Jstr.v "Enter")
            && (Ev.Keyboard.ctrl_key k || Ev.Keyboard.meta_key k)
         then (Ev.prevent_default e; run ()))
       (Document.as_target G.document));
  Lwt_result.return ()

let () = async_raise setup
