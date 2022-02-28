#!/usr/bin/env bash
#

set -e

readonly NAME="mangos-runner"
readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

readonly DATA_VOLUME="cmangos_mangosd_data"

docker run -it --rm \
           --name "${NAME}" \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="mangos" \
           -e MANGOS_DBPASS="mangos00" \
           -p 3443:3443 \
           -p 3724:3724 \
           -p 7878:7878 \
           -p 8085:8085 \
           -p 8086:8086 \
           -v "${PWD}/config":/opt/mangos/conf:ro \
           -v "${DATA_VOLUME}":/opt/mangos/data:ro \
    \
    ${IMAGE}:${VERSION} ${@}
