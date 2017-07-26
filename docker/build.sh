#!/bin/bash

set -e
set -u

CLEAN=no

clean() {
  rm -rf /opt/framework/diablo/build/
  rm /opt/diablo
  rm -rf /opt/diablo/obj/
  rm -f /opt/framework/diablo/self-profiling/*.o
  rm -f /tmp/linux*
  rm -rf /opt/diablo-gcc-toolchain
  rm -f /tmp/android*
  rm -rf /opt/diablo-android-gcc-toolchain
  rm -rf /opt/3rd_party

  # TODO /opt/framework/renewability/build.sh /opt/RA/setup/remote_attestation_setup.sh ACCL / ASCL
}

diablo() {
  echo "Building Diablo..."

  mkdir -p /opt/framework/diablo/build/
  cd /opt/framework/diablo/build/
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/framework/diablo/install ..
  make
  make install

  if [ ! -f /opt/diablo ]
  then
    ln -s /opt/framework/diablo/install/bin /opt/diablo
  fi
}

diablo_selfprofiling() {
  echo "Building Diablo-Selfprofiling..."

  mkdir -p /opt/diablo/obj/
  cd /opt/framework/diablo/self-profiling
  ./generate.sh /opt/diablo-gcc-toolchain/bin/arm-diablo-linux-gnueabi-cc printarm_linux.o arm
  make
  cp printarm_linux.o /opt/diablo/obj/
  ./generate.sh /opt/diablo-android-gcc-toolchain/bin/arm-linux-androideabi-gcc printarm_android.o arm
  make
  cp printarm_android.o /opt/diablo/obj/
}

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
  echo "Installint third-party libraries..."

  mkdir -p /opt/3rd_party
  cd /opt/3rd_party
  wget https://diablo.elis.ugent.be/sites/diablo/files/prebuilt/curl-7.45.0-prebuilt.tar.bz2
  wget https://diablo.elis.ugent.be/sites/diablo/files/prebuilt/libwebsockets-1.5-prebuilt.tar.bz2
  wget https://diablo.elis.ugent.be/sites/diablo/files/prebuilt/openssl-1.0.2d-prebuilt.tar.bz2
  tar xvf curl-7.45.0-prebuilt.tar.bz2
  tar xvf libwebsockets-1.5-prebuilt.tar.bz2
  tar xvf openssl-1.0.2d-prebuilt.tar.bz2 
}

setup_symlinks() {
  echo "Setting up symlinks..."

  ln -s /opt/framework/code-guards /opt/codeguard
  ln -s /opt/framework/annotation_extractor /opt/annotation_extractor
  mkdir -p /opt/online_backends/code_mobility/
  mkdir -p /opt/ASCL
  ln -s /opt/framework/ascl/src /opt/ASCL/src
  ln -s /opt/framework/ascl/src /opt/ASCL/include
  ln -s /opt/framework/ascl/src/aspire-portal /opt/ASCL/aspire-portal
  ln -s /opt/framework/ascl/prebuilt /opt/ASCL/obj
  ln -s /opt/framework/code-mobility /opt/code_mobility
  ln -s /opt/framework/remote-attestation /opt/RA
  ln -s /opt/code_mobility/prebuilt/ /opt/code_mobility/downloader
  ln -s /opt/code_mobility/prebuilt/ /opt/code_mobility/binder
  ln -s /opt/framework/accl/ /opt/ACCL
  ln -s /opt/framework/accl/prebuilt/ /opt/ACCL/obj
  ln -s /opt/framework/accl/src/ /opt/ACCL/include
  ln -s /opt/framework/actc/src/ /opt/ACTC
}

communications() {
  echo "Building Communications libraries..."

  echo "  Building ASCL..."
  /opt/framework/ascl/build.sh
  ln -s /opt/ASCL/obj/linux_x86 /opt/ASCL/obj/serverlinux


  echo "Building ACCL..."
  /opt/framework/accl/build.sh

  echo "Setup of server..."
  /tmp/nginx-setup.sh
  pip install uwsgi
}

anti_debugging() {
  echo "Building anti-debugging..."
  ln -s /opt/framework/anti-debugging /opt/anti_debugging
  /opt/framework/anti-debugging/build.sh
}

codemobility() {
  echo "Building code mobility..."

  find /opt/framework/code-mobility/ | grep Makefile | xargs sed --in-place "s/-Werror//"

  cd /opt/framework/code-mobility/src/mobility_server

  ln -s /opt/code_mobility/scripts/deploy_application.sh /opt/code_mobility/
  chmod a+x /opt/code_mobility/deploy_application.sh
  sed --in-place -e 's#/opt/code_mobility/mobility_server/mobility_server#/opt/code_mobility/prebuilt/bin/x86/mobility_server#' /opt/ASCL/aspire-portal/backends.json
  /opt/framework/code-mobility/build.sh
}

renewability() {
  echo "Building renewability..."

  /etc/init.d/mysql restart || true
  /opt/framework/renewability/build.sh
  ln -s /opt/framework/renewability /opt/renewability
  chmod a+x /opt/renewability/scripts/create_new_revision.sh
  /opt/renewability/setup/database_setup.sh
}

RA() {
  echo "Building remote attestation..."

  /etc/init.d/mysql restart || true
  /opt/RA/setup/remote_attestation_setup.sh
  cd /opt/RA/obj
  ../setup/generate_racommons.sh -o .
}

setup_symlinks

toolchains
diablo
diablo_selfprofiling
thirdparty

communications
[ -d /opt/framework/anti-debugging ] && anti_debugging
codemobility
renewability
RA
