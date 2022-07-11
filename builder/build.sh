#!/usr/bin/env bash
#

set -e

echo ""

readonly IMAGE="cmangos/builder"
readonly VERSION="tbc"

echo "  Now building a brand-new image...  "
echo " ----------------------------------- "
echo ""

docker build --tag "${IMAGE}:${VERSION}" \
             \
             ${@} \
             \
             --build-arg TIMEZONE="Europe/Rome" \
             --build-arg THREADS="8" \
    \
    . # There's a `dot` on this line!
