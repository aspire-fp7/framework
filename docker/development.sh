#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

ADDITIONALVOLUMES=""
add_volume() {
  vol=$1
  export ADDITIONALVOLUMES="$ADDITIONALVOLUMES -v ${PWD}/${vol}:/opt/development/${vol}"
}

# Add a volume for every module
cd modules
for module in $(ls);
do
  add_volume $module
done
cd ..

# Add a volume for docker
add_volume docker

# add /data volume
datapath=${HOME}/actc-data
if [ $(hostname) == "pegasus.elis.ugent.be" ]; then
  datapath=/bulk/A/measurements
fi
export ADDITIONALVOLUMES="$ADDITIONALVOLUMES -v $datapath:/data"

# Run development startup script
xhost +local:root;
docker-compose run -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix ${ADDITIONALVOLUMES} actc /opt/development/docker/actc/development.sh
