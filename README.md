![build-images](https://github.com/fpiesche/hercules-docker/workflows/build-images/badge.svg)

# hercules-docker

A Docker setup for building and containerising the Ragnarok Online server emulator Hercules

# Building Hercules

Simply run `docker-compose up`. Docker will bring up an Ubuntu 18.04 image, build Hercules and assemble a distribution in the `hercules` directory. Additionally, it will compress the distribution as `hercules-[timestamp].tar.gz`.

# Bringing up a server

After building Hercules, build a Docker container from your new distribution using `cd hercules; docker build . --tag hercules:latest`. Once the container has built, you can bring up the server (including database) using `cd hercules; docker-compose up`.
