FROM ubuntu:20.04

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
COPY --from=cmangos/builder:${EXPANSION} "${HOME_DIR}/run" "${MANGOS_DIR}"
COPY entrypoint.sh /

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
