#!/bin/ash

echo "Installing build tools and dependencies..."
apk add --no-cache git gcc make zlib-dev mariadb-connector-c-dev pcre-dev libressl-dev musl-dev linux-headers

echo "Getting Hercules source code..."
git clone https://github.com/HerculesWS/Hercules /build/hercules-src

WORKSPACE="/build"

HERCULES_SRC=${WORKSPACE}/hercules-src
BUILD_TIMESTAMP=`date +"%Y-%m-%d_%H-%M-%S"`
PACKETVER_FROM_SOURCE=`cat ${HERCULES_SRC}/src/common/mmo.h | sed -n -e 's/^.*#define PACKETVER \(.*\)/\1/p'`
GIT_VERSION=`cd ${HERCULES_SRC}; git describe --tags --exact-match 2> /dev/null || git symbolic-ref -q --short HEAD || git rev-parse --short HEAD; cd ${WORKSPACE}`
BUILD_IDENTIFIER=hercules
DISTRIB_PATH=${WORKSPACE}/distrib
BUILD_TARGET=${DISTRIB_PATH}/${BUILD_IDENTIFIER}
BUILD_ARCHIVE=${WORKSPACE}/${BUILD_IDENTIFIER}_${BUILD_TIMESTAMP}.tar.gz

# Patch out Hercules' compile root check to speed up builds by literally a minute
sed -i.bak -e "s/\$euid\" == \"0\"/$euid\" == \"-1\"/" ${HERCULES_SRC}/configure.ac

echo "Building Hercules ${GIT_VERSION} in ${HERCULES_SERVER_MODE} mode."
echo "Distribution will be assembled in ${DISTRIB_PATH}."

# Disable Hercules' memory manager on arm64 to stop servers crashing
# https://herc.ws/board/topic/18230-support-for-armv8-is-it-possible/#comment-96631
if [[ ${ARCH} == "arm64v8" || ${ARCH} == "aarch64" ]]; then
   echo "Running on arm64 - adding --disable-manager to build options to stop crashes."
   HERCULES_BUILD_OPTS=$HERCULES_BUILD_OPTS" --disable-manager"
fi

# Set the packet version if it's been passed in.
if [[ ! -z "${HERCULES_PACKET_VERSION}" && ${HERCULES_PACKET_VERSION} != "default" ]]; then
   echo "Specifying packet version ${HERCULES_PACKET_VERSION}."
   HERCULES_BUILD_OPTS=$HERCULES_BUILD_OPTS" --enable-packetver=${HERCULES_PACKET_VERSION}"
fi

# Disable Renewal on Classic mode builds
if [[ ${HERCULES_SERVER_MODE} == "classic" ]]; then
   HERCULES_BUILD_OPTS=$HERCULES_BUILD_OPTS" --disable-renewal"
fi

echo "Build Hercules with options: ${HERCULES_BUILD_OPTS}..."
rm -rf ${BUILD_TARGET}
cd ${HERCULES_SRC}
echo "Now in "`pwd`
echo `ls`
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
serverdata="cache conf db log maps npc plugins save"
for path in ${serverdata}
do
   echo "Copying $path to distribution..."
   mkdir -p ${BUILD_TARGET}/$path
   cp -r ${HERCULES_SRC}/$path/* ${BUILD_TARGET}/$path/
done

echo "Copying executables into distribution..."
cp ${HERCULES_SRC}/athena-start ${BUILD_TARGET}/
cp ${HERCULES_SRC}/char-server ${BUILD_TARGET}/
cp ${HERCULES_SRC}/login-server ${BUILD_TARGET}/
cp ${HERCULES_SRC}/map-server ${BUILD_TARGET}/

echo "Remove unnecessary configuration templates from distribution..."
rm -rf ${BUILD_TARGET}/conf/import-tmpl

echo "Copying common SQL files into distribution..."
mkdir -p ${BUILD_TARGET}/sql-files/upgrades
cp ${HERCULES_SRC}/sql-files/upgrades/* ${BUILD_TARGET}/sql-files/upgrades/
cp ${HERCULES_SRC}/sql-files/main.sql ${BUILD_TARGET}/sql-files/1-main.sql 
cp ${HERCULES_SRC}/sql-files/item_db2.sql ${BUILD_TARGET}/sql-files/5-item_db2.sql 
cp ${HERCULES_SRC}/sql-files/mob_db2.sql ${BUILD_TARGET}/sql-files/6-mob_db2.sql 
cp ${HERCULES_SRC}/sql-files/mob_skill_db2.sql ${BUILD_TARGET}/sql-files/7-mob_skill_db2.sql 
cp ${HERCULES_SRC}/sql-files/logs.sql ${BUILD_TARGET}/sql-files/8-logs.sql 

if [[ ${HERCULES_SERVER_MODE} == "classic" ]]; then
   echo "Copy Classic SQL files into distribution..."
   mkdir -p ${BUILD_TARGET}/sql-files
   cp ${HERCULES_SRC}/sql-files/item_db.sql ${BUILD_TARGET}/sql-files/2-item_db.sql 
   cp ${HERCULES_SRC}/sql-files/mob_db.sql ${BUILD_TARGET}/sql-files/3-mob_db.sql 
   cp ${HERCULES_SRC}/sql-files/mob_skill_db.sql ${BUILD_TARGET}/sql-files/4-mob_skill_db.sql 
elif [[ ${HERCULES_SERVER_MODE} == "renewal" ]]; then
   echo "Copy Renewal SQL files into distribution..."
   mkdir -p ${BUILD_TARGET}/sql-files
   cp ${HERCULES_SRC}/sql-files/item_db_re.sql ${BUILD_TARGET}/sql-files/2-item_db.sql 
   cp ${HERCULES_SRC}/sql-files/mob_db_re.sql ${BUILD_TARGET}/sql-files/3-mob_db.sql 
   cp ${HERCULES_SRC}/sql-files/mob_skill_db_re.sql ${BUILD_TARGET}/sql-files/4-mob_skill_db.sql 
else
   echo "ERROR: Unknown server mode ${HERCULES_SERVER_MODE}!"
   exit 1
fi

echo "Add remaining files from distribution template..."
cp -r ${WORKSPACE}/distrib-tmpl/* ${DISTRIB_PATH}/
cp ${WORKSPACE}/distrib-tmpl/.env ${DISTRIB_PATH}

echo "Add Autolycus to distribution."
git clone https://github.com/fpiesche/autolycus ${DISTRIB_PATH}/autolycus

echo "Adding build version file to distribution..."
VERSION_FILE=${BUILD_TARGET}/version_info.ini
echo "[version_info]" > ${VERSION_FILE}
echo "git_version="${GIT_VERSION} >> ${VERSION_FILE}
echo "packet_version="${HERCULES_PACKET_VERSION:-${PACKETVER_FROM_SOURCE}} >> ${VERSION_FILE}
echo "server_mode="${HERCULES_SERVER_MODE} >> ${VERSION_FILE}
echo "build_date="${BUILD_TIMESTAMP} >> ${VERSION_FILE}
echo "arch="${ARCH} >> ${VERSION_FILE}

echo "Package up the distribution..."
cd ${WORKSPACE}
tar -zcf ${BUILD_ARCHIVE} ${DISTRIB_PATH}
chown -R ${USERID}:${USERID} ${DISTRIB_PATH}
chmod -R a+rwx ${DISTRIB_PATH} 
chown ${USERID} ${BUILD_ARCHIVE}
echo "Done!"
