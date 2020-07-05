#!/bin/bash

BUILD_IDENTIFIER=hercules_${HERCULES_SERVER_MODE}_packetver-${HERCULES_PACKET_VERSION:-default}_${ARCH}
BUILD_TARGET=/build/${BUILD_IDENTIFIER}
REPO_CHECKOUT=/build/hercules-src

echo "Building Hercules in ${HERCULES_SERVER_MODE} mode on ${ARCH}."
echo "Distribution will be assembled in ${BUILD_TARGET}."

# Disable Hercules' memory manager on arm64 to stop servers crashing
# https://herc.ws/board/topic/18230-support-for-armv8-is-it-possible/#comment-96631
if [[ ${ARCH} == "arm64v8" ]]; then
   echo "Running on arm64 - adding --disable-manager to build options to stop crashes."
   HERCULES_BUILD_OPTS=$HERCULES_BUILD_OPTS" --disable-manager"
fi

# Set the packet version if it's been passed in.
if [[ ! -z "${HERCULES_PACKET_VERSION}" ]]; then
   echo "Specifying packet version ${HERCULES_PACKET_VERSION}."
   HERCULES_BUILD_OPTS=$HERCULES_BUILD_OPTS" --enable-packetver=${HERCULES_PACKET_VERSION}"
fi

echo "Build options: ${HERCULES_BUILD_OPTS}"

echo "Updating package database..."
apt-get update
echo "Installing build tools..."
apt-get install -y gcc git make
echo "Installing dependencies..."
apt-get install -y zlib1g-dev libmysqlclient-dev libpcre3-dev libssl-dev

echo "Build Hercules with ${HERCULES_BUILD_OPTS}..."
cd ${REPO_CHECKOUT}
./configure ${HERCULES_BUILD_OPTS}
make

declare -a serverdata=("cache" "conf" "db" "log" "maps" "npc" "plugins" "save")
for path in "${serverdata[@]}"
do
   echo "Copying $path to distribution..."
   mkdir -p ${BUILD_TARGET}/$path
   cp -r ${REPO_CHECKOUT}/$path/* ${BUILD_TARGET}/$path/
done

echo "Copying executables into distribution..."
cp ${REPO_CHECKOUT}/athena-start ${BUILD_TARGET}/
cp ${REPO_CHECKOUT}/char-server ${BUILD_TARGET}/
cp ${REPO_CHECKOUT}/login-server ${BUILD_TARGET}/
cp ${REPO_CHECKOUT}/map-server ${BUILD_TARGET}/

echo "Remove unnecessary configuration templates from distribution..."
rm -rf ${BUILD_TARGET}/conf/import-tmpl

if [[ ${HERCULES_SERVER_MODE} == "classic" ]]; then
   echo "Copy Classic SQL files into distribution..."
   mkdir -p ${BUILD_TARGET}/sql-files/classic
   cp ${REPO_CHECKOUT}/sql-files/main.sql ${BUILD_TARGET}/sql-files/classic/1-main.sql 
   cp ${REPO_CHECKOUT}/sql-files/item_db.sql ${BUILD_TARGET}/sql-files/classic/2-item_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_db.sql ${BUILD_TARGET}/sql-files/classic/3-mob_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_skill_db.sql ${BUILD_TARGET}/sql-files/classic/4-mob_skill_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/item_db2.sql ${BUILD_TARGET}/sql-files/classic/5-item_db2.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_db2.sql ${BUILD_TARGET}/sql-files/classic/6-mob_db2.sql 
   cp ${REPO_CHECKOUT}/sql-files/logs.sql ${BUILD_TARGET}/sql-files/classic/8-logs.sql 
elif [[ ${HERCULES_SERVER_MODE} == "renewal" ]]; then
   echo "Copy Renewal SQL files into distribution..."
   mkdir -p ${BUILD_TARGET}/sql-files/renewal
   cp ${REPO_CHECKOUT}/sql-files/main.sql ${BUILD_TARGET}/sql-files/renewal/1-main.sql 
   cp ${REPO_CHECKOUT}/sql-files/item_db_re.sql ${BUILD_TARGET}/sql-files/renewal/2-item_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_db_re.sql ${BUILD_TARGET}/sql-files/renewal/3-mob_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_skill_db_re.sql ${BUILD_TARGET}/sql-files/renewal/4-mob_skill_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/item_db2.sql ${BUILD_TARGET}/sql-files/renewal/5-item_db2.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_db2.sql ${BUILD_TARGET}/sql-files/renewal/6-mob_db2.sql 
   cp ${REPO_CHECKOUT}/sql-files/logs.sql ${BUILD_TARGET}/sql-files/renewal/8-logs.sql 
else
   echo "ERROR: Unknown server mode ${HERCULES_SERVER_MODE}!"
   exit 1
fi

echo "Package up the distribution..."
cp -r /build/distrib-tmpl/* ${BUILD_TARGET}/
cp ${BUILD_TARGET}-tmpl/.env ${BUILD_TARGET}
chmod -R a+rwx /build
cd /build
tar -zcf /build/${BUILD_IDENTIFIER}_`date +"%Y-%m-%d_%H-%M-%S"`.tar.gz ${BUILD_TARGET}
