FROM ubuntu:20.04

ENV DEBIAN_FRONTEND="noninteractive"

ARG TIMEZONE="UTC"
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

ARG MANGOS_TBC_SHA1="8ebaeb8bae1d4a04229d7f2b04c3f129c1b0a643"
ARG TBC_DB_SHA1="7623ad991bd4275ea35fe315c1552f5d6cc8df71"
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
 && cmake ../mangos/ -DCMAKE_INSTALL_PREFIX=../run -DBUILD_EXTRACTORS=ON \
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

ENV MANGOS_DBHOST="127.0.0.1" \
    MANGOS_DBPORT="3306" \
    MANGOS_DBUSER="root" \
    MANGOS_DBPASS="" \
    \
    MANGOS_REALMD_DBNAME="tbcrealmd" \
    MANGOS_MANGOS_DBNAME="tbcmangos" \
    MANGOS_CHARACTERS_DBNAME="tbccharacters"

COPY entrypoint.sh /
COPY InstallFullDB.config /home/mangos/tbc-db/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
