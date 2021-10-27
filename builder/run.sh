#!/usr/bin/env bash
#

set -e

readonly NAME="mangos-builder"
readonly IMAGE="cmangos/builder"
readonly VERSION="tbc"

BASE_DIR="$(realpath "${PWD}/..")"

docker run --rm -it \
           --name=${NAME} \
           --network=exposed \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="root" \
           -e MANGOS_DBPASS="root00" \
           -v /home/matteo/downloads/wow-tbc:/home/mangos/tbc-client \
           -v ${BASE_DIR}/mangosd_data/Cameras:/home/mangos/data/Cameras \
           -v ${BASE_DIR}/mangosd_data/dbc:/home/mangos/data/dbc \
           -v ${BASE_DIR}/mangosd_data/maps:/home/mangos/data/maps \
           -v ${BASE_DIR}/mangosd_data/mmaps:/home/mangos/data/mmaps \
           -v ${BASE_DIR}/mangosd_data/vmaps:/home/mangos/data/vmaps \
    \
    ${IMAGE}:${VERSION} ${@}
