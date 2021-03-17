#!/usr/bin/env bash
#

set -e

# Other functions:
#
function init_db()
{
    cd /opt/mangos/sql

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
function mangos_init()
{
    cd /opt/mangos/etc

    cp mangosd.conf.dist mangosd.conf
    cp realmd.conf.dist realmd.conf
}
function mangos_run()
{
    cd /opt/mangos/bin

    echo "Not implemented yet. Please, come back later."
    exit 1
}

# Execution:
#
echo ""

mangos_init

case "${1}" in
    -- | mangos)
        shift

        mangos_run ${@}
        ;;
    -*)
        mangos_run ${@}
        ;;
    *)
        cd /home/mangos

        exec ${@}
        ;;
esac

exit 1
