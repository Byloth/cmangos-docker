FROM ubuntu:20.04

ENV DEBIAN_FRONTEND="noninteractive"

ARG TIMEZONE="Etc/UTC"
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        tzdata \
 && ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 \
 && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git-core \
        libboost-filesystem-dev \
        libboost-program-options-dev \
        libboost-regex-dev \
        libboost-serialization-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libmariadb-dev-compat \
        libssl-dev \
        mariadb-client \
 \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

ARG MANGOS_TBC_SHA1="87d6304b22bbc0b1cc70db987a1773f57e2a86c6"
ARG TBC_DB_SHA1="b5ba1ceb3a54cfae14efe4b51728ee5adb7adcac"
RUN mkdir -p /home/mangos/mangos \
             /home/mangos/tbc-db \
 \
 && cd /tmp \
 && git clone "git://github.com/cmangos/mangos-tbc.git" \
        --branch "master" \
        --single-branch \
 && cd mangos-tbc/ \
 && git archive "${MANGOS_TBC_SHA1}" | tar xC /home/mangos/mangos \
 \
 && cd /tmp \
 && git clone "git://github.com/cmangos/tbc-db.git" \
        --branch "master" \
        --single-branch \
 && cd tbc-db/ \
 && git archive "${TBC_DB_SHA1}" | tar xC /home/mangos/tbc-db \
 \
 && rm -rf /tmp/*

# TODO: Add here as building arguments all `cmake` parameters.
#   - CMAKE_INSTALL_PREFIX    Path where the server should be installed to
#   - PCH                     Use precompiled headers
#   - DEBUG                   Include additional debug-code in core
#   - WARNINGS                Show all warnings during compile
#   - POSTGRESQL              Use PostgreSQL instead of mysql
#   - BUILD_EXTRACTORS        Build map/dbc/vmap/mmap extractor
#   - BUILD_SCRIPTDEV         Build scriptdev. (Disable it to speedup build in dev mode by not including scripts)
#   - BUILD_PLAYERBOT         Build Playerbot mod
#   - BUILD_AHBOT             Build Auction House Bot mod
#   - BUILD_METRICS           Build Metrics, generate data for Grafana
#   - BUILD_RECASTDEMOMOD     Build map/vmap/mmap viewer
#   - BUILD_GIT_ID            Build git_id
#   - BUILD_DOCS              Build documentation with doxygen
#
ARG THREADS="1"
RUN mkdir -p /home/mangos/build \
             /home/mangos/run \
 \
 && cd /home/mangos/build \
 && cmake ../mangos/ \
        -DCMAKE_INSTALL_PREFIX=../run \
        -DPCH=1 \
        -DDEBUG=0 \
        -DBUILD_EXTRACTORS=ON \
 && make "-j${THREADS}" \
 && make install \
 \
 && cd /home/mangos/run/bin/tools \
 && chmod +x ExtractResources.sh \
             MoveMapGen.sh

RUN useradd --comment "MaNGOS" \
            --home /home/mangos \
            --user-group mangos

WORKDIR /home/mangos

ENV MYSQL_SUPERUSER="root" \
    MYSQL_SUPERPASS="" \
    \
    MANGOS_DBHOST="127.0.0.1" \
    MANGOS_DBPORT="3306" \
    MANGOS_DBUSER="mangos" \
    MANGOS_DBPASS="" \
    \
    MANGOS_WORLD_DBNAME="tbcmangos" \
    MANGOS_CHARACTERS_DBNAME="tbccharacters" \
    MANGOS_LOGS_DBNAME="tbclogs" \
    MANGOS_REALMD_DBNAME="tbcrealmd"

COPY entrypoint.sh /
COPY InstallFullDB.config /home/mangos/tbc-db/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
