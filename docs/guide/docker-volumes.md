# Docker Volumes

Everything your server needs to remember — extracted game data, databases, configuration — lives **outside** the containers. Containers are disposable: they are deleted and recreated on every update, so anything worth keeping is stored in Docker volumes or mounted from your project directory.

This page explains where each piece of data lives, how the containers use it and how to work with the volumes.

## The big picture

CMaNGOS Docker uses two **named volumes**, declared at the bottom of `docker-compose.yml`:

```yaml
volumes:
  mariadb_data:
  cmangos_mangosd_data:
    external: true
```

A Docker volume is a persistent storage area that survives even when containers are deleted or recreated. The two volumes are managed differently, though — and that difference matters:

| Volume | Contents | Managed by | Survives `docker compose down -v`? |
|--------|----------|------------|------------------------------------|
| `cmangos_mangosd_data` | Extracted game data and backups | You (external) | ✅ Yes |
| `mariadb_data` | All databases — accounts, characters, world data | Docker Compose | ❌ **No** |

A handful of **bind mounts** — plain directories from your project folder — complete the picture; they are covered [below](#bind-mounts).

## The `cmangos_mangosd_data` volume

This is where CMaNGOS stores the game data extracted from your WoW client:

| Directory | Contents |
|-----------|----------|
| `Cameras/` | Camera definitions for cinematics |
| `dbc/` | Database client files — game strings, definitions and lookup tables |
| `maps/` | Terrain geometry and map data |
| `mmaps/` | Movement mesh data for NPC pathfinding |
| `vmaps/` | Visual mesh data for line-of-sight calculations |
| `logs/` | Extraction logs from the `extract` command |
| `backups/` | Database backups created with `backup-db` |
| `tmp/` | Temporary files (e.g. during a `restore-db`) |

These files are **copyrighted by Blizzard Entertainment** and are extracted from your legally owned game client. They cannot be distributed with the Docker image, which is why you must generate them yourself.

### How the containers use it

The volume is shared between three services, with different access levels:

| Service | Mount point | Access | Purpose |
|---------|-------------|--------|---------|
| **builder** | `/home/mangos/data` | read-write | Writes the extracted data; stores database backups |
| **mangosd** | `/var/lib/mangos` | read-only | Reads maps, vmaps, mmaps and dbc files at runtime |
| **realmd** | `/var/lib/mangos` | read-only | Reads dbc files at runtime |

Because multiple services need access to the same files, a named volume — rather than a bind mount — is the cleanest solution.  
It works identically across Windows, macOS and Linux.

### Why it is external

In `docker-compose.yml`, the volume is declared as `external: true`. This means Docker Compose expects the volume to exist before you start the server: it is **not** created automatically when you run `docker compose up`.

That may sound like an inconvenience, but it is a deliberate safety choice: an external volume survives even a `docker compose down -v`, protecting hours of extraction work from accidental deletion.

### Creating the volume

Before your first extraction or server start, create the volume manually:

```sh
docker volume create cmangos_mangosd_data
```

If you skip this step, Docker Compose will refuse to start any service that uses the volume, with an error like:

```
external volume "cmangos_mangosd_data" not found
```

A typical volume after extraction is **2–5 GB**, depending on the expansion.

## The `mariadb_data` volume

This is where MariaDB stores **all your databases**, mounted at `/var/lib/mysql` inside the `mariadb` container:

- The **realm database** — player accounts and realm definitions
- The **characters database** — every character, item, quest state and mail
- The **world database** — NPCs, loot tables, quests and any custom content you add
- The **logs database** — server activity logs

Unlike the game-data volume, `mariadb_data` is managed by Docker Compose: it is created automatically the first time you start the database, with no manual step required. Since Compose prefixes the volumes it manages with the project name (`cmangos`), it appears as **`cmangos_mariadb_data`** in `docker volume` commands.

::: danger This volume is NOT external
`mariadb_data` does **not** survive `docker compose down -v`: that command deletes the volume — and with it every account and character on your server.

Prefer a plain `docker compose down` (without `-v`) and keep regular [database backups](/guide/database-management#backups): they are stored in the `cmangos_mangosd_data` volume, which *does* survive.
:::

## Bind mounts

Alongside the named volumes, a few directories are mounted straight from your project folder:

| Host path | Container path | Service | Purpose |
|-----------|----------------|---------|---------|
| `./runner/config` | `/opt/mangos/conf` (read-only) | mangosd, realmd | [Server configuration](/guide/server-configuration) files |
| `./database` | `/etc/mysql/conf.d` (read-only) | mariadb | MariaDB configuration (`my.cnf`) |
| `${WOW_CLIENT_DIR}` | `/home/mangos/wow-client` | builder | Your WoW client, read during [data extraction](/guide/getting-started#extract-game-data) |

Since these live in your project directory, you edit them directly with your favorite editor — no Docker commands involved — and they naturally survive anything that happens to containers or volumes.

## Working with volumes

The commands below use `cmangos_mangosd_data` as the example; they work the same way on the database volume — just remember that its actual name is `cmangos_mariadb_data`.

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
Removing the volume will delete **all** extracted game data and any backups stored inside it. You will need to re-run the extraction step and restore backups from external copies.
:::

If you need to start completely fresh:

```sh
# Stop all services first
docker compose down

# Remove the volume
docker volume rm cmangos_mangosd_data

# Recreate it
docker volume create cmangos_mangosd_data
```

### Moving a volume to a different location

By default, Docker stores volumes on your system drive. If you need to move a volume to a larger or faster disk:

1. Stop the server:
   ```sh
   docker compose down
   ```

2. Back up the current volume contents to a local directory:
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

4. Create a new volume from the backup directory:
   ```sh
   docker volume create --driver local \
     --opt type=none \
     --opt o=bind \
     --opt device=/new/path/cmangos_data \
     cmangos_mangosd_data
   ```

5. Start the server:
   ```sh
   docker compose up -d
   ```

::: tip Windows and macOS
On Docker Desktop for Windows and macOS, volumes live inside the Docker virtual machine. Moving them to a different host disk requires adjusting the Docker Desktop resource settings rather than bind-mounting directly.
:::

## Troubleshooting

### `external volume "cmangos_mangosd_data" not found`

You forgot to create the volume. Run:

```sh
docker volume create cmangos_mangosd_data
```

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

Clean up old backups:

::: code-group

```sh [All platforms]
# Remove backups older than 30 days (run from inside the builder)
docker compose run --rm builder bash -c "find /home/mangos/data/backups -type f -mtime +30 -delete"
```

```sh [*nix shortcut]
# Remove backups older than 30 days (run from inside the builder)
./builder/run.sh bash -c "find /home/mangos/data/backups -type f -mtime +30 -delete"
```

:::
