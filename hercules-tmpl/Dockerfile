FROM arm32v7/ubuntu:18.04
RUN useradd --no-log-init -r hercules
RUN apt update && apt install -y libmysqlclient20 libmariadb3
COPY --chown=hercules ./ /hercules/

# Login server
EXPOSE 6900
# Character server
EXPOSE 6121
# Map server
EXPOSE 5121

USER hercules
WORKDIR /hercules
ENTRYPOINT /hercules/athena-start start && tail -f /hercules/log/*