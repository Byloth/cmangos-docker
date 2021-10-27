#!/usr/bin/env bash
#

set -e

readonly NAME="mangos-runner"
readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

BASE_DIR="$(realpath "${PWD}/..")"

docker run --rm -it \
           --name=${NAME} \
           --network=exposed \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="mangos" \
           -e MANGOS_DBPASS="mangos00" \
           -p 3443:3443 \
           -p 3724:3724 \
           -p 7878:7878 \
           -p 8085:8085 \
           -p 8086:8086 \
           -v ${PWD}/config:/opt/mangos/conf:ro \
           -v ${BASE_DIR}/mangosd_data/Cameras:/opt/mangos/data/Cameras:ro \
           -v ${BASE_DIR}/mangosd_data/dbc:/opt/mangos/data/dbc:ro \
           -v ${BASE_DIR}/mangosd_data/maps:/opt/mangos/data/maps:ro \
           -v ${BASE_DIR}/mangosd_data/mmaps:/opt/mangos/data/mmaps:ro \
           -v ${BASE_DIR}/mangosd_data/vmaps:/opt/mangos/data/vmaps:ro \
    \
    ${IMAGE}:${VERSION} ${@}
