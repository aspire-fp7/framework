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

# Start the ACTC container with extra volumes, then enter the development shell.
xhost +local:root;
container_name=$(docker-compose run -d -e DISPLAY=${DISPLAY} -v /tmp/.X11-unix:/tmp/.X11-unix ${ADDITIONALVOLUMES} actc)
docker exec --interactive --tty -e DISPLAY=${DISPLAY} ${container_name} /opt/development/docker/actc/development.sh
docker stop ${container_name} > /dev/null
