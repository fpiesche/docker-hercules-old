[![Build Status](https://drone.yellowkeycard.net/api/badges/outrider/hercules-docker/status.svg)](https://drone.yellowkeycard.net/outrider/hercules-docker)

# hercules-docker

A Docker setup for building and containerising the Ragnarok Online server emulator Hercules

# What is this?

This repository specifically contains everything you need to build a Hercules server with minimal
effort, provided you have a working Docker installation. If you're happy to run pre-built Docker
containers made using this setup, check out the "How do I run a Ragnarok Online server with this?"
section further down.

If you want to know what Docker is, [here is a good overview](https://www.zdnet.com/article/what-is-docker-and-why-is-it-so-darn-popular/).

# How does this work?

The Dockerfile is a two-stage definition for Docker:

- Step 1 (`build_hercules`) will bring up a Linux (Debian Buster, specifically) container, install
all the necessary requirements for compiling Hercules, build Hercules and package the build up in a
.tar.gz file.

- Step 2 (`build_image`) will then take the build produced by step 1 and deploy it inside another
Debian Buster container, all prepared so you can simply run the Hercules server with a single
`docker run`.

If you just want to run a server without making your own build, there are standard images built and
published from this repository via
[an automated weekly build](https://github.com/fpiesche/hercules-docker/actions).

These images are always built with the current release version of Hercules, for Intel/AMD
(most home computers), ARMv7 (Raspberry Pi 2 and equivalents) and ARM64 (Raspberry Pi 3 or 4 and
equivalents) systems and available in both Classic and Renewal mode.

# How do I run a Ragnarok Online server with this?

I'm making images available for both Renewal and Classic servers using both the latest packet
version supported by Hercules and packet version `20180418`, which matches the "Noob Pack" client
download available on the Hercules forums for ease of use.

In order to run these, you will need to [install Docker](https://docs.docker.com/get-docker/) on
the computer you want to run the server on.

Then, download the [docker-compose.yaml](https://github.com/fpiesche/hercules-docker/blob/main/docker-compose.yaml)
file from this repository and copy it somewhere. You can just use it as is to just bring up a
server, but do feel free to have a closer look at its contents. There are a number of variables
you can edit to e.g. lock down database access more tightly.

To bring up your Ragnarok game server and the database it needs, open a command prompt or terminal
window, navigate to where you saved the docker-compose.yaml file and simply run
`docker-compose up -d`. Docker will download the images for the game and database servers and
start them.

If you want to watch things happen, just run `docker-compose up` to run the services in the
foreground. To exit out of this view, simply press Ctrl-C; **NOTE** that this will shut down
the services though!

You can check the status of your services with `docker ps`; this should list both the database and
game_servers containers as "running" once they have started. They will continue running in the
background even if you close the command-line window and you should be able to create accounts
and connect to the server.

## How do I create an account on the server?

The database service is isolated within the Docker network for security - this means while your
game servers can connect to it, nobody else can. This does however mean that you cannot connect
to it with a MySQL client to create an account as is normally recommended by Hercules.

However, the pre-built images come with [Autolycus](https://github.com/fpiesche/autolycus), my
server manager. Currently this does not have a web interface for creating accounts, but it does
make creating accounts without needing access to the database easy.

- First, from a command-line/terminal window, connect to the game server container using
  `docker exec -it hercules-docker_game_servers /bin/bash`.
- Within the shell on the container, simply run:
  `python3 /autolycus/autolycus.py -p /hercules account [account name] -p [account password] -s [M|F] [--admin]`

This will create an account with the given name, password and sex. Add the `--admin` parameter to
make the account an admin. You can also use this to edit existing accounts.

# How do I build Hercules with this?

## I'd rather build my own Docker image.

Simply run `docker build . -t hercules`. This will run the build and package it up in a local image tagged `hercules`, which you can run either with `docker run hercules` or using the `docker-compose.yml` file (above) to bring up an entire setup with its own database service and everything.

# I don't want to run Hercules from a Docker image. Can I just get the build?

You can run only the first stage of the Dockerfile to build Hercules without packaging it up in an image. To just build Hercules and copy the build to your local machine, run:

  - `docker build . -t hercules --target build_hercules`
  - `docker cp hercules:/hercules*.tar.gz .`

Note that this **will** be a Linux build, so if you want to run this on a Windows host you might need to put some more work in. I'd be happy to accept pull requests to make this all work with and produce Windows builds, too!

# I don't want to build a Classic server. And what about packet version [whatever]?

To build a Renewal rather than a Classic server or a specific packet version, modify your `docker build` command with the `HERCULES_SERVER_MODE` and/or `HERCULES_PACKET_VERSION` build arguments:

* `docker build . -t hercules [--target build_hercules] --build-arg HERCULES_SERVER_MODE=[classic|renewal] --build-arg HERCULES_PACKET_VERSION=[whatever]`

# I'm a developer on Hercules or a plugin. Can I use this with my own copy of the source?

Sure you can! Simply mount your local copy of the source in the build container at `/builder/hercules-src`:

* `docker build . -t hercules --mount type=bind,source=/home/me/my-hercules-source,destination=/builder/hercules-src`
