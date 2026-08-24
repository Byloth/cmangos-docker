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

exec docker compose run --rm ${TTY} builder "${@}"
