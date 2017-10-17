#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

toolchains() {
  echo "Installing toolchains..."

  if [ ! -f /opt/diablo-gcc-toolchain ]
  then
    wget -O /tmp/linux-gcc-4.8.1.tar.bz2 https://diablo.elis.ugent.be/sites/diablo/files/toolchains/diablo-binutils-2.23.2-gcc-4.8.1-eglibc-2.17.tar.bz2 && \
    mkdir -p /opt/diablo-gcc-toolchain && \
    cd /opt/diablo-gcc-toolchain && \
    tar xvf /tmp/linux-gcc-4.8.1.tar.bz2 && \
    /tmp/patch_gcc.sh /opt/diablo-gcc-toolchain/
  fi

  if [ ! -f /opt/diablo-android-gcc-toolchain ]
  then
    wget -O /tmp/android-gcc-4.8.tar.bz2 https://diablo.elis.ugent.be/sites/diablo/files/toolchains/diablo-binutils-2.23.2-gcc-4.8.1-android-API-18.tar.bz2 && \
    mkdir -p /opt/diablo-android-gcc-toolchain && \
    cd /opt/diablo-android-gcc-toolchain && \
    tar xvf /tmp/android-gcc-4.8.tar.bz2 && \
    /tmp/patch_gcc.sh /opt/diablo-android-gcc-toolchain/
  fi
}

thirdparty() {
  echo "Installing third-party libraries..."

  mkdir -p /opt/3rd_party
  cd /opt/3rd_party
  wget https://diablo.elis.ugent.be/sites/diablo/files/prebuilt/curl-7.45.0-prebuilt.tar.bz2
  wget https://diablo.elis.ugent.be/sites/diablo/files/prebuilt/libwebsockets-1.5-prebuilt.tar.bz2
  wget https://diablo.elis.ugent.be/sites/diablo/files/prebuilt/openssl-1.0.2d-prebuilt.tar.bz2
  tar xvf curl-7.45.0-prebuilt.tar.bz2
  tar xvf libwebsockets-1.5-prebuilt.tar.bz2
  tar xvf openssl-1.0.2d-prebuilt.tar.bz2
}

toolchains
thirdparty
