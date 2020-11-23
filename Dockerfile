FROM --platform=$TARGETPLATFORM ubuntu:18.04
ARG TARGETPLATFORM
ARG DISTRIB_PATH=./distrib

RUN apt-get update && apt-get install -y libmariadb-dev libmysqlclient20 libmariadb3 python3-pip
RUN useradd --no-log-init -r hercules

COPY --chown=hercules ${DISTRIB_PATH}/${TARGETPLATFORM} /
# COPY --chown=hercules $DISTRIB_PATH/$TARGETPLATFORM/hercules /hercules
# COPY --chown=hercules $DISTRIB_PATH/$TARGETPLATFORM/autolycus /autolycus

# Login server, Character server, Map server
EXPOSE 6900 6121 5121

USER hercules
WORKDIR /hercules
ENTRYPOINT /autolycus/autolycus.py -p /hercules setup_all && \
  /autolycus/autolycus.py -p /hercules start && tail -f /hercules/log/*
