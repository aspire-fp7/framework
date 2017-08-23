#!/bin/bash

set -e
set -u

DEVELOPER_MODE="yes"
DEMO_PROJECTS="yes"

ADDITIONALVOLUMES=""
add_volume() {
  vol=$1
  export ADDITIONALVOLUMES="$ADDITIONALVOLUMES -v ${PWD}/${vol}:/opt/development/${vol}"
}


if [ "${DEVELOPER_MODE}" == "yes" ]
then
  # Add a volume for every module
  cd modules
  for module in $(ls);
  do
    add_volume $module
  done
  cd ..

  # Add a volume for docker
  add_volume docker
fi

if [ "${DEMO_PROJECTS}" == "yes" ]
then
  if [ ! -d projects/actc-demos ]
  then
    mkdir -p projects
    cd projects
    git clone https://github.com/aspire-fp7/actc-demos
    cd ..
  else
    echo "Demo projects are already present in projects/actc-demos. (These will not be updated/re-installed...)"
 fi
fi

docker-compose run --service-ports ${ADDITIONALVOLUMES} aspire
