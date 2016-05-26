#!/bin/bash
#===========================================================#
# RocketChat updater via Azure auto install
#===========================================================#
# Use docker to pull the latest images locally.
docker pull rocketchat/rocket.chat
docker pull mongo
# Navigate to the location of the docker-compose file.
cd /usr/local/
# Using docker-compose stop and remove the images.
docker-compose stop rocketchat && docker-compose rm -f rocketchat
docker-compose stop db && docker-compose rm -f db
# Watch the logs to see everything come back up.
docker-compose logs