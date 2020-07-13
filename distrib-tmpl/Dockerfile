ARG ARCH=amd64

FROM ${ARCH}/ubuntu:18.04
RUN useradd --no-log-init -r hercules
COPY --chown=hercules ./ /
RUN apt update && apt install -y libmysqlclient20 libmariadb3 nano python3-pip
RUN pip3 install -r /autolycus/requirements.txt

# Login server
EXPOSE 6900
# Character server
EXPOSE 6121
# Map server
EXPOSE 5121

USER hercules
WORKDIR /
ENTRYPOINT python3 /autolycus/autolycus.py setup_all && python3 /autolycus/autolycus.py start && tail -f /hercules/log/*
