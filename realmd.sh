#!/usr/bin/env bash
#

readonly NAME="realmd-tbc"
readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

docker run --rm -it \
           --name=${NAME} \
           --network=exposed \
           -e CMANGOS_DBHOST="172.17.0.1" \
           -e CMANGOS_DBUSER="mangos" \
           -e CMANGOS_DBPASS="mangos00" \
           -p 3724:3724 \
    \
    ${IMAGE}:${VERSION} ${@}
