#!/bin/sh
# Generate the OCaml list of .cmi files available under www/stdlib/.

echo "let cmis = ["
for i in $(ls ../www/stdlib/); do
  echo "\"$i\";"
done
echo "]"
