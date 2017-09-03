#!/bin/bash

set -e
set -u

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

setup_symlinks() {
  echo "Setting up symlinks..."

  ln -s /opt/framework/code-guards /opt/codeguard
  ln -s /opt/framework/annotation_extractor /opt/annotation_extractor
  mkdir -p /opt/online_backends/code_mobility/
  mkdir -p /opt/ASCL
  ln -s /opt/framework/ascl/src /opt/ASCL/src
  ln -s /opt/framework/ascl/src /opt/ASCL/include
  ln -s /opt/framework/ascl/src/aspire-portal /opt/ASCL/aspire-portal
  mkdir -p /opt/RA
  mkdir -p /opt/RA/obj
  ln -s /opt/framework/remote-attestation/{deploy,setup,scripts,src} /opt/RA/
  mkdir -p /opt/code_mobility
  ln -s /opt/code_mobility/prebuilt/ /opt/code_mobility/downloader
  ln -s /opt/code_mobility/prebuilt/ /opt/code_mobility/binder
  mkdir -p /opt/ACCL
  ln -s /opt/framework/accl/src/ /opt/ACCL/include
  ln -s /opt/framework/accl/src/ /opt/ACCL/src
  ln -s /opt/framework/actc/src/ /opt/ACTC
}

communications() {
  echo "Building Communications libraries..."

  echo "  Building ASCL..."
  /opt/framework/ascl/build.sh /opt/ASCL/obj
  ln -s /opt/ASCL/obj/linux_x86 /opt/ASCL/obj/serverlinux

  echo "Setup of server..."
  /tmp/nginx-setup.sh
  pip install uwsgi
}

anti_debugging() {
  echo "Building anti-debugging..."
  /opt/framework/anti-debugging/build.sh /opt/anti_debugging
}

codemobility() {
  echo "Building code mobility..."

  cd /opt/framework/code-mobility/src/mobility_server

  ln -s /opt/framework/code-mobility/scripts/deploy_application.sh /opt/code_mobility/
  chmod a+x /opt/code_mobility/deploy_application.sh
  /opt/framework/code-mobility/build.sh /opt/code_mobility/prebuilt
}

renewability() {
  echo "Building renewability..."

  /etc/init.d/mysql restart || true
  /opt/framework/renewability/build.sh /opt/renewability
  ln -s /opt/framework/renewability/scripts/ /opt/renewability/
  ln -s /opt/framework/renewability/setup/ /opt/renewability/
  chmod a+x /opt/renewability/scripts/create_new_revision.sh
  /opt/renewability/setup/database_setup.sh
}

RA() {
  echo "Building remote attestation..."

  /etc/init.d/mysql restart || true
  /opt/framework/remote-attestation/setup/remote_attestation_setup.sh
  cd /opt/RA/obj
  ../setup/generate_racommons.sh -o .
}

setup_symlinks

toolchains
[ -d /opt/framework/anti-debugging ] && anti_debugging
diablo_selfprofiling
thirdparty

communications
codemobility
renewability
RA
