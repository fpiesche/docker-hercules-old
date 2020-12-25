###
# STAGE 1: BUILD HERCULES
# We'll build Hercules on Debian Buster's "slim" image.
# This minimises dependencies and download times for the builder.
###
FROM --platform=${TARGETPLATFORM:-linux/arm/v6} debian:buster-slim AS build_hercules

# Set this to "classic" or "renewal" to build the relevant server version (default: classic).
ARG HERCULES_SERVER_MODE=classic

# Set this to a YYYYMMDD date string to build a server for a specific packet version.
# Set HERCULES_PACKET_VERSION to "latest" to build the server for the packet version
# defined in the Hercules code base as the current supported version.
# As a recommended alternative, the "Noob Pack" client download available on the
# Hercules forums is using the packet version 20180418.
ARG HERCULES_PACKET_VERSION=latest

# You can pass in any further command line options for the build with the HERCULES_BUILD_OPTS
# build argument.
ARG HERCULES_BUILD_OPTS

# Install build dependencies.
RUN apt-get update && apt-get install -y \
  gcc \
  git \
  libmariadb-dev \
  libmariadb-dev-compat \
  libpcre3-dev \
  libssl-dev \
  make \
  zlib1g-dev

# Create a build user
RUN adduser --home /home/builduser --shell /bin/bash --gecos "builduser" --disabled-password builduser

# Copy the Hercules build script and distribution template
COPY --chown=builduser builder /home/builduser

# Run the build
ENV WORKSPACE=/home/builduser
ENV DISABLE_MANAGER_ARM64=true
ENV PLATFORM=${TARGETPLATFORM:-linux/arm/v6}
ENV HERCULES_PACKET_VERSION=${HERCULES_PACKET_VERSION}
ENV HERCULES_SERVER_MODE=${HERCULES_SERVER_MODE}
ENV HERCULES_BUILD_OPTS=${HERCULES_BUILD_OPTS}
RUN /home/builduser/build-hercules.sh

###
# STAGE 2: BUILD IMAGE
# Here, we pick a clean minimal base image, install what dependencies
# we do need and then copy the build artifact from the build stage
# into it. Doing this as a separate stage from the build minimises
# final image size.
###

# We're picking the python:3-slim image as the base because
# unlike Alpine, this supports binary wheels which will minimise
# build time and image size for Autolycus's dependencies.
FROM --platform=${TARGETPLATFORM:-linux/arm/v7} python:3-slim AS build_image

# Install base system dependencies and create user.
RUN \
  apt-get update && \
  apt-get install -y \
  libmariadb3 \
  # libmysqlclient20 \
  libmariadbclient-dev \
  libmariadb-dev-compat \
  python3-pip \
  && rm -rf /var/lib/apt/lists/*
RUN useradd --no-log-init -r hercules

# Install Autolycus dependencies - we're doing this as a separate step
# to optimise build cache usage. Docker will cache the image with the
# Python dependencies installed and reuse this for subsequent builds.
ENV PLATFORM=${TARGETPLATFORM}
COPY --from=build_hercules --chown=hercules /builder/distrib/autolycus/requirements.txt /autolycus/
RUN pip3 install -r /autolycus/requirements.txt 

# Copy the actual distribution from builder image
COPY --from=build_hercules --chown=hercules /builder/distrib/ /

# Login server, Character server, Map server
EXPOSE 6900 6121 5121

USER hercules
WORKDIR /hercules
ENTRYPOINT /autolycus/autolycus.py -p /hercules setup_all && \
  /autolycus/autolycus.py -p /hercules start && tail -f /hercules/log/*
