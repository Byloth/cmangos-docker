FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND="noninteractive"

ARG TIMEZONE="Etc/UTC"
ENV TZ="${TIMEZONE}"
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        tzdata \
 && ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 \
 && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
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

ARG EXPANSION
ARG MANGOS_SHA1
ARG DATABASE_SHA1
ENV HOME_DIR="/home/mangos"
ENV MANGOS_DIR="${HOME_DIR}/mangos"
ENV DATABASE_DIR="${HOME_DIR}/${EXPANSION}-db"
RUN mkdir -p "${MANGOS_DIR}" \
             "${DATABASE_DIR}" \
 \
 && cd /tmp \
 && git clone "https://github.com/cmangos/mangos-${EXPANSION}.git" \
            --branch "master" \
            --single-branch \
        cmangos-mangos \
 && cd cmangos-mangos \
 && git archive "${MANGOS_SHA1}" | tar xC "${MANGOS_DIR}" \
 \
 && cd /tmp \
 && git clone "https://github.com/cmangos/${EXPANSION}-db.git" \
            --branch "master" \
            --single-branch \
        cmangos-db \
 && cd cmangos-db \
 && git archive "${DATABASE_SHA1}" | tar xC "${DATABASE_DIR}" \
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
RUN mkdir -p "${HOME_DIR}/build" \
             "${HOME_DIR}/run" \
 \
 && cd "${HOME_DIR}/build" \
 && cmake ../mangos/ \
        -D CMAKE_INSTALL_PREFIX=../run \
        -D PCH=1 \
        -D DEBUG=0 \
        -D BUILD_EXTRACTORS=ON \
 && make -j "${THREADS}" \
 && make install \
 \
 && cd "${HOME_DIR}/run/bin/tools" \
 && chmod +x ExtractResources.sh \
             MoveMapGen.sh

RUN useradd --comment "MaNGOS" \
            --home "${HOME_DIR}" \
            --user-group mangos

WORKDIR "${HOME_DIR}"

ENV MYSQL_SUPERUSER="root"
ENV MYSQL_SUPERPASS=""

ENV MANGOS_DBHOST="host.docker.internal"
ENV MANGOS_DBPORT="3306"
ENV MANGOS_DBUSER="mangos"
ENV MANGOS_DBPASS=""

ENV MANGOS_WORLD_DBNAME="${EXPANSION}mangos"
ENV MANGOS_CHARACTERS_DBNAME="${EXPANSION}characters"
ENV MANGOS_LOGS_DBNAME="${EXPANSION}logs"
ENV MANGOS_REALMD_DBNAME="${EXPANSION}realmd"

COPY builder/entrypoint.sh /
COPY builder/InstallFullDB.config "${DATABASE_DIR}/"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

ENV VOLUME_DIR="/home/mangos/data"
ENV TMPDIR="${VOLUME_DIR}/tmp"
VOLUME ["${VOLUME_DIR}"]

ARG COMMIT_SHA
ARG CREATE_DATE
ARG VERSION
LABEL org.opencontainers.image.title="CMaNGOS \"${EXPANSION}\" version"
LABEL org.opencontainers.image.description="A CMaNGOS \"${EXPANSION}\" version Docker image ready-to-use to host your emulated private server for WoW wherever you want."
LABEL org.opencontainers.image.licenses="GPL-2.0"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"
LABEL org.opencontainers.image.source="https://github.com/Byloth/cmangos-docker"
LABEL org.opencontainers.image.url="https://github.com/Byloth/cmangos-docker"
LABEL org.opencontainers.image.authors="Matteo Bilotta <me@byloth.net>"
LABEL org.opencontainers.image.vendor="Bylothink"
LABEL org.opencontainers.image.created="${CREATE_DATE}"

LABEL "net.cmangos.mangos-${EXPANSION}.revision"="${MANGOS_SHA1}"
LABEL "net.cmangos.mangos-${EXPANSION}.source"="https://github.com/cmangos/mangos-${EXPANSION}"
LABEL "net.cmangos.mangos-${EXPANSION}.url"="https://github.com/cmangos/mangos-${EXPANSION}"

LABEL "net.cmangos.${EXPANSION}-db.revision"="${DB_SHA1}"
LABEL "net.cmangos.${EXPANSION}-db.source"="https://github.com/cmangos/${EXPANSION}-db"
LABEL "net.cmangos.${EXPANSION}-db.url"="https://github.com/cmangos/${EXPANSION}-db"

FROM ubuntu:20.04 AS runner

ENV DEBIAN_FRONTEND="noninteractive"

ARG TIMEZONE="Etc/UTC"
ENV TZ="${TIMEZONE}"
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        tzdata \
 && ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 \
 && apt-get install -y --no-install-recommends \
        gosu \
        libmariadb-dev \
        libssl1.1 \
        wait-for-it \
 \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

ENV HOME_DIR="/home/mangos"
ENV MANGOS_DIR="/opt/mangos"
RUN useradd --home "${HOME_DIR}" --create-home \
            --comment "MaNGOS" \
            --user-group mangos

WORKDIR "${MANGOS_DIR}"

ARG EXPANSION
COPY --from=builder "${HOME_DIR}/run" "${MANGOS_DIR}"
COPY runner/entrypoint.sh /

ENV VOLUME_DIR="/var/lib/mangos"
ENV TMPDIR="${VOLUME_DIR}/tmp"
RUN mkdir "${VOLUME_DIR}" \
 && sed -i '/^DataDir/c\DataDir = "'"${VOLUME_DIR}"'"' etc/mangosd.conf.dist

ENV MANGOS_DBHOST="host.docker.internal"
ENV MANGOS_DBPORT="3306"
ENV MANGOS_DBUSER="mangos"
ENV MANGOS_DBPASS=""

ENV MANGOS_WORLD_DBNAME="${EXPANSION}mangos"
ENV MANGOS_CHARACTERS_DBNAME="${EXPANSION}characters"
ENV MANGOS_LOGS_DBNAME="${EXPANSION}logs"
ENV MANGOS_REALMD_DBNAME="${EXPANSION}realmd"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

EXPOSE 3443 3724 7878 8085 8086
VOLUME ["${VOLUME_DIR}"]

ARG COMMIT_SHA
ARG CREATE_DATE
ARG VERSION
LABEL org.opencontainers.image.title="CMaNGOS Runner \"${EXPANSION}\" version"
LABEL org.opencontainers.image.description="A CMaNGOS \"${EXPANSION}\" version Docker image ready-to-use to host your emulated private server for WoW wherever you want."
LABEL org.opencontainers.image.licenses="GPL-2.0"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"
LABEL org.opencontainers.image.source="https://github.com/Byloth/cmangos-docker"
LABEL org.opencontainers.image.url="https://github.com/Byloth/cmangos-docker"
LABEL org.opencontainers.image.authors="Matteo Bilotta <me@byloth.net>"
LABEL org.opencontainers.image.vendor="Bylothink"
LABEL org.opencontainers.image.created="${CREATE_DATE}"

ARG MANGOS_SHA1
LABEL "net.cmangos.mangos-${EXPANSION}.revision"="${MANGOS_SHA1}"
LABEL "net.cmangos.mangos-${EXPANSION}.source"="https://github.com/cmangos/mangos-${EXPANSION}"
LABEL "net.cmangos.mangos-${EXPANSION}.url"="https://github.com/cmangos/mangos-${EXPANSION}"

ARG DATABASE_SHA1
LABEL "net.cmangos.${EXPANSION}-db.revision"="${DB_SHA1}"
LABEL "net.cmangos.${EXPANSION}-db.source"="https://github.com/cmangos/${EXPANSION}-db"
LABEL "net.cmangos.${EXPANSION}-db.url"="https://github.com/cmangos/${EXPANSION}-db"
