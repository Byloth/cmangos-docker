#!/usr/bin/env bash
#

set -e

# Utils:
#
function echoerr()
{
    echo "${@}" >&2
}

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
    mysql "-h${MANGOS_DBHOST}" "-P${MANGOS_DBPORT}" "-u${MYSQL_SUPERUSER}" "-p${MYSQL_SUPERPASS}" ${@}
}
function mysql_dump()
{
    local DATABASE_NAME="${1}"
    local OUTPUT_FILE="${2}"

    mysqldump "-h${MANGOS_DBHOST}" "-P${MANGOS_DBPORT}" "-u${MYSQL_SUPERUSER}" "-p${MYSQL_SUPERPASS}" \
        "${DATABASE_NAME}" --opt --result-file="${OUTPUT_FILE}"
}

# Sub-functions:
#
function init_world_db()
{
    cd /home/mangos/tbc-db

    ./InstallFullDB.sh -InstallAll "${MYSQL_SUPERUSER}" "${MYSQL_SUPERPASS}" DeleteAll
}
function update_world_db()
{
    cd /home/mangos/tbc-db

    ./InstallFullDB.sh -World
}

# Main functions:
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
    mysql_execute "${MANGOS_WORLD_DBNAME}" < base/mangos.sql
    mysql_execute "${MANGOS_CHARACTERS_DBNAME}" < base/characters.sql
    mysql_execute "${MANGOS_LOGS_DBNAME}" < base/logs.sql
    mysql_execute "${MANGOS_REALMD_DBNAME}" < base/realmd.sql

    init_world_db
}
function backup_db()
{
    readonly HELP_MSG="
Backups the specified database(s) and then returns the
 result as a single \"tar.gz\" file via standard output.

Usage:
    backup-db [OPTIONS...]

Options:
    -a | --all
        Backups all databases.

    -w | --world
        Backups the world database: \"$(info "${MANGOS_WORLD_DBNAME}")\".

    -c | --characters
        Backups the characters database: \"$(info "${MANGOS_CHARACTERS_DBNAME}")\".

    -l | --logs
        Backups the logs database: \"$(info "${MANGOS_LOGS_DBNAME}")\".

    -r | --realmd
        Backups the realmd database: \"$(info "${MANGOS_REALMD_DBNAME}")\".
    
    -h | -? | --help
        Displays this help message.
"

    declare -A DATABASES

    while [[ ${#} -gt 0 ]]
    do
        case "${1}" in
            -a | --all)
                readonly BACKUPS_ALL="true"
                ;;
            -w | --world)
                DATABASES+=(["world"]="${MANGOS_WORLD_DBNAME}")
                ;;
            -c | --characters)
                DATABASES+=(["characters"]="${MANGOS_CHARACTERS_DBNAME}")
                ;;
            -l | --logs)
                DATABASES+=(["logs"]="${MANGOS_LOGS_DBNAME}")
                ;;
            -r | --realmd)
                DATABASES+=(["realmd"]="${MANGOS_REALMD_DBNAME}")
                ;;
            -h | -? | --help)
                echo -e "${HELP_MSG}"

                exit 0
                ;;
            *)
                echoerr ""
                echoerr -e " $(error "ERROR!" --underline)"
                echoerr -e "  $(error "└") Unknown option: \"$(info "${1}")\""
                echoerr ""
                echoerr " Run \"$(info "backup-db --help")\" for more information."

                exit 1
                ;;
        esac

        shift
    done

    if [[ "${BACKUPS_ALL}" == "true" ]]
    then
        if [[ -n ${DATABASES[@]} ]]
        then
            echoerr ""
            echoerr -e " $(error "ERROR!" --underline)"
            echoerr -e "  $(error "└") You cannot specify both \"$(info "--all")\" and any other"
            echoerr -e "     specific database options at the same time."
            echoerr ""
            echoerr " Run \"$(info "backup-db --help")\" for more information."

            exit 2
        fi

        DATABASES=(["world"]="${MANGOS_WORLD_DBNAME}" \
                   ["characters"]="${MANGOS_CHARACTERS_DBNAME}" \
                   ["logs"]="${MANGOS_LOGS_DBNAME}" \
                   ["realmd"]="${MANGOS_REALMD_DBNAME}")
    fi
    if [[ -z ${DATABASES[@]} ]]
    then
        echoerr ""
        echoerr -e " $(error "ERROR!" --underline)"
        echoerr -e "  $(error "└") You must specify at least one database to backup."
        echoerr ""
        echoerr " Run \"$(info "backup-db --help")\" for more information."

        exit 3
    fi

    local TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
    local BACKUP_DIRECTORY="/home/mangos/data/backups/${TIMESTAMP}"
    local BACKUP_FILE="${BACKUP_DIRECTORY}/backup_${TIMESTAMP}.tar.gz"

    mkdir -p "${BACKUP_DIRECTORY}"

    for DATABASE in ${!DATABASES[@]}
    do
        local DATABASE_NAME="${DATABASES["${DATABASE}"]}"
        local OUTPUT_FILENAME="${DATABASE}.sql"

        mysql_dump "${DATABASE_NAME}" "${BACKUP_DIRECTORY}/${OUTPUT_FILENAME}"
    done

    cd "${BACKUP_DIRECTORY}"
    tar -czvf "${BACKUP_FILE}" $(ls *.sql | xargs -n 1) > /dev/null

    cat "${BACKUP_FILE}"
}
function manage_db()
{
    cd /home/mangos/tbc-db

    ./InstallFullDB.sh
}
function restore_db()
{
    local TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
    local TEMP_DIRECTORY="/home/mangos/data/tmp/${TIMESTAMP}"
    local BACKUP_FILE="${TEMP_DIRECTORY}/backup_${TIMESTAMP}.tar.gz"

    mkdir -p "${TEMP_DIRECTORY}"
    cat - > "${BACKUP_FILE}"

    cd "${TEMP_DIRECTORY}"

    tar -xzvf "${BACKUP_FILE}" -C . > /dev/null

    local BACKUP_FILES=($(ls *.sql | xargs -n 1))

    for BACKUP_FILE in ${BACKUP_FILES[@]}
    do
        local DATABASE="${BACKUP_FILE%.sql}"

        if [[ "${DATABASE}" == "world" ]]
        then
            local DATABASE_NAME="${MANGOS_WORLD_DBNAME}"
        elif [[ "${DATABASE}" == "characters" ]]
        then
            local DATABASE_NAME="${MANGOS_CHARACTERS_DBNAME}"
        elif [[ "${DATABASE}" == "logs" ]]
        then
            local DATABASE_NAME="${MANGOS_LOGS_DBNAME}"
        elif [[ "${DATABASE}" == "realmd" ]]
        then
            local DATABASE_NAME="${MANGOS_REALMD_DBNAME}"
        fi

        mysql_execute "${DATABASE_NAME}" < "${TEMP_DIRECTORY}/${BACKUP_FILE}"
    done
}
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

        update_world_db
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
    backup-db)
        shift

        backup_db ${@}
        ;;
    restore-db)
        shift

        restore_db ${@}
        ;;
    manage-db)
        shift

        manage_db
        ;;
    update-db)
        shift

        update_db
        ;;
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac
