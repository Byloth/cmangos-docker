#!/usr/bin/env bash
#

set -e

echo ""

readonly IMAGE="cmangos/mangos-tbc"
readonly VERSION="latest"

echo "  Now building a brand-new image...  "
echo " ----------------------------------- "
echo ""

docker build --tag ${IMAGE}:${VERSION} \
             --pull \
             --build-arg TIMEZONE="Europe/Rome" \
             --build-arg THREADS="8" \
    \
    . # There's a `dot` on this line!
