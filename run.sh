#!/usr/bin/env bash
#

set -e

readonly PROJECT="cmangos"
readonly SERVICE="mangosd"

docker-compose -p "${PROJECT}" up --detach
docker attach "${PROJECT}_${SERVICE}_1"
