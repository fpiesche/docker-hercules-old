#!/bin/bash
echo "Updating package database..."
apt-get update
echo "Installing build tools..."
apt-get install -y gcc git make
echo "Installing dependencies..."
apt-get install -y zlib1g-dev libmysqlclient-dev libpcre3-dev libssl-dev

echo "Assuring clean distribution..."
rm -rf /build/hercules

echo "Cloning Hercules repo..."
git clone -b stable https://github.com/HerculesWS/Hercules/ /build/src

echo "Build Hercules with ${HERCULES_BUILD_OPTS}..."
cd /build/src
make clean
./configure ${HERCULES_BUILD_OPTS}
make

echo "Copy server data into distribution..."
declare -a serverdata=("cache" "conf" "db" "log" "maps" "npc" "plugins" "save")
for path in "${serverdata[@]}"
do
   echo "Copying $path"
   mkdir -p /build/hercules/$path
   cp -r /build/src/$path/* /build/hercules/$path/
done

echo "Copying executables into distribution..."
cp /build/src/athena-start /build/hercules/
cp /build/src/char-server /build/hercules/
cp /build/src/login-server /build/hercules/
cp /build/src/map-server /build/hercules/

echo "Remove unnecessary configuration templates from distribution..."
rm -rf /build/hercules/conf/import-tmpl

echo "Copy Classic SQL files into distribution..."
mkdir -p /build/hercules/sql-files/classic
cp /build/src/sql-files/main.sql /build/hercules/sql-files/classic/1-main.sql 
cp /build/src/sql-files/item_db.sql /build/hercules/sql-files/classic/2-item_db.sql 
cp /build/src/sql-files/mob_db.sql /build/hercules/sql-files/classic/3-mob_db.sql 
cp /build/src/sql-files/mob_skill_db.sql /build/hercules/sql-files/classic/4-mob_skill_db.sql 
cp /build/src/sql-files/item_db2.sql /build/hercules/sql-files/classic/5-item_db2.sql 
cp /build/src/sql-files/mob_db2.sql /build/hercules/sql-files/classic/6-mob_db2.sql 
cp /build/src/sql-files/logs.sql /build/hercules/sql-files/classic/8-logs.sql 

echo "Copy Renewal SQL files into distribution..."
mkdir -p /build/hercules/sql-files/renewal
cp /build/src/sql-files/main.sql /build/hercules/sql-files/renewal/1-main.sql 
cp /build/src/sql-files/item_db_re.sql /build/hercules/sql-files/renewal/2-item_db.sql 
cp /build/src/sql-files/mob_db_re.sql /build/hercules/sql-files/renewal/3-mob_db.sql 
cp /build/src/sql-files/mob_skill_db_re.sql /build/hercules/sql-files/renewal/4-mob_skill_db.sql 
cp /build/src/sql-files/item_db2.sql /build/hercules/sql-files/renewal/5-item_db2.sql 
cp /build/src/sql-files/mob_db2.sql /build/hercules/sql-files/renewal/6-mob_db2.sql 
cp /build/src/sql-files/logs.sql /build/hercules/sql-files/renewal/8-logs.sql 

echo "Package up the distribution..."
cp -r /build/hercules-tmpl/* /build/hercules/
cp /build/hercules-tmpl/.env /build/hercules
chmod -R a+rwx /build
rm -rf /build/src
cd /build/hercules
tar -zcvf /build/hercules-`date +"%Y-%m-%d_%H-%M-%S"`.tar.gz .
