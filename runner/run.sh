#!/usr/bin/env bash
#

set -e

readonly BASE_DIR="$(realpath "$(dirname "${0}")/..")"
source "${BASE_DIR}/.env"

readonly NAME="cmangos-runner"
# readonly IMAGE="ghcr.io/byloth/cmangos/${WOW_VERSION}"
# readonly VERSION="latest"
readonly IMAGE="byloth/cmangos-${WOW_VERSION}"
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
           -e MANGOS_DBHOST="mariadb" \
           -e MANGOS_DBUSER="${MANGOS_DBUSER}" \
           -e MANGOS_DBPASS="${MANGOS_DBPASS}" \
           -p 3443:3443 \
           -p 3724:3724 \
           -p 7878:7878 \
           -p 8085:8085 \
           -p 8086:8086 \
           -v "${PWD}/config":/opt/mangos/conf:ro \
           -v "${DATA_VOLUME}":/var/lib/mangos:ro \
    \
    "${IMAGE}:${VERSION}" ${@}
