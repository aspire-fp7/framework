#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

diablo_selfprofiling() {
  echo "Building Diablo-Selfprofiling..."
  /opt/framework/diablo/build_obj.sh /opt/diablo/obj
}

# Set up the symlinks for the modules that don't require anything special.
setup_symlinks() {
  echo "Setting up symlinks..."
  ln -s /opt/framework/actc/src/ /opt/ACTC
  ln -s /opt/framework/annotation_extractor /opt/annotation_extractor
  ln -s /opt/framework/code_guards /opt/codeguard
}

accl() {
  echo "  Building ACCL..."
  /opt/framework/accl/build.sh /opt/ACCL
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
  /opt/framework/remote_attestation/build.sh /opt/remote_attestation
}

setup_symlinks

[ -d /opt/framework/anti_debugging ] && anti_debugging
diablo_selfprofiling
accl
code_mobility
renewability
remote_attestation
