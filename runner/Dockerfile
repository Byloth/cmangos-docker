FROM ubuntu:20.04

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        gosu \
        libmariadb-dev \
        libssl1.1 \
        tzdata \
        wait-for-it \
 \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

RUN useradd --home /home/mangos --create-home \
            --comment "MaNGOS" \
            --user-group mangos

WORKDIR /opt/mangos

COPY --from=cmangos/builder:tbc /home/mangos/run /opt/mangos
COPY entrypoint.sh /

RUN mkdir /opt/mangos/data \
 && sed -i '/^DataDir/c\DataDir = "/opt/mangos/data"' etc/mangosd.conf.dist

VOLUME ["/opt/mangos/data"]

ARG TIMEZONE="UTC"
ENV TIMEZONE="${TIMEZONE}" \
    MANGOS_DBHOST="127.0.0.1" \
    MANGOS_DBPORT="3306" \
    MANGOS_DBUSER="mangos" \
    MANGOS_DBPASS="mangos" \
    \
    MANGOS_REALMD_DBNAME="tbcrealmd" \
    MANGOS_MANGOS_DBNAME="tbcmangos" \
    MANGOS_CHARACTERS_DBNAME="tbccharacters"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

EXPOSE 3443 \
       3724 \
       7878 \
       8085 \
       8086
