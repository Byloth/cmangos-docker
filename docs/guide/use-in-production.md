# Use in Production

::: warning Scope of this guide
This page covers practical hardening and operational advice for running CMaNGOS Docker on a single host with a small to medium player base. It does **not** cover enterprise-scale deployments, Kubernetes or automated multi-realm orchestration — those require infrastructure far beyond what this project provides out of the box.
:::

::: warning Linux-based instructions
Every command and example on this page assumes a **Linux host**: shell scripts, file permissions, UFW and cron are all Linux tools.  
On Windows, run everything inside [WSL 2](https://learn.microsoft.com/windows/wsl/); on macOS most commands work as-is, but the firewall section does not apply.
:::

Running a game server for actual players is very different from a local test environment. This guide will help you secure, tune and maintain your server responsibly.

## Security hardening

### Protect your credentials

The `.env` file contains database passwords and other sensitive configuration. Treat it like a key:

```sh
chmod 600 .env
```

This ensures only your user account can read it. Never commit `.env` to Git and never share it in screenshots or support requests.

::: tip .gitignore check
Make sure `.env` is listed in your `.gitignore` file. If you cloned the repository, it should already be there — but double-check.
:::

### Network isolation

By default, Docker Compose creates a private bridge network for your services. The MariaDB database has **no port mapping at all**: it is reachable by the other containers, but never from outside the host. Keep it that way — do **not** add a mapping for port 3306 unless you have a specific reason and understand the risk.

The only ports published to the host — and therefore reachable from outside — are:

| Port | Service | Purpose |
|------|---------|---------|
| `3724` | realmd | Login server |
| `8085` | mangosd | World server |

Both are configurable through the optional `REALMD_PORT` and `MANGOSD_PORT` variables in your `.env` file.

::: warning phpMyAdmin is a debugging tool
phpMyAdmin *does* have a port mapping (`8080`) in `docker-compose.yml`, but the service sits behind the `debug` Compose profile, so it is never started unless you explicitly activate that profile. **Do not run the `debug` profile on a production server.**

If you really need remote database administration, bind phpMyAdmin to localhost by setting `PHPMYADMIN_PORT="127.0.0.1:8080"` in your `.env` file and access it through an SSH tunnel.
:::

### Firewall configuration

A host firewall like UFW is still worth enabling — but you need to know what it does and does not cover:

::: warning Docker bypasses UFW
Docker manages its own `iptables` rules, which are evaluated **before** UFW's. Ports published by Docker Compose are therefore reachable from outside **even if UFW denies them** — and, conversely, `ufw allow` rules for those ports are effectively no-ops.

For the containers, your real access control is the Compose file itself: **only the ports you publish are exposed** — just `3724` and `8085` by default — on the interface you bind them to.
:::

Use UFW to protect the services running directly on the host, such as SSH:

```sh
# Example using UFW on Ubuntu
sudo ufw default deny incoming
sudo ufw allow 22/tcp
sudo ufw enable
```

If you need actual packet filtering in front of the containers too (e.g. an IP allowlist for the game ports), the mechanism Docker supports is the `DOCKER-USER` `iptables` chain — see the [Docker documentation](https://docs.docker.com/engine/network/packet-filtering-firewalls/) — or a helper tool like [ufw-docker](https://github.com/chaifeng/ufw-docker).

### Update regularly

Nightly builds incorporate upstream security fixes and bug patches. Make updating a habit:

1. Back up your databases
2. Pull the latest images
3. Apply database updates
4. Restart

See the [Installing Updates](/guide/install-updates) guide for the full procedure.

## Performance optimization

### Hardware recommendations

CMaNGOS is single-threaded for world simulation, so **clock speed matters more than core count** for the mangosd process. MariaDB benefits from multiple cores and fast disk I/O.

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 4 GB | 8 GB+ |
| CPU | 2 cores | 4+ cores, 3.0 GHz+ |
| Disk | Any SSD | NVMe SSD for database volume |
| Network | 10 Mbps | 100 Mbps+ symmetric |

The [database volume](/guide/docker-volumes#the-mariadb-data-volume) should live on your fastest disk.  
On Linux, you can inspect where Docker stores volumes:

```sh
docker volume inspect cmangos_mariadb_data
```

### Docker resource limits

Prevent a runaway process from consuming all host resources by adding limits to `docker-compose.yml`:

```yaml
services:
  mangosd:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M

  mariadb:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

Adjust the values based on your player count and available RAM.

### Database tuning

The `database/my.cnf` file shipped with the project is already mounted into the MariaDB container; it sets the required character set and a sane `wait_timeout`, but nothing more. For a production server, extend its `[mysqld]` section with tuned parameters:

```ini
# Connection settings
max_connections = 200

# InnoDB buffer pool — set to ~50-70% of the memory limit you gave MariaDB
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
```

::: warning innodb_flush_log_at_trx_commit
Setting this to `2` improves write performance at the cost of slightly reduced durability. A power loss could lose up to one second of transactions. For a game server, this is usually an acceptable trade-off.
:::

Changes to `database/my.cnf` take effect after restarting the database:

```sh
docker compose restart mariadb
```

## Backup automation

Manual backups are easy to forget. Automate them with a cron job.

### Create a backup script

Save this as `backup.sh` in your project directory:

```sh
#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

mkdir -p "${BACKUP_DIR}"

cd "${PROJECT_DIR}"
docker compose run --rm -T builder backup-db > "${BACKUP_DIR}/cmangos_${TIMESTAMP}.tar.gz"

# Keep only the last 14 backups
ls -1t "${BACKUP_DIR}"/cmangos_*.tar.gz | tail -n +15 | xargs -r rm -f

echo "Backup complete: ${BACKUP_DIR}/cmangos_${TIMESTAMP}.tar.gz"
```

Make it executable:

```sh
chmod +x backup.sh
```

### Schedule with cron

Open your crontab:

```sh
crontab -e
```

Add a daily backup at 3 AM:

```
0 3 * * * /path/to/your/project/backup.sh >> /path/to/your/project/backups/backup.log 2>&1
```

::: warning Backups also pile up inside the volume
Besides streaming the archive to standard output, each `backup-db` run leaves a second copy inside the `cmangos_mangosd_data` volume, under `backups/<timestamp>/`. With a daily cron job, those copies accumulate and the volume [grows unboundedly](/guide/docker-volumes#volume-grows-unexpectedly-large).

Prune them periodically — for example, by adding this line to `backup.sh` right after the backup command:

```sh
docker compose run --rm -T builder bash -c "find /home/mangos/data/backups -type f -mtime +30 -delete"
```
:::

::: tip Off-site storage
For extra safety, sync your `backups/` directory to cloud storage or another machine using `rsync`, `rclone` or similar tools.
:::

## Monitoring and health checks

### Basic uptime monitoring

The simplest health check is ensuring your services respond on their ports:

```sh
# Check login server
nc -z localhost 3724 && echo "realmd: OK" || echo "realmd: DOWN"

# Check world server
nc -z localhost 8085 && echo "mangosd: OK" || echo "mangosd: DOWN"
```

For automated monitoring, tools like [Uptime Kuma](https://github.com/louislam/uptime-kuma) can watch TCP ports and alert you via Telegram, Discord or email when your server goes offline.

### Log inspection

Server logs are your first diagnostic tool:

```sh
# Follow live logs
docker compose logs -f mangosd

# Check for errors in the last hour
docker compose logs --since 1h mangosd | grep -i error

# Save recent logs to a file
docker compose logs --since 24h > "$(date +%Y-%m-%d)_logs.txt"
```

### Container health

Every long-running service defines a Docker healthcheck, so you can see at a glance not just whether containers are running, but whether they are actually responding:

```sh
docker compose ps
```

Each service is reported as `(healthy)` or `(unhealthy)` in the `STATUS` column.

::: info mangosd takes its time
The world server binds its port only after loading databases, maps and mesh data — on first boot this can take several minutes, during which mangosd is reported as `(health: starting)`. That's normal.
:::

To block until the whole stack is up and healthy — handy in scripts — use:

```sh
docker compose up -d --wait
```

If a container exits unexpectedly, inspect its last logs and exit code:

```sh
docker compose logs --tail 50 <service-name>
docker inspect <container-id> --format='{{.State.ExitCode}}'
```

## Legal and ethical considerations

### Blizzard's stance

Blizzard Entertainment has historically taken action against commercial private servers and those that distribute game client files. Running a small, non-commercial server for personal use or a closed group of friends carries significantly lower risk, but it is not risk-free.

### Guidelines for responsible operation

- **Require legal ownership** — Do not distribute the WoW client. Every player must obtain their own copy through legitimate means.
- **Do not monetize** — Do not sell in-game items, advantages, subscriptions or donations that affect gameplay. Monetization is the single most reliable way to attract legal attention.
- **Keep it private** — Public advertising on large forums or server listing sites increases visibility and risk.
- **Respect intellectual property** — Do not use Blizzard's trademarks in your server name, domain or branding.

### Data privacy

If players from the European Union connect to your server, you should be aware of GDPR obligations regarding personal data. At minimum:

- Collect only what you need (account name, email if used, IP addresses in logs)
- Do not share player data with third parties
- Allow players to request deletion of their accounts and associated character data

::: warning Not legal advice
This section is a practical overview, not legal advice. Laws vary by jurisdiction. If you intend to operate a server with a large public player base, consult a lawyer familiar with intellectual property and gaming law.
:::
