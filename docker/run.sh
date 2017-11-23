#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

DEMO_PROJECTS="${DEMO_PROJECTS:-yes}"
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

# Make sure all services run
docker-compose up -d

COMMAND="${@:1}"
docker-compose exec actc /opt/ACTC/actc.py ${COMMAND}
