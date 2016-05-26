#!/bin/bash
#==========================================#
# ELK via Azure auto install
# Requires docker and docker-compose
#==========================================#
# Params sent from az_vm.deploy.ps1
CLUSTER="${1}"
NODE="${2}"
NET_BH="${3}"
NET_PH="${4}"
DISC_HOSTS="${5}"
MIN_NODES="${6}"

LOG=/var/log/elk-auto.log
SEPERATOR="----------------\r"

# check command execution & display this message if missing params
if [ "$#" != 6 ]; then
	echo "Usage: elk-install.sh CLUSTER NODE NET_BH NET_PH DISC_HOSTS MIN_NODES"
	echo "This script will auto install Elasticsearch via docker container"
	echo "Example: sudo elk-install.sh elksyscluster elksysclustersvr01 0.0.0.0 172.21.249.5 172.21.249.5 1"
	exit 2
fi

# Check root privilages
GOTROOT=`whoami`
if [ "$GOTROOT" != "root" ]; then
	echo "must be root to execute"
	exit 1
fi

# Update and clean distro
apt-get -y update && apt-get -y dist-upgrade && apt-get autoremove -y

# Install wget if not already on system
hash wget 2>/dev/null || { sudo apt-get install wget; }

# Create a docker compose file, setting the ES_HEAP_SIZE to half of the available memory [Default: 1G]
wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.yml -O /usr/local/docker-compose.yml

# Manually create the config folder and a required sub-folder scripts.
cd /media/data && mkdir config && cd config && mkdir scripts

# Download the current eleasticsearch.yml config from the package hosted on the product website 
# and paste the content to an equivalently named file in to the config folder created in the 
# previous step, then open for edit.
# wget https://raw.githubusercontent.com/elastic/elasticsearch/master/distribution/src/main/resources/config/elasticsearch.yml -O /media/data/config/elasticsearch.yml

# OR - Build new yml config file from parsed parameters
ELKCONFIG=/media/data/config/elasticsearch.yml
echo -e "# Config Generated: `/bin/date`" > $ELKCONFIG
echo -e "\n# Cluster $SEPERATOR" >> $ELKCONFIG
echo -e "cluster.name: $CLUSTER" >> $ELKCONFIG
echo -e "\n# Node $SEPERATOR" >> $ELKCONFIG
echo -e "node.name: $NODE" >> $ELKCONFIG
echo -e "\n# Memory $SEPERATOR" >> $ELKCONFIG
echo -e "bootstrap.mlockall: true" >> $ELKCONFIG
echo -e "\n# Network $SEPERATOR" >> $ELKCONFIG
echo -e "network.bind_host: $NET_BH" >> $ELKCONFIG
echo -e "network.publish_host: $NET_PH" >> $ELKCONFIG
echo -e "\n# Discovery $SEPERATOR" >> $ELKCONFIG
echo -e "discovery.zen.ping.unicast.hosts: [\"$DISC_HOSTS\"]" >> $ELKCONFIG
echo -e "discovery.zen.minimum_master_nodes: $MIN_NODES" >> $ELKCONFIG

# Place logging.yml file in the same dir as the elasticseach.yml file.
# >> change this to forked version on prod <<
wget https://raw.githubusercontent.com/elastic/elasticsearch/master/distribution/src/main/resources/config/logging.yml -O /media/data/config/logging.yml

# Start docker compose to ensure no issues.
cd /usr/local && docker-compose up

# Install any plugins needed. Use "sudo docker ps -a" to list the containers for the name (local_elasticsearch_1).
docker exec -it local_elasticsearch_1 /usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf/

# Create an init script to start the container on boot.
wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.conf -O /etc/init/docker-compose.conf

# Reboot
reboot now


# TO REMOVE DOS LINE ENDINGS (M) WITH VI - ":set fileformat=unix"