#!/usr/bin/env bash
#

set -e

# Other functions:
#
function extract_resources_from_client()
{
    cd /home/mangos/mangos/bin/tools
}

function init_db()
{
    cd /home/mangos/mangos/sql

    mysql -h${MANGOS_DBHOST} -u${MANGOS_DBUSER} -p${MANGOS_DBPASS} < create/db_create_mysql.sql
    mysql -h${MANGOS_DBHOST} -u${MANGOS_DBUSER} -p${MANGOS_DBPASS} tbcmangos < base/mangos.sql

    for sql_file in $(ls base/dbc/original_data/*.sql)
    do
        mysql -h${MANGOS_DBHOST} -u${MANGOS_DBUSER} -p${MANGOS_DBPASS} tbcmangos < $sql_file
    done

    mysql -h${MANGOS_DBHOST} -u${MANGOS_DBUSER} -p${MANGOS_DBPASS} tbccharacters < base/characters.sql
    mysql -h${MANGOS_DBHOST} -u${MANGOS_DBUSER} -p${MANGOS_DBPASS} tbcrealmd < base/realmd.sql
}
function install_full_db()
{
    cd /home/mangos/tbc-db

    #
    # TODO: Create configuration file.
    #

    ./InstallFullDB.sh
}


# Main functions:
#

# Execution:
#
echo ""

case "${1}" in
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac

exit 1
