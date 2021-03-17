FROM ubuntu:20.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        gosu \
        libmariadb-dev \
        libssl1.1 \
 \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

RUN useradd --home /home/mangos --create-home \
            --comment "MaNGOS" \
            --user-group mangos

WORKDIR /opt/mangos

COPY --from=cmangos/mangos-builder:tbc /home/mangos/run /opt/mangos

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

EXPOSE 3443 3724 7878 8085 8086
