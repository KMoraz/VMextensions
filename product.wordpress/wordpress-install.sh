#!/bin/bash
set -e
#===========================================================#
# WordPress with MySQL via Azure auto install
# Prerequisites: run drive.provision.sh
#===========================================================#
# Params sent from az_vm.deploy.ps1
PRODUCT="${1}"

# Create Variables
#IP=`hostname -I`
IP=`ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
DATE=`date +%d.%m.%y-%H.%M.%S`
LOG=/var/log/docker-${PRODUCT}-auto-${DATE}.log
SEPERATOR="--------------------------------------\r"
#Color
GREEN=`tput setaf 2`
NORM=`tput sgr0`

# Check command execution & display this message if missing params
if [ "$#" != 1 ]; then
	echo "Usage: auto-docker-install.sh $PRODUCT"
	echo "This script will auto install docker & docker-compose with specified product(s)"
	echo "Example: ${GREEN}sudo ./auto-docker-install.sh wordpress${NORM}"
	exit 2
fi

# Check root privilages
GOTROOT=`whoami`
if [ "$GOTROOT" != "root" ]; then
	echo "must be root to execute"
	exit 1
fi

# Verify product parameter
if [[ $PRODUCT == *".yml" ]]
then
	PRODUCT=`echo $PRODUCT | rev | cut -d"." -f2  | rev`
fi

#===========================
# CREATE MAIN LOG FILE
#===========================
echo "WordPress with MySQL via Azure auto install (auto-docker-install.sh)" > $LOG
echo "Start Date/Time: `/bin/date`" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo "Hostname = `hostname`" >> $LOG
echo "IP on eth0 = $IP" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo "Running system updates..." >> $LOG
apt-get -y update
echo "Update completed: `/bin/date`" >> $LOG
echo -e "$SEPERATOR" >> $LOG

#===========================
# DOCKER
#===========================
# Install wget & cURL if not already on system
hash wget 2>/dev/null || { echo "Installing wget..." >> $LOG; apt-get install -y wget; }
hash curl 2>/dev/null || { echo "Installing cURL..." >> $LOG; apt-get install -y curl; }

#Get the latest docker package if not installed.
hash docker 2>/dev/null || { echo "Installing docker..." >> $LOG; wget -qO- https://get.docker.com/ | sh; }
echo "`docker --version`" >> $LOG

#if ! type -p docker > /dev/null;
#	then 
#	echo "Installing docker..." >> $LOG
#	wget -qO- https://get.docker.com/ | sh
#	echo "`docker --version`" >> $LOG
#else
#	echo "`docker --version`" >> $LOG
#fi

#===========================
# DOCKER-COMPOSE
#===========================
# Download Latest Docker Compose from GutHub: https://github.com/docker/compose/releases
COMPOSE_VER="1.7.1"
COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-Linux-x86_64"
COMPOSE_DIR=/usr/local/bin/docker-compose

if [ ! -f "$COMPOSE_DIR" ];
then
    curl -L $COMPOSE_URL > $COMPOSE_DIR
    # set execute permissions on the install folder.
	chmod +x $COMPOSE_DIR
	echo "Installing Docker-Compose $COMPOSE_VER to $COMPOSE_DIR" >> $LOG
	echo "`docker-compose --version` successfully installed" >> $LOG
else
	echo "`docker-compose --version` already installed" >> $LOG
fi

#===========================
# CONTAINER INSTALL
#===========================
INSTALL_DIR=/usr/local/my-${PRODUCT}
if [ -d "$INSTALL_DIR" ];
then
    rm -r $INSTALL_DIR/*
else
	mkdir $INSTALL_DIR
fi
cd $INSTALL_DIR

# Pull a docker compose file
wget http://10.243.54.132/core-infrastructure/infrastructure.iaas/raw/master/docker/compose/$PRODUCT.yml -O docker-compose.yml
echo "Created docker-compose file: $INSTALL_DIR/docker-compose.yml" >> $LOG

# Start docker compose and pull latest images.
echo -e "$SEPERATOR" >> $LOG
echo "Initial docker-compose started at: `/bin/date`" >> $LOG
docker-compose up -d >> $LOG 2>&1
# Copy plugin into running container
#cat ~/updraftplus.tar | docker exec -i mywordpress_wordpress_1 sh -c "cat > ~/updraftplus.tar; cd /var/www/html/wp-content/plugins/; tar xf ~/updraftplus.tar"

# Create/pull an init script to start the container on boot.
#wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.conf -O /etc/init/docker-compose.conf
INIT=/etc/init/${PRODUCT}.conf
echo -e "description \"Docker-Compose Service Manager for $PRODUCT\"\n" > $INIT
echo -e "start on filesystem and started docker" >> $INIT
echo -e "stop on runlevel [!2345]\n" >> $INIT
echo -e "respawn" >> $INIT
echo -e "respawn limit 99 5\n" >> $INIT
echo -e "chdir $INSTALL_DIR\n" >> $INIT
echo -e "script" >> $INIT
echo -e "\texec /usr/local/bin/docker-compose up" >> $INIT
echo -e "end script" >> $INIT

#===========================
# LOG COMPLETION STEPS
#===========================
echo -e "$SEPERATOR" >> $LOG
echo -e "Created initialisation script: /etc/init/${PRODUCT}.conf" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo -e "Initialisation Log:" >> $LOG
docker-compose logs | grep '${PRODUCT}' >> $LOG
# ensure SSH is accessible at startup
echo -e "$SEPERATOR" >> $LOG
#echo -e "Setting sshd init to defaults on boot" >> $LOG
#update-rc.d ssh defaults >> $LOG 2>&1
#echo -e "$SEPERATOR" >> $LOG
#echo -e "$PRODUCT Service accessible via: ${IP}:8080" >> $LOG
echo -e "auto-docker-install.sh completed at: `/bin/date` - system rebooting..." >> $LOG
#reboot
exit 1

# TO REMOVE DOS LINE ENDINGS (M) WITH VI - ":set fileformat=unix"