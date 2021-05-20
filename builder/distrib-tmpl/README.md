<img style="float: left;" src="https://raw.githubusercontent.com/fpiesche/hercules-docker/master/distrib-tmpl/hercules-icon.png" alt="Hercules logo"/>

# Hercules Ragnarok Online Server

## Release information

* Hercules release [__GIT_VERSION__](https://github.com/HerculesWS/Hercules/releases/tag/__GIT_VERSION__)
* Server mode: __SERVER_MODE__
* Packet version: __PACKET_VER__

# Usage

Paste the following code block into a file called `docker-compose.yml` in a new directory and run `docker-compose up` to bring up a server.

    version: '3.2'

    services:
        game_servers:
            image: florianpiesche/hercules-${SERVER_MODE:-classic}-${PACKETVER:-20180418}
            restart: on-failure
            environment:
                MYSQL_USER: ${MYSQL_USER:-ragnarok}
                MYSQL_PASSWORD: ${MYSQL_PASSWORD:-ragnarok}
                MYSQL_DATABASE: ${MYSQL_DATABASE:-ragnarok}
                MYSQL_HOST: ${MYSQL_HOST:-db}
                INTERSERVER_USER: ${INTERSERVER_USER:-wisp}
                INTERSERVER_PASSWORD: ${INTERSERVER_PASSWORD:-wisp}
            ports:
                # login server
                - 6900:6900
                # character server
                - 6121:6121
                # map server
                - 5121:5121
            volumes:
                - configuration:/hercules/conf/import
                - sql_init:/hercules/sql-files/

        db:
            image: mariadb:10.4
            restart: on-failure
            depends_on:
                - game_servers
            environment:
                MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-hercroot}
                MYSQL_USER: ${MYSQL_USER:-ragnarok}
                MYSQL_PASSWORD: ${MYSQL_PASSWORD:-ragnarok}
                MYSQL_DATABASE: ${MYSQL_DATABASE:-ragnarok}
                MYSQL_HOST: ${MYSQL_HOST:-db}
                INTERSERVER_USER: ${INTERSERVER_USER:-wisp}
                INTERSERVER_PASSWORD: ${INTERSERVER_PASSWORD:-wisp}
            ports:
                - 3306:3306
            volumes:
                - mysql_data:/var/lib/mysql
                - sql_init:/docker-entrypoint-initdb.d

    volumes:
        mysql_data:
        configuration:
        sql_init:

## Editing server configuration

You can edit the server configuration by running `docker exec -it hercules-game_servers_1 /bin/bash` and modifying the configuration files in `/hercules/conf/import`. Changes in the `import` directory will persist even if you rebuild or update the image.

You can also edit the configuration on the host system. To find out where Docker has stored these files on the host, run `docker volume inspect hercules_configuration` and look for the `Mountpoint`.

For configuration changes to take effect, you will need to restart the game server container: `docker restart hercules-game_servers_1`.
