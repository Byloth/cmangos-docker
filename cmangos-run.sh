#!/usr/bin/env bash
#

set -e

readonly PROJECT="cmangos"
readonly SERVICE="mangosd"

docker compose -p "${PROJECT}" up --detach
exec docker attach "${PROJECT}-${SERVICE}-1"
