#!/usr/bin/env bash
#

set -e

readonly BASE_DIR="$(realpath "$(dirname "${0}")/..")"

if [[ -t 0 ]] && [[ -t 1 ]]
then
    readonly TTY=""
else
    readonly TTY="-T"
fi

cd "${BASE_DIR}"

case "${1:-mangosd}" in
    mangosd | realmd)
        exec docker compose run --rm ${TTY} --service-ports "${1}"
        ;;
    *)
        exec docker compose run --rm ${TTY} mangosd "${@}"
        ;;
esac
