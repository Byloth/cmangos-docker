#!/usr/bin/env bash
#

readonly NAME="mangosd-tbc"
readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

docker run --rm -it \
           --name=${NAME} \
           --network=exposed \
           -e CMANGOS_DBHOST="172.17.0.1" \
           -e CMANGOS_DBUSER="mangos" \
           -e CMANGOS_DBPASS="mangos00" \
           -e CMANGOS_GAME_TYPE="0" \
           -e CMANGOS_REALM_ZONE="8" \
           -e CMANGOS_RABBIT_DAY="954547200" \
           -e CMANGOS_MOTD="Benvenuto su Azeroth!" \
           -p 8085:8085 \
           -v ${PWD}/mangosd_data/Cameras:/opt/mangos/data/Cameras:ro \
           -v ${PWD}/mangosd_data/dbc:/opt/mangos/data/dbc:ro \
           -v ${PWD}/mangosd_data/maps:/opt/mangos/data/maps:ro \
           -v ${PWD}/mangosd_data/mmaps:/opt/mangos/data/mmaps:ro \
           -v ${PWD}/mangosd_data/vmaps:/opt/mangos/data/vmaps:ro \
    \
    ${IMAGE}:${VERSION} ${@}
