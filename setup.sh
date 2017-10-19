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
  git clone https://github.ugent.be/SysLab/anti-debugging.git anti_debugging
  cd anti_debugging
  git checkout 18461ad3dd4d5eb75d4f04813962e95cce1a74b6
  cp diablo/* $MODULES_DIR/diablo/aspire/self_debugging/
fi
