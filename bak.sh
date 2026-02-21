#!/bin/sh
# ".bak" appending toggle

for filename in "$@"; do
  if [ "${filename%.bak}" = "$filename" ]; then
    mv "$filename" "$filename.bak"
  else
    mv "$filename" "${filename%.bak}"
  fi
done
