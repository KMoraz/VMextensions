#!/bin/sh

#==========================================#
# Logstash for Azure auto install
# Requires docker and docker-compose
#==========================================#
ELKHOST="${1}"
PORT="${2}"
TEMPLATE_URL="${3}"

LOG=/var/log/logstash-extension.log

# Check root privilages
GOTROOT=`whoami`
if [ "$GOTROOT" != "root" ]; then
	/bin/date > $LOG
	echo "must be root to execute" >> $LOG
	exit 1
fi

# Update and clean distro
apt-get -y update && apt-get -y dist-upgrade && apt-get autoremove -y

# Install wget and curl if not already on system
hash wget 2>/dev/null || { sudo apt-get install wget; }
hash curl 2>/dev/null || { sudo apt-get install curl; }

# Create a docker compose file.
wget https://raw.githubusercontent.com/SuDT/ELK/master/docker-compose.yml -O /usr/local/docker-compose.yml

# Get the logstash config file.
wget https://raw.githubusercontent.com/SuDT/ELK/master/logstash.conf -O /usr/local/logstash.conf

# Start docker compose to ensure no issues.
cd /usr/local && docker-compose up

# Install logstash template on ELK server:
#TEMPLATE="`wget -qO- $TEMPLATE_URL`"
TEMPLATE="`wget -qO- https://raw.githubusercontent.com/SuDT/ELK/master/logstash_netflow5.template`"
curl -XPUT localhost:9200/_template/logstash_netflow5 -d "$TEMPLATE"

# Remote install is unsafe as cURL sends passwords in clear text in HTTP header
#curl -u ${USER_ID}:${PASSWORD} -XPUT ${ELKHOST}:${PORT}/_template/logstash_netflow5 -d "$TEMPLATE"

# SSH solution safer:
#cat $TEMPLATE | ssh $USER@$ELKHOST "cat > /usr/local/$TEMPLATE ; curl -XPUT localhost:9200/_template/logstash_netflow5 -d "$TEMPLATE" "

exit 1