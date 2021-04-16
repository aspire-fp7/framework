# Build Diablo
FROM ubuntu:16.04 as diablo-builder
ARG DEBIAN_FRONTEND=noninteractive

# Install the required packages
RUN \
  apt-get update && \
  apt-get install -y bison build-essential cmake flex g++-multilib

COPY modules/diablo /tmp/diablo/
RUN \
  mkdir -p /tmp/diablo/build/ && \
  cd /tmp/diablo/build/ && \
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/diablo -DUseInstallPrefixForLinkerScripts=on .. && \
  make -j$(nproc) install

# Actual docker image
FROM debian:stretch
ARG DEBIAN_FRONTEND=noninteractive

RUN \
  # The i386, and installs of binutils-multiarch gcc-multilib zlib1g:i386 are workarounds for the 32 bit Android toolchain
  dpkg --add-architecture i386 && \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y htop man ssh vim wget && \
  apt-get install -y binutils-multiarch gcc-multilib gfortran zlib1g:i386 && \
  # ACTC \
  apt-get install -y binutils-dev default-libmysqlclient-dev libwebsockets-dev mysql-client openjdk-8-jre-headless python python-pip && \
  pip install doit==0.29.0 && \
  # UWSGI interface \
  apt-get install -y uwsgi-plugin-python && \
  # Development \
  apt-get install -y bison cmake flex g++-multilib gdb

# Install the prebuilts
COPY docker/actc/install_prebuilts.sh docker/actc/patch_gcc.sh /tmp/
RUN /tmp/install_prebuilts.sh

# Install Diablo
COPY --from=diablo-builder /opt/diablo /opt/diablo

# Copy the modules and install them
RUN mkdir -p /opt/framework_buildtime && ln -s /opt/framework_buildtime /opt/framework
COPY modules/ /opt/framework/
COPY docker/actc/install_modules.sh /tmp/
RUN /tmp/install_modules.sh

# Install the UWSGI service
COPY docker/actc/service/ /opt/service
CMD [ "uwsgi", "--http-socket", ":80", "--ini", "/opt/service/uwsgi.ini" ]

# Clean up
RUN rm -rf /tmp/*
