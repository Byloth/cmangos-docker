# Docker Volumes

Everything your server needs to remember — extracted game data, databases, configuration — lives **outside** the containers. Containers are disposable: they are deleted and recreated on every update, so anything worth keeping is stored in Docker volumes or mounted from your project directory.

This page explains where each piece of data lives, how the containers use it and how to work with the volumes.

## The big picture

CMaNGOS Docker uses two **named volumes**, declared at the bottom of `docker-compose.yml`:

```yaml
volumes:
  mariadb_data:
  mangosd_data:
```

A Docker volume is a persistent storage area that survives even when containers are deleted or recreated.  
Both volumes are **managed by Docker Compose**: they are created automatically the first time a service needs them, with no manual step required.

Docker Compose prefixes the volumes it manages with the project name. Since `docker-compose.yml` starts with `name: cmangos`, the project is always called `cmangos` — whatever directory you cloned or extracted it into — so the real volume names are always:

| Volume (in `docker-compose.yml`) | Real name (in `docker volume` commands) | Contents |
|----------------------------------|-----------------------------------------|----------|
| `mangosd_data` | `cmangos_mangosd_data` | Extracted game data and database backups |
| `mariadb_data` | `cmangos_mariadb_data` | All databases — accounts, characters, world data |

::: danger `docker compose down -v` deletes BOTH volumes
The `-v` flag removes every volume declared in `docker-compose.yml`. Running `docker compose down -v` permanently deletes:

- the **game data** extracted from your client (`maps`, `vmaps`, `mmaps`, `dbc`, `Cameras`) — hours of extraction work;
- **all your databases** — every account, character and world customization;
- the **backups stored inside the volume** by `backup-db`.

The only backup that survives is the archive you wrote to the **host** (e.g. `backup-db > backups/cmangos_backup.tar.gz`, see [Creating a backup](/guide/database-management#creating-a-backup)).

To stop the server, always use a plain `docker compose down` — **without** `-v`.
:::

A handful of **bind mounts** — plain directories from your project folder — complete the picture; they are covered [below](#bind-mounts).

## The `cmangos_mangosd_data` volume

This is where CMaNGOS stores the game data extracted from your WoW client:

| Path | Contents |
|------|----------|
| `Cameras/` | Camera definitions for cinematics |
| `dbc/` | Database client files — game strings, definitions and lookup tables |
| `maps/` | Terrain geometry and map data |
| `mmaps/` | Movement mesh data for NPC pathfinding |
| `vmaps/` | Visual mesh data for line-of-sight calculations |
| `logs/` | Extraction logs from the `extract` command |
| `.resext` | Marker written at the end of a successful `extract`; it makes a later `extract` ask before overwriting |
| `backups/` | One `<timestamp>/` directory per `backup-db` run, holding the raw `.sql` dumps and the `.tar.gz` archive |
| `tmp/` | Temporary files (e.g. during a `restore-db`) |

These files are **copyrighted by Blizzard Entertainment** and are extracted from your legally owned game client. They cannot be distributed with the Docker image, which is why you must generate them yourself.

A typical volume after extraction is **2–5 GB**, depending on the expansion.

### How the containers use it

The volume is shared between three services, with different access levels:

| Service | Mount point | Access | Purpose |
|---------|-------------|--------|---------|
| **builder** | `/home/mangos/data` | read-write | Writes the extracted data; stores database backups |
| **mangosd** | `/var/lib/mangos` | read-only | Reads maps, vmaps, mmaps and dbc files at runtime |
| **realmd** | `/var/lib/mangos` | read-only | Mounted, but not used: the data directory is only configured for mangosd |

Because multiple services need access to the same files, a named volume — rather than a bind mount — is the cleanest solution.  
It works identically across Windows, macOS and Linux.

::: warning Backups inside the volume are not backups
Each `backup-db` run leaves a copy of its dumps in `backups/`, but that copy lives in the same volume as everything else: `docker compose down -v` or `docker volume rm cmangos_mangosd_data` deletes it too.  
Always keep the archive written to the host — and, ideally, a copy of it on another machine.
:::

## The `cmangos_mariadb_data` volume

This is where MariaDB stores **all your databases**, mounted at `/var/lib/mysql` inside the `mariadb` container:

- The **realm database** — player accounts and realm definitions
- The **characters database** — every character, item, quest state and mail
- The **world database** — NPCs, loot tables, quests and any custom content you add
- The **logs database** — server activity logs

Like the game-data volume, it is created automatically the first time you start the database and it is deleted by `docker compose down -v` (see the [warning above](#the-big-picture)).  
Keep regular [database backups](/guide/database-management#backups) on the host.

## Bind mounts

Alongside the named volumes, a few directories are mounted straight from your project folder:

| Host path | Container path | Service | Purpose |
|-----------|----------------|---------|---------|
| `./runner/config` | `/opt/mangos/conf` (read-only) | mangosd, realmd | [Server configuration](/guide/server-configuration) files |
| `./database` | `/etc/mysql/conf.d` (read-only) | mariadb | MariaDB configuration (`my.cnf`) |
| `${WOW_CLIENT_DIR}` | `/home/mangos/wow-client` | builder | Your WoW client, read during [data extraction](/guide/getting-started#extract-game-data) |

If `WOW_CLIENT_DIR` is not set, Compose falls back to `./wow-client` (creating it if needed), and `extract` then stops with an error because that folder contains no `Data/` directory.

Since these live in your project directory, you edit them directly with your favorite editor — no Docker commands involved — and they naturally survive anything that happens to containers or volumes.

## Working with volumes

The commands below use `cmangos_mangosd_data` as the example; they work the same way on the database volume — just use `cmangos_mariadb_data` instead.

### Checking a volume

To verify a volume exists and see where Docker stores it:

```sh
docker volume inspect cmangos_mangosd_data
```

To see how much space it is using:

```sh
docker system df -v | grep cmangos_mangosd_data
```

### Removing the volume

::: danger Data loss warning
Removing the volume will delete **all** extracted game data and any backups stored inside it. You will need to re-run the extraction step and restore backups from copies kept on the host.
:::

If you need to start completely fresh:

```sh
# Stop all services first
docker compose down

# Remove the volume
docker volume rm cmangos_mangosd_data
```

There is no need to recreate it: Docker Compose creates an empty one the next time a service needs it. Then [extract the game data](/guide/getting-started#extract-game-data) again.

### Moving a volume to a different location

By default, Docker stores volumes on your system drive. If you need to move a volume to a larger or faster disk, let Docker Compose create it as a bind to a directory of your choice, through a `docker-compose.override.yml` file (Compose reads it automatically, next to `docker-compose.yml`):

1. Stop the server:
   ```sh
   docker compose down
   ```

2. Copy the current volume contents to the new directory:
   ```sh
   docker run --rm \
              -v cmangos_mangosd_data:/from \
              -v /new/path/cmangos_data:/to \
              alpine cp -a /from/. /to/
   ```

3. Remove the old volume:
   ```sh
   docker volume rm cmangos_mangosd_data
   ```

4. Create a `docker-compose.override.yml` file in your project directory:
   ```yaml
   volumes:
     mangosd_data:
       driver: local
       driver_opts:
         type: none
         o: bind
         device: /new/path/cmangos_data
   ```

5. Start the server; Compose creates the volume with the new options:
   ```sh
   docker compose up -d
   ```

::: tip Windows and macOS
On Docker Desktop for Windows and macOS, volumes live inside the Docker virtual machine. Moving them to a different host disk requires adjusting the Docker Desktop resource settings rather than bind-mounting directly.
:::

## Troubleshooting

### `volume "cmangos_mangosd_data" already exists but was not created by Docker Compose`

If you installed CMaNGOS Docker before the volume became Compose-managed, you created it by hand with `docker volume create`. On every command, Compose now prints:

```
volume "cmangos_mangosd_data" already exists but was not created by Docker Compose. Use `external: true` to use an existing volume
```

It's only a **warning**: since the name matches, Compose reuses your existing volume and all its data.

::: warning Don't add `external: true`
Ignore the hint at the end of the message. Adding `external: true` to `docker-compose.yml` brings back the old setup, which this project has moved away from.
:::

### Extraction fails with permission errors

The builder container runs as `root`, so it can always write to the volume; the runner containers only need to *read* it (they mount it read-only and drop privileges to the `mangos` user). With a standard Docker setup, permissions should therefore never be an issue.

If you're on an unusual setup (e.g. rootless Docker with custom UID mappings) and something still fails, inspect the volume contents to check ownership:

```sh
docker run --rm -v cmangos_mangosd_data:/data alpine ls -la /data
```

### Volume grows unexpectedly large

Check for old backup files or repeated extraction runs:

```sh
# Inspect the volume contents
docker run --rm -v cmangos_mangosd_data:/data alpine sh -c "du -sh /data/*"
```

Clean up old backups (each `backup-db` run has its own timestamped directory):

::: code-group

```sh [All platforms]
# Remove backups older than 30 days (run from inside the builder)
docker compose run --rm builder bash -c "find /home/mangos/data/backups -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +"
```

```sh [*nix shortcut]
# Remove backups older than 30 days (run from inside the builder)
./builder/run.sh bash -c "find /home/mangos/data/backups -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +"
```

:::
