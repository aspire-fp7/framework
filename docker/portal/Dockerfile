FROM tiangolo/uwsgi-nginx:python2.7
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y default-libmysqlclient-dev

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
