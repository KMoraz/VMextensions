#!/bin/bash
#===========================================================#
# RocketChat with MongoDB via Azure auto install
# Prerequisites: run drive.provision.sh
#===========================================================#
# Params sent from az_vm.deploy.ps1
DB_PORT="${1}"
RC_PORT="${2}"
ROOT_URL="${3}"
USERNAME="${4}"

# Create Variables
#IP=`hostname -I`
IP=`ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
DATE=`date +%d.%m.%y-%H.%M.%S`
LOG=/var/log/rocketchat-auto-${DATE}.log
SEPERATOR="----------------\r"
#Color
GREEN=`tput setaf 2`
NORM=`tput sgr0`

# Check command execution & display this message if missing params
if [ "$#" != 3 ] && [ "$#" != 4 ]; then
	echo "Usage: rocketchat-install.sh DB_PORT RC_PORT ROOT_URL ${GREEN}USERNAME [optional]$NORM"
	echo "This script will auto install RocketChat & MongoDB via docker containers"
	echo "Example: ${GREEN}sudo ./rocketchat-install.sh 27017 3000 chatter.mydomain.com${NORM}"
	exit 2
fi
# Check root privilages
GOTROOT=`whoami`
if [ "$GOTROOT" != "root" ]; then
	echo "must be root to execute"
	exit 1
fi

#===========================
# CREATE MAIN LOG FILE
#===========================
echo -e "RocketChat with MongoDB via Azure auto install (rocketchat-install.sh)" > $LOG
echo -e "Start Date/Time: `/bin/date`" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo -e "Hostname = `hostname`" >> $LOG
echo -e "IP on eth0 = $IP" >> $LOG
echo -e "MongoDB Port = $DB_PORT" >> $LOG
echo -e "RocketChat Port = $RC_PORT" >> $LOG
echo -e "RC URL = $ROOT_URL" >> $LOG
echo -e "$SEPERATOR" >> $LOG
# Update and clean distro
echo -e "Running system updates..." >> $LOG
apt-get -y update
echo -e "Update completed: `/bin/date`" >> $LOG
echo -e "$SEPERATOR" >> $LOG

#==============================
# PROVISION DATA DRIVE /dev/sdc
#==============================
TGTDEV=/dev/sdc

# Automate fdisk process with sed
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  w # write the partition table
  q # and we're done
EOF

# Format the drive & modify reserved space
mkfs -t ext3 ${TGTDEV}1 && tune2fs -m 0 ${TGTDEV}1
# Add the drive mount details at the end of the fstab file.
echo -e "${TGTDEV}1 \t/media/data \text3 \tdefaults \t0 \t2" >> /etc/fstab
# Create the new mount point, reload fstab and mount new drive to /media/data
DATA=/media/data

if [ ! -d "$DATA" ]; then
  mkdir $DATA
fi

cd /media && mount -a

echo -e "Provisioned data drive ${TGTDEV} mounted at ${DATA}" >> $LOG
echo -e "$SEPERATOR" >> $LOG

#===========================
# DOCKER
#===========================
# Install wget if not already on system
hash wget 2>/dev/null || { echo -e "Installing wget..." >> $LOG; apt-get install -y wget; }

#Get the latest docker package if not installed.
get.docker(){
hash docker 2>/dev/null || { echo -e "Installing docker..." >> $LOG; wget -qO- https://get.docker.com/ | sh; echo -e "`docker --version`" >> $LOG; }

# If additional users required
if [ ! -z "$USERNAME" ]; then
	echo -e "Creating additional docker user: $USERNAME" >> $LOG
	usermod -aG docker $USERNAME
fi
}
get.docker

#===========================
# DOCKER-COMPOSE
#===========================
# Install curl if not already on system
hash curl 2>/dev/null || { echo -e "Installing cURL..." >> $LOG; apt-get install -y curl; }

# Download Latest Docker Compose from GutHub: https://github.com/docker/compose/releases
COMPOSE_VER="1.7.1"
COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-Linux-x86_64"
COMPOSE_DIR=/usr/local/bin/docker-compose

if [ ! -f "$COMPOSE_DIR" ];
then
    curl -L $COMPOSE_URL > $COMPOSE_DIR
    # set execute permissions on the install folder.
	chmod +x $COMPOSE_DIR
	echo -e "Installing Docker-Compose $COMPOSE_VER to $COMPOSE_DIR" >> $LOG
	echo -e "`docker-compose --version` successfully installed" >> $LOG
else
	echo -e "`docker-compose --version` already installed" >> $LOG
fi

#===========================
# ROCKETCHAT & MONGODB
#===========================
# Create/pull a docker compose file, setting the ES_HEAP_SIZE to half of the available memory [Default: 1G]
#wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.yml -O /usr/local/docker-compose.yml
COMPOSE=/usr/local/docker-compose
echo -e "db: " > $COMPOSE.temp
echo -e "  image: mongo" >> $COMPOSE.temp
echo -e "  volumes:" >> $COMPOSE.temp
echo -e "    - /media/rocketchat/data/db:/data/db" >> $COMPOSE.temp
echo -e "    - /media/rocketchat/data/dump:/dump" >> $COMPOSE.temp
echo -e "  command: mongod --smallfiles" >> $COMPOSE.temp
echo -e "  ports:" >> $COMPOSE.temp
echo -e "    - ${DB_PORT}:${DB_PORT}" >> $COMPOSE.temp
echo -e "\nrocketchat:" >> $COMPOSE.temp
echo -e "  image: rocketchat/rocket.chat:latest" >> $COMPOSE.temp
echo -e "  environment:" >> $COMPOSE.temp
echo -e "    - MONGO_URL=mongodb://db:$DB_PORT/rocketchat" >> $COMPOSE.temp
echo -e "    - ROOT_URL=https://$ROOT_URL" >> $COMPOSE.temp
echo -e "  links:" >> $COMPOSE.temp
echo -e "    - db:db" >> $COMPOSE.temp
echo -e "  ports:" >> $COMPOSE.temp
echo -e "    - ${RC_PORT}:${RC_PORT}" >> $COMPOSE.temp

# rename temp file to new yml compose
if [ -f "$COMPOSE.yml" ]
then
    rm -r $COMPOSE.yml
fi
mv $COMPOSE.temp $COMPOSE.yml
echo -e "Created docker-compose file: $COMPOSE.yml" >> $LOG

# Manually create the config folder and a required sub-folder scripts.
mkdir -p /media/rocketchat/data/{db,dump}
echo -e "Created directories: /media/rocketchat/data/{db,dump}" >> $LOG

# Start docker compose and pull latest images.
echo -e "$SEPERATOR" >> $LOG
echo -e "Initial docker-compose started at: `/bin/date`" >> $LOG
cd /usr/local && docker-compose up -d >> $LOG 2>&1
# wait for compose to complete in order to pull logs
sleep 90
echo -e "Restarting containers to overcome failed to connect to DB on ${PORT}" >> $LOG
docker-compose restart && docker-compose up -d >> $LOG 2>&1
sleep 15

# Create/pull an init script to start the container on boot.
#wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.conf -O /etc/init/docker-compose.conf
INIT=/etc/init/docker-compose.conf
echo -e "description \"Docker-Compose Service Manager\"\n" > $INIT
echo -e "start on filesystem and started docker" >> $INIT
echo -e "stop on runlevel [!2345]\n" >> $INIT
echo -e "respawn" >> $INIT
echo -e "respawn limit 99 5\n" >> $INIT
echo -e "chdir /usr/local\n" >> $INIT
echo -e "script" >> $INIT
echo -e "\texec /usr/local/bin/docker-compose up" >> $INIT
echo -e "end script" >> $INIT

#===========================
# LOG COMPLETION STEPS
#===========================
echo -e "$SEPERATOR" >> $LOG
echo -e "Created initialisation script: /etc/init/docker-compose.conf" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo -e "MongoDB initialisation:" >> $LOG
docker-compose logs | grep 'db' >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo -e "RocketChat initialisation:" >> $LOG
docker-compose logs | grep 'rocketchat' >> $LOG
# ensure SSH is accessible at startup
echo -e "$SEPERATOR" >> $LOG
echo -e "Setting sshd init to defaults on boot" >> $LOG
update-rc.d ssh defaults >> $LOG 2>&1
echo -e "$SEPERATOR" >> $LOG
echo -e "rocketchat-install.sh completed at: `/bin/date`" >> $LOG
echo -e "Service accessible via: ${ROOT_URL}:${RC_PORT} or ${IP}:${RC_PORT}" >> $LOG
echo -e "System will now reboot..." >> $LOG
reboot
#exit 1

# TO REMOVE DOS LINE ENDINGS (M) WITH VI - ":set fileformat=unix"