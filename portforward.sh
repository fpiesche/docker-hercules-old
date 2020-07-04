#!/bin/bash
#LOCAL_IP=`ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

# Ragnarok Online
upnpc -e "ragnarok login" -r 6900 TCP >> /dev/null
upnpc -e "ragnarok char" -r 6121 TCP >> /dev/null
upnpc -e "ragnarok map" -r 5121 TCP >> /dev/null
