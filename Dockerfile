FROM ubuntu:20.04 AS builder

ARG TIMEZONE="UTC"
RUN ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone \
 \
 && apt-get update \
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
 \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

ARG MANGOS_TBC_SHA1="168d2ff3437b395b2b52a45c3824d06d8c588af2"
ARG TBC_DB_SHA1="a70165a80d23fe4917f91212dc8e399fb68d9cdd"
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
 && make install

FROM ubuntu:20.04

# Installing `gosu` and required shared libraries...
#
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        gosu \
        libmariadb-dev \
        libssl1.1 \
        mariadb-client \
 \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

# Creating `mangos:mangos` user...
#
RUN useradd --home /home/mangos --create-home \
            --comment "MaNGOS" \
            --user-group mangos

# Defining working directory...
#
WORKDIR /home/mangos

# Copying files from builder...
#
# TODO: Are `mangos` and `tbc-db` directories really required?
#
COPY --from=builder /home/mangos/run /opt/mangos
COPY --from=builder /home/mangos/mangos/sql /opt/mangos/sql
COPY --from=builder --chown=mangos:mangos /home/mangos/tbc-db /home/mangos/tbc-db

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
# CMD ["cmangos"]
CMD ["bash"]

EXPOSE 3443 3724 7878 8085 8086
