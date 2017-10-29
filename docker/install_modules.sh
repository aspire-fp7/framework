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
  ln -s /opt/framework/code_guards /opt/codeguard
}

communications() {
  echo "Building Communications libraries..."

  echo "  Building ACCL..."
  /opt/framework/accl/build.sh /opt/ACCL

  echo "  Building ASCL..."
  /opt/framework/ascl/build.sh /opt/ASCL
}

anti_debugging() {
  echo "Building anti_debugging..."
  /opt/framework/anti_debugging/build.sh /opt/anti_debugging
}

code_mobility() {
  echo "Building code mobility..."
  /opt/framework/code_mobility/build.sh /opt/code_mobility
}

renewability() {
  echo "Building renewability..."
  /opt/framework/renewability/build.sh /opt/renewability
}

remote_attestation() {
  echo "Building remote attestation..."
  /opt/framework/remote_attestation/build.sh /opt/RA
}

setup_symlinks

[ -d /opt/framework/anti_debugging ] && anti_debugging
diablo_selfprofiling
communications
code_mobility
renewability
remote_attestation
