#!/bin/bash
set -e
#===========================================================#
# Azure auto install via VMextensions
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
YELLOW=`tput setaf 3`
NORM=`tput sgr0`

# Check command execution & display this message if missing params
if [ "$#" != 1 ] && [ "$#" != 2 ]; then
	echo "${GREEN}Usage: auto-docker-install.sh PRODUCT"
	echo "${YELLOW}This script will auto install docker & docker-compose with specified product(s)"
	echo "${GREEN}Example: sudo ./auto-docker-install.sh wordpress${NORM}"
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
echo "Azure extension (auto-docker-install.sh) for $PRODUCT" > $LOG
echo "Start Date/Time: `/bin/date`" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo "Hostname = `hostname`" >> $LOG
echo "IP on eth0 = $IP" >> $LOG
echo -e "$SEPERATOR" >> $LOG
echo "Running system updates..." >> $LOG
apt-get -y update
echo "Update completed: `/bin/date`" >> $LOG
echo -e "$SEPERATOR" >> $LOG

#==============================
# DRIVE PROVISION FOR SDC (1TB)
#==============================
TGT_DEV=/dev/sdc
if [ -e $TGT_DEV ]; then
	echo -e "Provisioning Data Drive: $TGT_DEV" >> $LOG
	#wget -qO- http://10.243.54.132/core-infrastructure/infrastructure.iaas/raw/master/docker/drive.provision.sh | sh
	
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGT_DEV}
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
    # default, extend partition to end of disk
  w # write the partition table
  q # and we're done
EOF

	# Format the drive && modify reserved space
	mkfs -t ext3 ${TGT_DEV}1 && tune2fs -m 0 ${TGT_DEV}1
	
	# Add the drive mount details at the end of the fstab file.
	echo -e "\n${TGT_DEV}1 \t/media/data \text3 \tdefaults \t0 \t2" >> /etc/fstab
	
	# Create new mount point, reload fstab and mount new drive to /media/data
	DATA=/media/data
	if [ ! -d "$DATA" ]; then
  	mkdir $DATA
	fi
	cd /media && mount -a

	echo -e "$TGT_DEV mounted to: $DATA" >> $LOG
fi

#===========================
# DOCKER
#===========================
# Install wget & cURL if not already on system
hash wget 2>/dev/null || { echo "Installing wget..." >> $LOG; apt-get install -y wget; }
hash curl 2>/dev/null || { echo "Installing cURL..." >> $LOG; apt-get install -y curl; }

# Get the latest docker package if not installed.
hash docker 2>/dev/null || { echo "Installing docker..." >> $LOG; wget -qO- https://get.docker.com/ | sh; } 
echo "`docker --version`" >> $LOG

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
	echo "`docker-compose --version`" >> $LOG
fi

#===========================
# CONTAINER INSTALL
#===========================
INSTALL_DIR=/usr/local/dc_${PRODUCT}

if [ -d "$INSTALL_DIR" ];
then
    rm -r $INSTALL_DIR/*
else
	mkdir $INSTALL_DIR
fi
cd $INSTALL_DIR

# Pull docker-compose file
#GIT_LAB=http://10.243.54.132/core-infrastructure/infrastructure.iaas/raw/master/docker
GIT_LAB=https://raw.githubusercontent.com/SuDT/VMextensions/master/docker
wget $GIT_LAB/compose/$PRODUCT.yml -O docker-compose.yml
echo "Created docker-compose file: $INSTALL_DIR/docker-compose.yml" >> $LOG

if [ $PRODUCT == "logstash" ]; then
   wget $GIT_LAB/config/logstash.conf -O logstash.conf
   echo "Logstash config file added: $INSTALL_DIR/logstash.conf" >> $LOG
fi

# Start docker-compose and pull latest images
echo -e "$SEPERATOR" >> $LOG
echo "Initial docker-compose started at: `/bin/date`" >> $LOG
docker-compose up -d >> $LOG 2>&1

# Create init script to start container(s) on boot
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