#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# Save PWD
OLD_PWD=$PWD

if [ ! -d /opt/development ]
then
  echo "/opt/development needs to be mounted!"
  exit -1
fi

# Replace the /opt/framework link so we get all source code from the mounts
rm /opt/framework
ln -s /opt/development /opt/framework

# Build diablo
if [ ! -d /build/diablo ]; then
  mkdir -p /build/diablo
  cd /build/diablo
  cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/opt/diablo -DUseInstallPrefixForLinkerScripts=on /opt/framework/diablo
  make -j$(nproc) install
fi

# Start the actual shell
cd $OLD_PWD
tail -f /dev/null
