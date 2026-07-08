#!/usr/bin/env bash
#

set -e

readonly BASE_DIR="$(realpath "$(dirname "${0}")/..")"
source "${BASE_DIR}/.env"

readonly NAME="cmangos-builder"
# readonly IMAGE="ghcr.io/byloth/cmangos/${WOW_VERSION}/builder"
# readonly VERSION="latest"
readonly IMAGE="byloth/cmangos-${WOW_VERSION}/builder"
readonly VERSION="develop"

readonly DATA_VOLUME="cmangos_mangosd_data"
readonly NETWORK="cmangos_default"

if [[ -t 0 ]] && [[ -t 1 ]]
then
    readonly TTY="-it"
else
    readonly TTY="-i"
fi

docker run ${TTY} \
           --name "${NAME}" \
           --network "${NETWORK}" \
           --rm \
           -e MYSQL_SUPERUSER="root" \
           -e MYSQL_SUPERPASS="${MYSQL_SUPERPASS}" \
           -e MANGOS_DBHOST="mariadb" \
           -e MANGOS_DBUSER="${MANGOS_DBUSER}" \
           -e MANGOS_DBPASS="${MANGOS_DBPASS}" \
           -v "${DATA_VOLUME}":/home/mangos/data \
           -v "${WOW_CLIENT_DIR}":/home/mangos/wow-client \
    \
    "${IMAGE}:${VERSION}" ${@}
