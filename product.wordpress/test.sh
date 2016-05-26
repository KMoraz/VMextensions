#!/bin/bash
set -e
PRODUCT="${1}"

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

if [[ $PRODUCT == *".yml" ]]
then
	PRODUCT=`echo $PRODUCT | rev | cut -d"." -f2  | rev`
	echo "$PRODUCT"
else
	echo "$PRODUCT is ok"
fi