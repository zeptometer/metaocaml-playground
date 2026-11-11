(lang dune 3.0)

(using directory-targets 0.1)

(name metaocaml-playground)

(generate_opam_files true)

(license ISC)

(package
 (name metaocaml-playground)
 (synopsis "An in-browser playground for BER MetaOCaml")
 (description
  "A browser-only toplevel for BER MetaOCaml, derived from the ocaml.org playground.")
 (allow_empty)
 (depends
  (ocaml
   (= 5.3.0))
  (ocaml-variants
   (= 5.3.0+BER))
  (brr
   (>= 0.0.6))
  js_of_ocaml
  js_of_ocaml-compiler
  js_of_ocaml-toplevel
  js_of_ocaml-ppx
  code-mirror
  lwt
  rresult
  astring
  cppo))
