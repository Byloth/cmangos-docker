#!/usr/bin/env bash
#

set -e

# Main functions:
#
function init_runner()
{
    cd /opt/mangos/etc

    cp mangosd.conf.dist mangosd.conf
    cp realmd.conf.dist realmd.conf
}

function run_mangosd()
{
    cd /opt/mangos/bin

    echo "Not implemented yet. Please, come back later."
    exit 1
}
function run_realmd()
{
    cd /opt/mangos/bin

    echo "Not implemented yet. Please, come back later."
    exit 1
}

# Execution:
#
echo ""

init_runner

case "${1}" in
    mangosd)
        shift

        run_mangosd ${@}
        ;;
    realmd)
        shift

        run_realmd ${@}
        ;;
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac

exit 1
