#!/bin/sh
# Collect the .cmi files the in-browser toplevel may load on demand:
# the standard library, the MetaOCaml library (Codelib, Runcode, Lifts, Trx),
# and the compiler-libs interfaces that the MetaOCaml interfaces refer to.
set -e

OCAMLLIB=$(ocamlfind ocamlc -where)
out=stdlib
mkdir -p "$out"

# Standard library
tmpfile=$(mktemp)
jsoo_listunits -o "$tmpfile" stdlib
for i in $(cat "$tmpfile"); do
  # unit names are capitalised; files are not (Stdlib__List -> stdlib__List.cmi)
  cp "$OCAMLLIB"/?"${i#?}".cmi "$out"/
done
rm "$tmpfile"
for i in std_exit unix/unix unix/unixLabels compiler-libs/topdirs; do
  cp "$OCAMLLIB/$i.cmi" "$out"/
done

# MetaOCaml
for i in codelib runcode lifts trx; do
  cp "$OCAMLLIB/$i.cmi" "$out"/
done

# compiler-libs interfaces imported by the MetaOCaml interfaces
for f in codelib runcode lifts trx; do
  ocamlobjinfo "$OCAMLLIB/$f.cmi" |
    sed -n '/^Interfaces imported/,$p' | awk 'NR > 1 { print $2 }'
done | sort -u | while read -r unit; do
  lower=$(echo "$unit" | cut -c1 | tr 'A-Z' 'a-z')$(echo "$unit" | cut -c2-)
  if [ ! -e "$out/$lower.cmi" ] && [ -e "$OCAMLLIB/compiler-libs/$lower.cmi" ]; then
    cp "$OCAMLLIB/compiler-libs/$lower.cmi" "$out"/
  fi
done
