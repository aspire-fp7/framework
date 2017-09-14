#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

git submodule update --init --recursive

echo
read -r -p "Would you like to include the anti-debugging protection? (y/N)" response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
  cd modules/
  git clone https://github.ugent.be/SysLab/anti-debugging.git
  cd anti-debugging
  git checkout bf8e72b3f63b45650da2feb00918c017cde219de
fi
