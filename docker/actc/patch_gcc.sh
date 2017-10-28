#!/bin/bash

set -u -e
NEWPATH=$1

for f in `grep -lr "DIABLO_TOOLCHAIN_PATH" .`
do
  # only process text files
  if [ -n "`file $f | grep text`" ]; then
    echo "Patching file $f"

    sed -i "s:DIABLO_TOOLCHAIN_PATH:${NEWPATH}:g" $f
  fi
done
