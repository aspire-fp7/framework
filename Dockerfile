# Build Diablo
FROM ubuntu:14.04 as diablo-builder

# Install the required packages
RUN \
  apt-get update && \
  apt-get install -y bison build-essential cmake flex

COPY modules/diablo /tmp/diablo/
RUN \
  mkdir -p /tmp/diablo/build/ && \
  cd /tmp/diablo/build/ && \
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/diablo -DUseInstallPrefixForLinkerScripts=on .. && \
  make -j$(nproc) install

# Actual docker image
FROM ubuntu:14.04

COPY --from=diablo-builder /opt/diablo /opt/diablo

RUN \
  # The i386, and installs of binutils-multiarch gcc-multilib zlib1g:i386 are workarounds for the 32 bit Android toolchain
  dpkg --add-architecture i386 && \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  apt-get install -y binutils-multiarch gcc-multilib zlib1g:i386 && \
  # ACTC \
  apt-get install -y python python-pip && \
  pip install doit==0.29.0 && \
  # ONLINE TECHNIQUES \
  apt-get install -y nginx php5-fpm python-dev libmysqlclient18 libmysqlclient-dev openjdk-7-jre binutils-dev tree && \
# Warning: MySQL gets installed later on, because first the default pw is set
  # Development \
  apt-get install -y bison cmake flex gdb

COPY docker/online/mysql-pre-setup.sh /tmp/mysql-pre-setup.sh

# This has to run before the mysql-server installs as it sets the default password
RUN \
 /tmp/mysql-pre-setup.sh && \
  apt-get update && \
  apt-get install -y mysql-client mysql-server 

COPY docker/online/nginx-default /etc/nginx/sites-available/default
COPY docker/online/aspire_ascl.conf /etc/nginx/conf.d/aspire_ascl.conf

# TODO: this file is slightly patched for Docker (and also patches /opt/ASCL/aspire-portal/aspire-portal.ini): make them uniform!
COPY docker/online/nginx-setup.sh /tmp/nginx-setup.sh

# Install the prebuilts
COPY docker/diablo/ /tmp/
COPY docker/install_prebuilts.sh /tmp/
RUN /tmp/install_prebuilts.sh

# Copy the modules and install them
RUN mkdir -p /opt/framework_buildtime && ln -s /opt/framework_buildtime /opt/framework
COPY modules/ /opt/framework/
COPY docker/install_modules.sh /tmp/
RUN /tmp/install_modules.sh

# EXPOSE 8088
EXPOSE 8080-8099
EXPOSE 18001
