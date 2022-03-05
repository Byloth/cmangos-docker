#!/usr/bin/env bash
#

set -e

# Utils:
#
function _replace_conf()
{
    local SEARCH_FOR="${1}"
    local REPLACE_WITH="${2}"
    local FILENAME="${3}"

    sed -i "/^${SEARCH_FOR}/c\\${SEARCH_FOR} = ${REPLACE_WITH}" "${FILENAME}"
}
function _merge_confs()
{
    local FILENAME="${1}"
    local CONFIG_FILE="${2}"

    while IFS='' read -r LINE || [[ -n "${LINE}" ]]
    do
        PROPERTY="$(echo "${LINE}" | cut -d '#' -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        if [[ -n "${PROPERTY}" ]]
        then
            local SEARCH_FOR="$(echo "${PROPERTY}" | cut -d '=' -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            local REPLACE_WITH="$(echo "${PROPERTY}" | cut -d '=' -f 2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

            _replace_conf "${SEARCH_FOR}" "${REPLACE_WITH}" "${FILENAME}"
        fi

    done < "${CONFIG_FILE}"
}

# Sub-functions:
#
function compose_mangosd_conf()
{
    local MANGOS_DBCONN="${MANGOS_DBHOST};${MANGOS_DBPORT};${MANGOS_DBUSER};${MANGOS_DBPASS}"

    cd /opt/mangos/etc
    cp mangosd.conf.dist mangosd.conf

    _replace_conf "LoginDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_REALMD_DBNAME}\"" mangosd.conf
    _replace_conf "WorldDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_WORLD_DBNAME}\"" mangosd.conf
    _replace_conf "CharacterDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_CHARACTERS_DBNAME}\"" mangosd.conf
    _replace_conf "LogsDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_LOGS_DBNAME}\"" mangosd.conf

    if [[ -f "/opt/mangos/conf/mangosd.conf" ]]
    then
        _merge_confs mangosd.conf "/opt/mangos/conf/mangosd.conf"
    fi
}
function compose_realmd_conf()
{
    local MANGOS_DBCONN="${MANGOS_DBHOST};${MANGOS_DBPORT};${MANGOS_DBUSER};${MANGOS_DBPASS}"

    cd /opt/mangos/etc
    cp realmd.conf.dist realmd.conf

    _replace_conf "LoginDatabaseInfo" "\"${MANGOS_DBCONN};${MANGOS_REALMD_DBNAME}\"" realmd.conf

    if [[ -f "/opt/mangos/conf/realmd.conf" ]]
    then
        _merge_confs realmd.conf "/opt/mangos/conf/realmd.conf"
    fi
}

function set_timezone()
{
    ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    echo "${TIMEZONE}" > /etc/timezone

    dpkg-reconfigure --frontend noninteractive tzdata &> /dev/null
}

function wait_for_database()
{
    wait-for-it -h "${MANGOS_DBHOST}" -p "${MANGOS_DBPORT}"
}

# Main functions:
#
function init_runner()
{
    set_timezone

    compose_mangosd_conf
    compose_realmd_conf
}

function run_mangosd()
{
    cd /opt/mangos/bin

    gosu mangos ./mangosd
}
function run_realmd()
{
    cd /opt/mangos/bin

    gosu mangos ./realmd
}

# Execution:
#
init_runner

case "${1}" in
    mangosd)
        shift

        wait_for_database
        run_mangosd ${@}
        ;;
    realmd)
        shift

        wait_for_database
        run_realmd ${@}
        ;;
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac

exit 1
