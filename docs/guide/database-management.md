# Database Management

CMaNGOS uses a MariaDB database to store all game data, player characters and server logs.  
This guide covers common database operations like backups, restores, running queries and maintenance.

## Prerequisites

All the maintenance commands on this page run inside the `builder` container and are shown in two flavors:

- **All platforms** — the `docker compose run` form; works identically on Windows, macOS and Linux.  
  You don't even need to start the database server first: Docker Compose starts it automatically as a dependency and waits for it to be ready.
- **\*nix shortcut** — the `./builder/run.sh` wrapper script; WSL, macOS and Linux only.  
  It runs the same `docker compose run` command under the hood, so it behaves exactly the same way.

## Backups

Regular backups are essential for protecting your server data.  
CMaNGOS Docker provides built-in tools for creating and restoring backups.

### Creating a backup

From within your project directory, run:

::: code-group

```sh [All platforms]
docker compose run --rm -T builder backup-db > backups/cmangos_backup.tar.gz
```

```sh [*nix shortcut]
./builder/run.sh backup-db > backups/cmangos_backup-$(date +"%Y_%m_%d-%H_%M_%S").tar.gz
```

:::

::: warning Binary output
The backup is written to **standard output** as a binary archive.  
In the `docker compose` form, the `-T` flag disables the pseudo-TTY, which would otherwise corrupt the binary stream — always use it when redirecting or piping the output of a builder command.  
The shortcut script handles this automatically.

On Windows, run these commands from the **Command Prompt**: PowerShell's redirection re-encodes the stream and corrupts binary data.
:::

::: tip Backup options
Without any flag, `backup-db` backs up all four databases.  
To back up only some of them, combine these flags:
- `-w` / `--world` — World data (NPCs, items, quests, etc.)
- `-c` / `--characters` — Player characters and progression
- `-l` / `--logs` — Server activity logs
- `-r` / `--realmd` — Realm and account data

`-a` / `--all` backs up all databases, exactly like no flags; it cannot be combined with the other flags (the command exits with an error).
:::

::: info Where backups are stored
The command outputs the backup archive to **standard output** (stdout).  
The examples above redirect it to a local `backups/` directory.

Make sure this directory exists before running the command!
:::

### Restoring a backup

To restore from a backup file:

::: code-group

```sh [All platforms]
docker compose run --rm -T builder restore-db < backups/cmangos_backup.tar.gz
```

```sh [*nix shortcut]
./builder/run.sh restore-db < backups/cmangos_backup-2026_08_18-01_12_48.tar.gz
```

:::

::: danger Destructive operation
Restoring a backup will **overwrite** the current database contents.  
Make sure you have a recent backup of your current data before proceeding!
:::

::: warning The databases must already exist
`restore-db` loads each dump into the existing database with the same name: it replaces the tables contained in the dump, leaves any other table as it is and doesn't create the databases.  
On a fresh install, [initialize the database](/guide/getting-started#initialize-the-database) with `init-db` first, then restore your backup.
:::

## Interactive database management

For advanced operations — such as installing custom content, applying specific SQL patches or running the full database installer menu — use the `manage-db` command:

::: code-group

```sh [All platforms]
docker compose run --rm builder manage-db
```

```sh [*nix shortcut]
./builder/run.sh manage-db
```

:::

This launches the CMaNGOS `InstallFullDB.sh` interactive menu inside the builder container, giving you direct access to all database maintenance options provided by the upstream project.

## Querying databases

To execute queries and perform various operations on the databases, CMaNGOS Docker provides both a graphical interface through **[phpMyAdmin](https://www.phpmyadmin.net/)** and the MariaDB CLI command within the `builder` Docker container.

Choose the one that best suits your needs.

### Using phpMyAdmin

phpMyAdmin is included in CMaNGOS Docker but is disabled by default.  
To run it, you can simply use the `debug` profile:

```sh
docker compose --profile debug up
```

After running this command, visit [`http://localhost:8080`](http://localhost:8080) to access phpMyAdmin's graphical interface.

::: danger No login prompt: anyone who reaches it is root
phpMyAdmin logs in automatically as the database `root` user (with the `MYSQL_SUPERPASS` password from your `.env` file), without asking for any credentials.  
By default its port is published on all network interfaces, so **anyone who can reach port `8080` has full control of your databases**.

- Bind it to localhost by setting `PHPMYADMIN_PORT="127.0.0.1:8080"` in your `.env` file.
- Only start it when you need it, and stop it when you're done:

  ```sh
  docker compose --profile debug stop phpmyadmin
  ```
:::

### Using the MariaDB CLI

For command-line access, open an interactive shell inside the `builder` container:

::: code-group

```sh [All platforms]
docker compose run --rm builder bash
```

```sh [*nix shortcut]
./builder/run.sh bash
```

:::

The container already has your `.env` credentials loaded as environment variables, so from that shell you can connect right away:

```sh
mariadb -h"${MANGOS_DBHOST}" -u"${MYSQL_SUPERUSER}" -p"${MYSQL_SUPERPASS}"
```

Once connected, you can run any SQL you need:

```sql
-- Switch to the database you're interested in, for instance:
USE tbcrealmd;

-- Then you're ready to run all the queries you need, for example:
SELECT * FROM realmlist;
```

When you're done, type `exit` to leave the MariaDB client and `exit` again to leave the container.

::: tip One-liners for scripting
On WSL, macOS and Linux, you can run non-interactive queries in a single command:

```sh
# Execute a single inline query, for instance:
./builder/run.sh bash -c \
    'mariadb -h"${MANGOS_DBHOST}" -u"${MYSQL_SUPERUSER}" -p"${MYSQL_SUPERPASS}" tbcrealmd -e "SELECT * FROM realmlist;"'

# Execute queries from a file, for example:
./builder/run.sh bash -c \
    'mariadb -h"${MANGOS_DBHOST}" -u"${MYSQL_SUPERUSER}" -p"${MYSQL_SUPERPASS}" tbcmangos' < path/to/queries.sql
```
:::

::: warning Database names
The examples above use the `tbc` databases.  
Adjust the database name to your expansion keyword (`classic`, `tbc` or `wotlk`) — e.g. `classicrealmd`, `wotlkmangos`, ...
:::

::: tip Using mysql vs mariadb commands
The builder image includes MariaDB client tools: the canonical commands are `mariadb` and `mariadb-dump`.  
A `mysql` symlink may also be available, but `mariadb` is the preferred command for forward compatibility.
:::

## Database structure

CMaNGOS uses four separate databases for each expansion:

| Database | Purpose |
|----------|---------|
| `{expansion}mangos` | World data (NPCs, items, quests, spells, loot tables, etc.) |
| `{expansion}characters` | Player data (characters, inventories, skills, achievements, etc.) |
| `{expansion}logs` | Server logs (chat, trades, GM commands, etc.) |
| `{expansion}realmd` | Account and realm data (login credentials, realm list, bans, etc.) |

Where `{expansion}` is - as usual - one of: `classic`, `tbc` or `wotlk`.
