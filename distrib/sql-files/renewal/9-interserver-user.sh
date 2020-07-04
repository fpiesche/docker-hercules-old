#!/bin/bash
mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "USE ragnarok; UPDATE login set userid = '${INTERSERVER_USER}', user_pass = '${INTERSERVER_PASSWORD}' where account_id = 1;"
