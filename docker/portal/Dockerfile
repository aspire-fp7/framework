FROM tiangolo/uwsgi-nginx:python2.7
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y libmysqlclient-dev

# Dirty hack: the portal is supposed to run binaries for remote attestation that have been built
# by the actc docker. These binaries are dynamically linked and depend on libmysqclient20, but
# only libmysqclient18 is available on this docker. We thus install it from unstable..
COPY docker/portal/unstable.list /etc/apt/sources.list.d/
RUN apt-get update && apt-get -t unstable install -y libmysqlclient20

# Build code mobility components
COPY modules/code_mobility /tmp/code_mobility
RUN /tmp/code_mobility/build_portal.sh /opt/code_mobility

# Build remote attestation components
COPY modules/remote_attestation /tmp/remote_attestation
RUN /tmp/remote_attestation/build_portal.sh /opt/remote_attestation

# Install the app
COPY docker/portal/ /app

# Clean up
RUN rm -rf /tmp/*
