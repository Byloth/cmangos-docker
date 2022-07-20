#!/usr/bin/env bash
#

set -e

echo ""

readonly IMAGE="cmangos/builder"
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
             --build-arg MANGOS_SHA1="b337c14a55502203d5571fd4debf0d888809dd25" \
             --build-arg DATABASE_SHA1="db459949c86afd9dea5a31f316986d5d77a9a7c1" \
             --build-arg THREADS="8" \
             --build-arg COMMIT_SHA="${COMMIT_SHA}" \
             --build-arg CREATE_DATE="${TIMESTAMP}" \
             --build-arg VERSION="${VERSION_CODE}" \
    \
    . # There's a `dot` on this line!
