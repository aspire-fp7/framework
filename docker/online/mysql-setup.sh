#!/bin/bash
# Kind of hacky script: We're supposed to put DB setup scripts into the /docker-entrypoint-initdb.d/
# directory, but as these scripts aren't actually executed, but sourced, we have some issues with
# them finding the extra files they depend on (such as SQL scripts). Therefore we use this intermediate
# script to do the actual invoking of setup scripts.

cd /docker-entrypoint-initdb.d/

for f in $(ls); do
  [ -f $f/database_setup.sh ] && $f/database_setup.sh || true
done
