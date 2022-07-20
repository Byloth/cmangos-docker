#!/usr/bin/env bash
#

set -e

echo ""

readonly IMAGE="cmangos/runner"
readonly VERSION="tbc"

readonly COMMIT_SHA="$(git log -1 --format="%H")"
readonly TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
readonly VERSION_CODE="1.0.0-develop+$(date -u +"%Y%m%d%H%M%S")"

echo "  Now building a brand-new image...  "
echo " ----------------------------------- "
echo ""

docker build --tag "${IMAGE}:${VERSION}" \
             \
             ${@} \
             \
             --build-arg TIMEZONE="Europe/Rome" \
             --build-arg EXPANSION="${VERSION}" \
             --build-arg COMMIT_SHA="${COMMIT_SHA}" \
             --build-arg CREATE_DATE="${TIMESTAMP}" \
             --build-arg VERSION="${VERSION_CODE}" \
    \
    . # There's a `dot` on this line!
