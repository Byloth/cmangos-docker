#!/usr/bin/env bash
#

set -e

# Utils:
#
function success()
{
    echo -e "\e[32m${1}\e[0m"
}
function info()
{
    echo -e "\e[36m${1}\e[0m"
}
function warning()
{
    if [[ "${2}" == "--underline" ]]
    then
        echo -e "\e[4;33m${1}\e[0m"
    else
        echo -e "\e[33m${1}\e[0m"
    fi
}
function error()
{
    if [[ "${2}" == "--underline" ]]
    then
        echo -e "\e[4;31m${1}\e[0m"
    else
        echo -e "\e[31m${1}\e[0m"
    fi
}

function mysql_execute()
{
    mysql -h${MANGOS_DBHOST} -P${MANGOS_DBPORT} -u${MYSQL_SUPERUSER} -p${MYSQL_SUPERPASS} ${@}
}

# Sub-functions:
#
function extract_resources_from_client()
{
    cd /home/mangos/run/bin/tools

    cp * /home/mangos/wow-client/

    cd /home/mangos/wow-client

    ./ExtractResources.sh

    mv Cameras /home/mangos/data/Cameras
    mv dbc /home/mangos/data/dbc
    mv maps /home/mangos/data/maps
    mv mmaps /home/mangos/data/mmaps
    mv vmaps /home/mangos/data/vmaps

    mkdir -p /home/mangos/data/logs

    mv *.log /home/mangos/data/logs/

    rm -rf Buildings/ \
       \
       ExtractResources.sh \
       MoveMapGen \
       MoveMapGen.sh \
       ad \
       offmesh.txt \
       vmap_assembler \
       vmap_extractor
}

function init_db()
{
    cd /home/mangos/mangos/sql

    mysql_execute < create/db_create_mysql.sql
    mysql_execute ${MANGOS_WORLD_DBNAME} < base/mangos.sql
    mysql_execute ${MANGOS_CHARACTERS_DBNAME} < base/characters.sql
    mysql_execute ${MANGOS_LOGS_DBNAME} < base/logs.sql
    mysql_execute ${MANGOS_REALMD_DBNAME} < base/realmd.sql

    load_world_db
}
function load_world_db()
{
    cd /home/mangos/tbc-db

    ./InstallFullDB.sh -InstallAll ${MYSQL_SUPERUSER} ${MYSQL_SUPERPASS} DeleteAll
}

# Main functions:
#
function update_db()
{
    echo ""
    echo -e " $(warning "WARNING!" --underline)"
    echo -e "  $(warning "└") This procedure will prune all customized data you"
    echo -e "     may have loaded into your \"$(info "${MANGOS_WORLD_DBNAME}")\" database."
    echo -e ""
    read -p "Are you sure to continue? [N]: " ANSWER

    if [[ "${ANSWER}" == "y" ]] || [[ "${ANSWER}" == "Y" ]]
    then
        echo -e " └ Please, wait... Updating database..."
        echo -e ""
        echo -e " --------------------------------------"

        load_world_db

        echo -e " $(success "-------")"
        echo -e "  $(success "DONE!")"
        echo -e " $(success "-------")"
    else
        echo -e " └ Ok, no problem! Database have been left untouched."
    fi
}

# Execution:
#

case "${1}" in
    extract)
        shift

        extract_resources_from_client
        ;;
    init-db)
        shift

        init_db
        ;;
    update-db)
        shift

        update_db ${@}
        ;;
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac
