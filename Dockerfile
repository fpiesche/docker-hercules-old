# To use this Dockerfile, run docker build with --build-arg ARCH=[amd64|arm32v7|arm64v8]
ARG ARCH=${ARCH}

FROM ${ARCH}/ubuntu:18.04
RUN useradd --no-log-init -r hercules
COPY --chown=hercules ./distrib/hercules /hercules
COPY --chown=hercules ./autolycus /autolycus
RUN apt-get update && apt-get install -y libmariadb-dev libmysqlclient20 libmariadb3 nano python3-pip
RUN pip3 install -r /autolycus/requirements.txt

# Login server
EXPOSE 6900
# Character server
EXPOSE 6121
# Map server
EXPOSE 5121

USER hercules
WORKDIR /
ENTRYPOINT /autolycus/autolycus.py -p /hercules setup_all && /autolycus/autolycus.py -p /hercules start && tail -f /hercules/log/*
