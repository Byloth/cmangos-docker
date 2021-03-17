#!/usr/bin/env bash
#

readonly NAME="mangosd_tbc"
readonly IMAGE="cmangos/mangos-tbc"
readonly VERSION="latest"

docker run --rm -it \
           --name=${NAME} \
           --network=database \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="root" \
           -e MANGOS_DBPASS="root00" \
           -p 3443:3443 \
           -p 7878:7878 \
           -p 8085:8085 \
           -p 8086:8086 \
           -v /home/matteo/downloads/wow-tbc:/home/mangos/wow-tbc \
           -v ${PWD}/Cameras:/opt/mangos/Cameras:ro \
           -v ${PWD}/dbc:/opt/mangos/dbc:ro \
           -v ${PWD}/maps:/opt/mangos/maps:ro \
           -v ${PWD}/mmaps:/opt/mangos/mmaps:ro \
           -v ${PWD}/vmaps:/opt/mangos/vmaps:ro \
    \
    ${IMAGE}:${VERSION} ${@}
