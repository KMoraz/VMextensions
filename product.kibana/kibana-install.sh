#!/bin/sh

#==========================================#
# Kibana for Azure auto install
# Requires docker and docker-compose
#==========================================#
# Params sents from az_vm.deploy.ps1
CLUSTER="${1}"
NODE="${2}"
NET_BH="${3}"
NET_PH="${4}"
DISC_HOSTS="${5}"
MIN_NODES="${6}"

LOG=/var/log/kibana-auto.log
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

# Create a docker compose file, setting the ES_HEAP_SIZE to half of the available memory [Default: 1G]
wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.yml -O /usr/local/docker-compose.yml

# Create the config folder and a required sub-folder scripts.
cd /usr/local && mkdir elasticsearch && cd elasticsearch && mkdir config && cd config && mkdir scripts

# Download the current eleasticsearch.yml config from the package hosted on the product website 
# and paste the content to an equivalently named file in to the config folder created in the 
# previous step, then open for edit.
# wget https://raw.githubusercontent.com/elastic/elasticsearch/master/distribution/src/main/resources/config/elasticsearch.yml -O /media/data/config/elasticsearch.yml

# OR Build config file from parsed parameters
ELKCONFIG=/usr/local/elasticsearch/config/elasticsearch.yml
echo "# Config Generated: `/bin/date`" > $ELKCONFIG
echo "\n# Cluster $SEPERATOR" >> $ELKCONFIG
echo "cluster.name: $CLUSTER" >> $ELKCONFIG
echo "\n# Node $SEPERATOR" >> $ELKCONFIG
echo "node.name: $NODE" >> $ELKCONFIG
echo "node.master: false" >> $ELKCONFIG
echo "node.data: false" >> $ELKCONFIG
echo "\n# Memory $SEPERATOR" >> $ELKCONFIG
echo "bootstrap.mlockall: true" >> $ELKCONFIG
echo "\n# Network $SEPERATOR" >> $ELKCONFIG
echo "network.bind_host: $NET_BH" >> $ELKCONFIG
echo "network.publish_host: $NET_PH" >> $ELKCONFIG
echo "\n# Discovery $SEPERATOR" >> $ELKCONFIG
echo "discovery.zen.ping.unicast.hosts: [\"$DISC_HOSTS\"]" >> $ELKCONFIG
echo "discovery.zen.minimum_master_nodes: $MIN_NODES" >> $ELKCONFIG

# Place logging.yml file in the same dir as the elasticseach.yml file.
# >> change this to forked version on prod <<
wget https://raw.githubusercontent.com/elastic/elasticsearch/master/distribution/src/main/resources/config/logging.yml -O /usr/local/elasticsearch/config/logging.yml

# Start docker compose to ensure no issues.
cd /usr/local && docker-compose up

# Install any plugins needed. Use "sudo docker ps -a" to list the containers for the name (local_elasticsearch_1).
docker exec -it local_elasticsearch_1 /usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf/

# Create an init script to start the container on boot.
wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.conf -O /etc/init/docker-compose.conf

# Reboot
#reboot now

exit 1
