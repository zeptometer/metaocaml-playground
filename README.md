# MetaOCaml Playground

An in-browser playground for [BER MetaOCaml](https://okmij.org/ftp/ML/MetaOCaml.html)
(N153, on OCaml 5.3). Write staged code with `.< … >.` and `.~`, look at the
code it generates, and run it with `Runcode.run`, all without installing
anything. Everything runs client-side: the MetaOCaml toplevel is compiled to
JavaScript and runs in a web worker, so `www/` is a plain static site.

It is derived from the [ocaml.org playground](https://github.com/ocaml/ocaml.org).

## Features

- A MetaOCaml toplevel set up like the `metaocaml` command: `Codelib` is
  opened, and code values are printed with `Codelib.print_code` /
  `print_closed_code`.
- Code generation, type errors inside brackets, scope-extrusion checks and
  `Runcode.run` all work as they do natively.
- A CodeMirror editor with OCaml highlighting. Ctrl/⌘ + Enter runs the code.
- Share links: **Share** puts the code in the URL fragment (`#code=<base64>`)
  and copies the link.

## Building

You need [opam](https://opam.ocaml.org). The project uses a local switch with
the BER MetaOCaml compiler (`ocaml-variants.5.3.0+BER`):

```sh
opam switch create . --deps-only   # creates _opam/ with the BER compiler and dependencies
eval $(opam env)
dune build
```

`dune build` promotes its outputs into `www/`:

| File | What it is |
| --- | --- |
| `www/playground.min.js` | the page script (editor, UI, RPC client) |
| `www/worker.min.js` | the toplevel worker |
| `www/stdlib/*.cmi` | interfaces the toplevel loads on demand |

These are build outputs and are git-ignored. To try it out, serve `www/` over
HTTP (web workers don't load from `file://`):

```sh
cd www && python3 -m http.server 8000
```

Then open http://localhost:8000/. To deploy it, copy `www/` to any static host.

## Layout

```
src/main.ml        page script: editor, Run/Share/Clear, output rendering
src/edit.ml        CodeMirror setup
src/worker.ml      toplevel worker: MetaOCaml-specific setup
src/dune           worker and page build rules (js_of_ocaml --toplevel)
gen_stdlib.sh      collects the .cmi files served from www/stdlib/
vendor/js_top_worker/
                   toplevel-in-a-worker library and its RPC client
                   (vendored from tmattio/js_top_worker, patched for OCaml 5.3)
www/               static site: index.html, style.css and the build outputs
```

## How it works

The worker is the bytecode program `src/worker.ml`, linked with the vendored
`js_top_worker` and MetaOCaml's `metalib.cma` (`Codelib`, `Lifts`,
`Runcode`). It is then compiled with `js_of_ocaml --toplevel`, so it carries
the OCaml compiler (BER's, which understands brackets) and can evaluate
phrases. `Runcode.run` type-checks and evaluates the generated code with that
same in-browser toplevel.

The worker is built with `--no-cmis`, so it doesn't embed the `.cmi` files.
On startup the page sends it a list of URLs under `www/stdlib/` and the worker
fetches each interface when it is first needed. This set covers the stdlib,
MetaOCaml's libraries, and the compiler-libs interfaces those libraries refer
to.

Two things need care because the interfaces arrive this late:

- The worker links `metalib.cma` directly instead of the `metaocaml` findlib
  package. That package's bytecode archive also contains `berstart.cmo`,
  which initialises the toplevel environment as soon as it is loaded. In the
  worker this fails with `Unbound module Stdlib`, because no `.cmi` is
  available yet.
- For the same reason, `Codelib` can't be opened through
  `Clflags.open_modules`. `worker.ml` runs `open Codelib;;` as a phrase after
  setup instead.

## Licence

ISC, like the ocaml.org playground that this project is derived from.
`vendor/js_top_worker` keeps the licence of its upstream project.
