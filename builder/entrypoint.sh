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
    mysql -h${MANGOS_DBHOST} -P${MANGOS_DBPORT} -u${MANGOS_DBUSER} -p${MANGOS_DBPASS} ${@}
}

# Sub-functions:
#
function extract_resources_from_client()
{
    cd /home/mangos/mangos/bin/tools

    #
    # TODO!
    #
}

function init_db()
{
    cd /home/mangos/mangos/sql

    mysql_execute < create/db_create_mysql.sql
    mysql_execute ${MANGOS_MANGOS_DBNAME} < base/mangos.sql
    mysql_execute ${MANGOS_REALMD_DBNAME} < base/realmd.sql
    mysql_execute ${MANGOS_CHARACTERS_DBNAME} < base/characters.sql

    load_mangos_db
}
function load_mangos_db()
{
    cd /home/mangos/tbc-db

    ./InstallFullDB.sh
}

# Main functions:
#
function update_db()
{
    echo -e " $(warning "WARNING!" --underline)"
    echo -e "  $(warning "└") This procedure will prune all customized data you"
    echo -e "     may have loaded into your \"$(info "${MANGOS_MANGOS_DBNAME}")\" database."
    echo -e ""
    read -p "Are you sure to continue? [N]: " ANSWER

    if [[ "${ANSWER}" == "y" ]] || [[ "${ANSWER}" == "Y" ]]
    then
        echo -e " └ Please, wait... Updating database..."
        echo -e ""
        echo -e " --------------------------------------"

        load_mangos_db

        echo -e " $(success "-------")"
        echo -e "  $(success "DONE!")"
        echo -e " $(success "-------")"
    else
        echo -e " └ Ok, no problem! Database have been left untouched."
    fi
}

# Execution:
#
echo ""

case "${1}" in
    update-db)
        shift

        update_db ${@}
        ;;
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac

exit 1
