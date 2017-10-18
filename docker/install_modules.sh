#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

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

# Set up the symlinks for the modules that don't require anything special.
setup_symlinks() {
  echo "Setting up symlinks..."
  ln -s /opt/framework/actc/src/ /opt/ACTC
  ln -s /opt/framework/annotation_extractor /opt/annotation_extractor
  ln -s /opt/framework/code-guards /opt/codeguard
}

communications() {
  echo "Building Communications libraries..."
  mkdir -p /opt/ACCL
  ln -s /opt/framework/accl/src/ /opt/ACCL/include
  ln -s /opt/framework/accl/src/ /opt/ACCL/src

  echo "  Building ASCL..."
  mkdir -p /opt/ASCL
  ln -s /opt/framework/ascl/src /opt/ASCL/src
  ln -s /opt/framework/ascl/src /opt/ASCL/include
  ln -s /opt/framework/ascl/src/aspire-portal /opt/ASCL/aspire-portal
  /opt/framework/ascl/build.sh /opt/ASCL/obj
  ln -s /opt/ASCL/obj/linux_x86 /opt/ASCL/obj/serverlinux

  echo "Setup of server..."
  /tmp/nginx-setup.sh
  pip install uwsgi
}

anti_debugging() {
  echo "Building anti_debugging..."
  /opt/framework/anti_debugging/build.sh /opt/anti_debugging
}

codemobility() {
  echo "Building code mobility..."
  mkdir -p /opt/online_backends/code_mobility/
  mkdir -p /opt/code_mobility
  ln -s /opt/code_mobility/prebuilt/ /opt/code_mobility/downloader
  ln -s /opt/code_mobility/prebuilt/ /opt/code_mobility/binder

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
  mkdir -p /opt/RA
  mkdir -p /opt/RA/obj
  ln -s /opt/framework/remote-attestation/{deploy,setup,scripts,src} /opt/RA/

  /etc/init.d/mysql restart || true
  /opt/framework/remote-attestation/setup/remote_attestation_setup.sh
  cd /opt/RA/obj
  ../setup/generate_racommons.sh -o .
}

setup_symlinks

[ -d /opt/framework/anti_debugging ] && anti_debugging
diablo_selfprofiling
communications
codemobility
renewability
RA
