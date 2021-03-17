#!/usr/bin/env bash
#

readonly NAME="mangos-runner"
readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

BASE_DIR="$(realpath "${PWD}/..")"

docker run --rm -it \
           --name=${NAME} \
           --network=database \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="root" \
           -e MANGOS_DBPASS="root00" \
           -p 3443:3443 \
           -p 3724:3724 \
           -p 7878:7878 \
           -p 8085:8085 \
           -p 8086:8086 \
           -v ${BASE_DIR}/Cameras:/opt/mangos/Cameras:ro \
           -v ${BASE_DIR}/dbc:/opt/mangos/dbc:ro \
           -v ${BASE_DIR}/maps:/opt/mangos/maps:ro \
           -v ${BASE_DIR}/mmaps:/opt/mangos/mmaps:ro \
           -v ${BASE_DIR}/vmaps:/opt/mangos/vmaps:ro \
    \
    ${IMAGE}:${VERSION} ${@}
