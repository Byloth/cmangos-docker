#!/usr/bin/env bash
#

set -e

# Sub-functions:
#
function set_defaults()
{
    if [[ -z "${CMANGOS_DBHOST}" ]]
    then
        export CMANGOS_DBHOST="127.0.0.1"
    fi
    if [[ -z "${CMANGOS_DBPORT}" ]]
    then
        export CMANGOS_DBPORT="3306"
    fi
    if [[ -z "${CMANGOS_DBUSER}" ]]
    then
        export CMANGOS_DBUSER="mangos"
    fi
    if [[ -z "${CMANGOS_DBPASS}" ]]
    then
        export CMANGOS_DBPASS="mangos"
    fi

    if [[ -z "${CMANGOS_REALMD_DBNAME}" ]]
    then
        export CMANGOS_REALMD_DBNAME="tbcrealmd"
    fi
    if [[ -z "${CMANGOS_MANGOS_DBNAME}" ]]
    then
        export CMANGOS_MANGOS_DBNAME="tbcmangos"
    fi
    if [[ -z "${CMANGOS_CHARACTERS_DBNAME}" ]]
    then
        export CMANGOS_CHARACTERS_DBNAME="tbccharacters"
    fi

    if [[ -z "${CMANGOS_REALM_ID}" ]]
    then
        export CMANGOS_REALM_ID="1"
    fi
    if [[ -z "${CMANGOS_WORLD_SERVER_PORT}" ]]
    then
        export CMANGOS_WORLD_SERVER_PORT="8085"
    fi
    if [[ -z "${CMANGOS_GAME_TYPE}" ]]
    then
        export CMANGOS_GAME_TYPE="1"
    fi
    if [[ -z "${CMANGOS_REALM_ZONE}" ]]
    then
        export CMANGOS_REALM_ZONE="1"
    fi
    if [[ -z "${CMANGOS_RABBIT_DAY}" ]]
    then
        export CMANGOS_RABBIT_DAY="0"
    fi
    if [[ -z "${CMANGOS_MOTD}" ]]
    then
        export CMANGOS_MOTD="Welcome to the Continued Massive Network Game Object Server."
    fi
}

function compose_mangosd_conf()
{
    local CMANGOS_DBCONN="${CMANGOS_DBHOST};${CMANGOS_DBPORT};${CMANGOS_DBUSER};${CMANGOS_DBPASS}"

    cd /opt/mangos/etc

    sed -e '/DataDir/s/"."/"\/opt\/mangos\/data"/g' mangosd.conf.dist > mangosd.conf.tmp

    sed -e "/LoginDatabaseInfo/s/127.0.0.1;3306;mangos;mangos;tbcrealmd/${CMANGOS_DBCONN};${CMANGOS_REALMD_DBNAME}/g" mangosd.conf.tmp > mangosd.conf
    sed -e "/WorldDatabaseInfo/s/127.0.0.1;3306;mangos;mangos;tbcmangos/${CMANGOS_DBCONN};${CMANGOS_MANGOS_DBNAME}/g" mangosd.conf > mangosd.conf.tmp
    sed -e "/CharacterDatabaseInfo/s/127.0.0.1;3306;mangos;mangos;tbccharacters/${CMANGOS_DBCONN};${CMANGOS_CHARACTERS_DBNAME}/g" mangosd.conf.tmp > mangosd.conf

    sed -e "/RealmID/s/1/${CMANGOS_REALM_ID}/g" mangosd.conf > mangosd.conf.tmp
    sed -e "/WorldServerPort/s/8085/${CMANGOS_WORLD_SERVER_PORT}/g" mangosd.conf.tmp > mangosd.conf
    sed -e "/GameType/s/1/${CMANGOS_GAME_TYPE}/g" mangosd.conf > mangosd.conf.tmp
    sed -e "/RealmZone/s/1/${CMANGOS_REALM_ZONE}/g" mangosd.conf.tmp > mangosd.conf
    sed -e "/RabbitDay/s/0/${CMANGOS_RABBIT_DAY}/g" mangosd.conf > mangosd.conf.tmp
    sed -e "/Motd/s/Welcome to the Continued Massive Network Game Object Server./${CMANGOS_MOTD}/g" mangosd.conf.tmp > mangosd.conf
}
function compose_realmd_conf()
{
    local CMANGOS_DBCONN="${CMANGOS_DBHOST};${CMANGOS_DBPORT};${CMANGOS_DBUSER};${CMANGOS_DBPASS}"

    cd /opt/mangos/etc

    sed -e "/LoginDatabaseInfo/s/127.0.0.1;3306;mangos;mangos;tbcrealmd/${CMANGOS_DBCONN};${CMANGOS_REALMD_DBNAME}/g" realmd.conf.dist > realmd.conf
}


# Main functions:
#
function init_runner()
{
    set_defaults

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
