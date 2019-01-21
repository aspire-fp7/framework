#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

git submodule update --init --recursive

echo
read -r -p "Would you like to include the anti_debugging protection? (y/N)" response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
  cd modules/
  MODULES_DIR=$PWD
  git clone https://github.com/csl-ugent/anti-debugging.git anti_debugging
  cd anti_debugging
  git checkout 266e209f17ce66ce7728be6b2f185850fa6593fe
  cp diablo/* $MODULES_DIR/diablo/aspire/self_debugging/
fi
