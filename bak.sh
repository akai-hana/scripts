#!/bin/sh
# ".bak" appending toggle

filename="$1"

if [ "${filename%.bak}" = "$filename" ]; then
  mv "$filename" "$filename.bak"
else
  mv "$filename" "${filename%.bak}"
fi
