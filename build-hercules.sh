#!/bin/bash
echo "Updating package database..."
apt-get update
echo "Installing build tools..."
apt-get install -y gcc git make
echo "Installing dependencies..."
apt-get install -y zlib1g-dev libmysqlclient-dev libpcre3-dev libssl-dev

echo "Cloning Hercules repo..."
cd /build
git clone https://github.com/HerculesWS/Hercules/

echo "Build Hercules with ${HERCULES_BUILD_OPTS}..."
cd /build/Hercules
./configure ${HERCULES_BUILD_OPTS}
make

echo "Adding destination paths for distribution..."
mkdir -p /build/distrib
mkdir -p /build/distrib/sql-files/classic
mkdir -p /build/distrib/sql-files/renewal

echo "Move server data into the distribution..."
mv /build/Hercules/athena-start /build/distrib/
mv /build/Hercules/conf /build/distrib/
mv /build/Hercules/cache /build/distrib/
mv /build/Hercules/db /build/distrib/
mv /build/Hercules/log /build/distrib/
mv /build/Hercules/maps /build/distrib/
mv /build/Hercules/npc /build/distrib/
mv /build/Hercules/plugins /build/distrib/
mv /build/Hercules/save /build/distrib/
mv /build/Hercules/char-server /build/distrib/
mv /build/Hercules/login-server /build/distrib/
mv /build/Hercules/map-server /build/distrib/

echo "Remove unnecessary configuration templates from distribution..."
rm /build/distrib/conf/import-tmpl

echo "Prepare Classic SQL files for distribution..."
cp /build/Hercules/sql-files/main.sql /build/distrib/sql-files/classic/1-main.sql 
cp /build/Hercules/sql-files/item_db.sql /build/distrib/sql-files/classic/2-item_db.sql 
cp /build/Hercules/sql-files/mob_db.sql /build/distrib/sql-files/classic/3-mob_db.sql 
cp /build/Hercules/sql-files/mob_skill_db.sql /build/distrib/sql-files/classic/4-mob_skill_db.sql 
cp /build/Hercules/sql-files/item_db2.sql /build/distrib/sql-files/classic/5-item_db2.sql 
cp /build/Hercules/sql-files/mob_db2.sql /build/distrib/sql-files/classic/6-mob_db2.sql 
cp /build/Hercules/sql-files/logs.sql /build/distrib/sql-files/classic/8-logs.sql 

echo "Prepare Renewal SQL files for distribution..."
cp /build/Hercules/sql-files/main.sql /build/distrib/sql-files/renewal/1-main.sql 
cp /build/Hercules/sql-files/item_db_re.sql /build/distrib/sql-files/renewal/2-item_db.sql 
cp /build/Hercules/sql-files/mob_db_re.sql /build/distrib/sql-files/renewal/3-mob_db.sql 
cp /build/Hercules/sql-files/mob_skill_db_re.sql /build/distrib/sql-files/renewal/4-mob_skill_db.sql 
cp /build/Hercules/sql-files/item_db2.sql /build/distrib/sql-files/renewal/5-item_db2.sql 
cp /build/Hercules/sql-files/mob_db2.sql /build/distrib/sql-files/renewal/6-mob_db2.sql 
cp /build/Hercules/sql-files/logs.sql /build/distrib/sql-files/renewal/8-logs.sql 

echo "Package up the distribution..."
cd /build
tar -zcvf /build/hercules`date +"%Y-%m-%d_%H-%M-%S"`.tar.gz /build/distrib
