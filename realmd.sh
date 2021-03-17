#!/usr/bin/env bash
#

readonly NAME="realmd-tbc"
readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

docker run --rm -it \
           --name=${NAME} \
           --network=database \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="root" \
           -e MANGOS_DBPASS="root00" \
           -p 3724:3724 \
           -v ${PWD}/Cameras:/opt/mangos/Cameras:ro \
           -v ${PWD}/dbc:/opt/mangos/dbc:ro \
           -v ${PWD}/maps:/opt/mangos/maps:ro \
           -v ${PWD}/mmaps:/opt/mangos/mmaps:ro \
           -v ${PWD}/vmaps:/opt/mangos/vmaps:ro \
    \
    ${IMAGE}:${VERSION} ${@}
