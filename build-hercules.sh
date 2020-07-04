#!/bin/bash
echo "Updating package database..."
apt-get update
echo "Installing build tools..."
apt-get install -y gcc git make
echo "Installing dependencies..."
apt-get install -y zlib1g-dev libmysqlclient-dev libpcre3-dev libssl-dev

echo "Cloning Hercules repo..."
cd /build
rm -rf Hercules
git clone https://github.com/HerculesWS/Hercules/
chmod a+rwx Hercules
git reset --hard HEAD^

echo "Build Hercules with ${HERCULES_BUILD_OPTS}..."
cd /build/Hercules
make clean
./configure ${HERCULES_BUILD_OPTS}
make

echo "Assuring clean distribution..."
rm -rf /build/hercules
cp -r /build/hercules-tmpl /build/hercules

echo "Adding destination paths for distribution..."
mkdir -p /build/hercules
mkdir -p /build/hercules/sql-files/classic
mkdir -p /build/hercules/sql-files/renewal

echo "Move server data into the distribution..."
cp /build/Hercules/athena-start /build/hercules/
cp -nr /build/Hercules/conf /build/hercules/
cp -r /build/Hercules/cache /build/hercules/
cp -r /build/Hercules/db /build/hercules/
cp -r /build/Hercules/log /build/hercules/
cp -r /build/Hercules/maps /build/hercules/
cp -r /build/Hercules/npc /build/hercules/
cp -r /build/Hercules/plugins /build/hercules/
cp -r /build/Hercules/save /build/hercules/
cp -r /build/Hercules/char-server /build/hercules/
cp -r /build/Hercules/login-server /build/hercules/
cp -r /build/Hercules/map-server /build/hercules/

echo "Remove unnecessary configuration templates from distribution..."
rm -rf /build/hercules/conf/import-tmpl

echo "Prepare Classic SQL files for distribution..."
cp /build/Hercules/sql-files/main.sql /build/hercules/sql-files/classic/1-main.sql 
cp /build/Hercules/sql-files/item_db.sql /build/hercules/sql-files/classic/2-item_db.sql 
cp /build/Hercules/sql-files/mob_db.sql /build/hercules/sql-files/classic/3-mob_db.sql 
cp /build/Hercules/sql-files/mob_skill_db.sql /build/hercules/sql-files/classic/4-mob_skill_db.sql 
cp /build/Hercules/sql-files/item_db2.sql /build/hercules/sql-files/classic/5-item_db2.sql 
cp /build/Hercules/sql-files/mob_db2.sql /build/hercules/sql-files/classic/6-mob_db2.sql 
cp /build/Hercules/sql-files/logs.sql /build/hercules/sql-files/classic/8-logs.sql 

echo "Prepare Renewal SQL files for distribution..."
cp /build/Hercules/sql-files/main.sql /build/hercules/sql-files/renewal/1-main.sql 
cp /build/Hercules/sql-files/item_db_re.sql /build/hercules/sql-files/renewal/2-item_db.sql 
cp /build/Hercules/sql-files/mob_db_re.sql /build/hercules/sql-files/renewal/3-mob_db.sql 
cp /build/Hercules/sql-files/mob_skill_db_re.sql /build/hercules/sql-files/renewal/4-mob_skill_db.sql 
cp /build/Hercules/sql-files/item_db2.sql /build/hercules/sql-files/renewal/5-item_db2.sql 
cp /build/Hercules/sql-files/mob_db2.sql /build/hercules/sql-files/renewal/6-mob_db2.sql 
cp /build/Hercules/sql-files/logs.sql /build/hercules/sql-files/renewal/8-logs.sql 

echo "Package up the distribution..."
chmod -R a+rwx /build
tar -zcf /build/hercules-`date +"%Y-%m-%d_%H-%M-%S"`.tar.gz /build/hercules
