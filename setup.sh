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
  git checkout 631a935e71caf8cf6d7bde5555925b412b080239
fi
