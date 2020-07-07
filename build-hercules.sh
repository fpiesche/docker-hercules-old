#!/bin/bash

echo "Updating package database..."
apt-get update
echo "Installing build tools and dependencies..."
apt-get install -y git gcc make zlib1g-dev libmysqlclient-dev libpcre3-dev libssl-dev

REPO_CHECKOUT=/build/hercules-src
BUILD_TIMESTAMP=`date +"%Y-%m-%d_%H-%M-%S"`
PACKETVER_FROM_SOURCE=`cat ${REPO_CHECKOUT}/src/common/mmo.h | sed -n -e 's/^.*#define PACKETVER \(.*\)/\1/p'`
GIT_VERSION=`cd ${REPO_CHECKOUT}; git describe --tags --exact-match 2> /dev/null || git symbolic-ref -q --short HEAD || git rev-parse --short HEAD; cd /build/`
BUILD_IDENTIFIER=hercules_${HERCULES_SERVER_MODE}_packetver-${HERCULES_PACKET_VERSION:-$PACKETVER_FROM_SOURCE}_${ARCH}
BUILD_TARGET=/build/${BUILD_IDENTIFIER}
BUILD_ARCHIVE=/build/${BUILD_IDENTIFIER}_${BUILD_TIMESTAMP}.tar.gz

echo "Building Hercules ${GIT_VERSION} in ${HERCULES_SERVER_MODE} mode on ${ARCH}."
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

echo "Build Hercules with options: ${HERCULES_BUILD_OPTS}..."
rm -rf ${BUILD_TARGET}
cd ${REPO_CHECKOUT}
make clean
./configure ${HERCULES_BUILD_OPTS}
if [[ $? -ne 0 ]]; then
   echo "CONFIGURE FAILED"
   exit 1
fi
make
if [[ $? -ne 0 ]]; then
   echo "BUILD FAILED"
   exit 1
fi

# Copy server data to distribution directory
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

echo "Copying common SQL files into distribution..."
mkdir -p ${BUILD_TARGET}/sql-files/upgrades
cp ${REPO_CHECKOUT}/sql-files/upgrades/* ${BUILD_TARGET}/sql-files/upgrades/
cp ${REPO_CHECKOUT}/sql-files/main.sql ${BUILD_TARGET}/sql-files/1-main.sql 
cp ${REPO_CHECKOUT}/sql-files/item_db2.sql ${BUILD_TARGET}/sql-files/5-item_db2.sql 
cp ${REPO_CHECKOUT}/sql-files/mob_db2.sql ${BUILD_TARGET}/sql-files/6-mob_db2.sql 
cp ${REPO_CHECKOUT}/sql-files/mob_skill_db2.sql ${BUILD_TARGET}/sql-files/7-mob_skill_db2.sql 
cp ${REPO_CHECKOUT}/sql-files/logs.sql ${BUILD_TARGET}/sql-files/8-logs.sql 

if [[ ${HERCULES_SERVER_MODE} == "classic" ]]; then
   echo "Copy Classic SQL files into distribution..."
   mkdir -p ${BUILD_TARGET}/sql-files
   cp ${REPO_CHECKOUT}/sql-files/item_db.sql ${BUILD_TARGET}/sql-files/2-item_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_db.sql ${BUILD_TARGET}/sql-files/3-mob_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_skill_db.sql ${BUILD_TARGET}/sql-files/4-mob_skill_db.sql 
elif [[ ${HERCULES_SERVER_MODE} == "renewal" ]]; then
   echo "Copy Renewal SQL files into distribution..."
   mkdir -p ${BUILD_TARGET}/sql-files
   cp ${REPO_CHECKOUT}/sql-files/item_db_re.sql ${BUILD_TARGET}/sql-files/2-item_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_db_re.sql ${BUILD_TARGET}/sql-files/3-mob_db.sql 
   cp ${REPO_CHECKOUT}/sql-files/mob_skill_db_re.sql ${BUILD_TARGET}/sql-files/4-mob_skill_db.sql 
else
   echo "ERROR: Unknown server mode ${HERCULES_SERVER_MODE}!"
   exit 1
fi

echo "Add remaining files from distribution template..."
cp -r /build/distrib-tmpl/* ${BUILD_TARGET}/
cp /build/distrib-tmpl/.env ${BUILD_TARGET}

echo "Adding build version file to distribution..."
VERSION_FILE=${BUILD_TARGET}/version.ini
echo "[version_info]" > ${VERSION_FILE}
echo "git_version="${GIT_VERSION} >> ${VERSION_FILE}
echo "packet_version="${HERCULES_PACKET_VERSION:-${PACKETVER_FROM_SOURCE}} >> ${VERSION_FILE}
echo "server_mode="${HERCULES_SERVER_MODE} >> ${VERSION_FILE}
echo "build_date="${BUILD_TIMESTAMP} >> ${VERSION_FILE}
echo "arch="${ARCH} >> ${VERSION_FILE}

echo "Modify docker-compose.yml for distribution..."
sed -i "s/__PACKET_VER_DEFAULT__/${HERCULES_PACKET_VERSION:-default}/g" ${BUILD_TARGET}/docker-compose.yml
sed -i "s/__SERVER_MODE__/${HERCULES_SERVER_MODE}/g" ${BUILD_TARGET}/docker-compose.yml

echo "Package up the distribution..."
cd /build
tar -zcf ${BUILD_ARCHIVE} ${BUILD_TARGET}
chown -R ${USERID}:${USERID} ${BUILD_TARGET}
chmod -R a+rwx ${BUILD_TARGET} 
chown ${USERID} ${BUILD_ARCHIVE}
echo "Done!"
