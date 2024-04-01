# Use a smaller base image
FROM debian:bookworm as build

# Combine RUN commands to minimize layers and clean up in the same layer
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget; \
    curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash -s ;\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        mariadb-backup \
        mariadb-client; \
    wget -O /tmp/s5cmd.deb https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_linux_amd64.deb; \
        dpkg -i /tmp/s5cmd.deb; \
        rm /tmp/s5cmd.deb; \
    #wget -O /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc; \
    #chmod +x /usr/local/bin/mc; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /backup; \
    chown -R 1000:1000 /backup

# Copy backup script and execute
COPY resources/perform-backup.sh /
RUN chmod +x /perform-backup.sh

FROM scratch
COPY --from=build / /
#USER 1000
WORKDIR /backup
CMD ["sh", "/perform-backup.sh"]