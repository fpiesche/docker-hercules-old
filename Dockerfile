FROM --platform=$TARGETPLATFORM ubuntu:18.04
ARG $TARGETPLATFORM
ARG $DISTRIB_PATH=./distrib

RUN apt-get update && apt-get install -y libmariadb-dev libmysqlclient20 libmariadb3 nano python3-pip
RUN useradd --no-log-init -r hercules
COPY --chown=hercules ${$DISTRIB_PATH}/${TARGETPLATFORM} /hercules
COPY --chown=hercules ./autolycus /autolycus
RUN pip3 install -r /autolycus/requirements.txt

# Login server
EXPOSE 6900
# Character server
EXPOSE 6121
# Map server
EXPOSE 5121

USER hercules
WORKDIR /hercules
ENTRYPOINT /autolycus/autolycus.py -p /hercules setup_all && /autolycus/autolycus.py -p /hercules start && tail -f /hercules/log/*
