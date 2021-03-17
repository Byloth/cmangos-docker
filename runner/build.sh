#!/usr/bin/env bash
#

set -e

echo ""

readonly IMAGE="cmangos/mangos-runner"
readonly VERSION="tbc"

echo "  Now building a brand-new image...  "
echo " ----------------------------------- "
echo ""

docker build --tag ${IMAGE}:${VERSION} \
    \
    . # There's a `dot` on this line!
