#!/usr/bin/env bash
#

set -e

readonly BASE_DIR="$(realpath "$(dirname "${0}")/..")"

source "${BASE_DIR}/.env"

readonly NAME="mangos-builder"
readonly IMAGE="cmangos/builder"
readonly VERSION="tbc"

readonly DATA_VOLUME="cmangos_mangosd_data"

if [[ -t 0 ]] && [[ -t 1 ]]
then
    readonly TTY="-it"
else
    readonly TTY="-i"
fi

docker run "${TTY}" \
           --name "${NAME}" \
           --rm \
           -e MYSQL_SUPERUSER="root" \
           -e MYSQL_SUPERPASS="root00" \
           -e MANGOS_DBHOST="172.17.0.1" \
           -e MANGOS_DBUSER="mangos" \
           -e MANGOS_DBPASS="mangos00" \
           -v "${DATA_VOLUME}":/home/mangos/data \
           -v "${WOW_CLIENT_DIR}":/home/mangos/wow-client \
    \
    "${IMAGE}:${VERSION}" ${@}
