#!/usr/bin/env bash
#

readonly NAME="mangos-builder"
readonly IMAGE="cmangos/builder"
readonly VERSION="tbc"

BASE_DIR="$(realpath "${PWD}/..")"

docker run --rm -it \
           --name=${NAME} \
           --network=database \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="root" \
           -e MANGOS_DBPASS="root00" \
           -v /home/matteo/downloads/wow-tbc:/home/mangos/tbc-client \
           -v ${BASE_DIR}/Cameras:/home/mangos/run/Cameras \
           -v ${BASE_DIR}/dbc:/home/mangos/run/dbc \
           -v ${BASE_DIR}/maps:/home/mangos/run/maps \
           -v ${BASE_DIR}/mmaps:/home/mangos/run/mmaps \
           -v ${BASE_DIR}/vmaps:/home/mangos/run/vmaps \
    \
    ${IMAGE}:${VERSION} ${@}
