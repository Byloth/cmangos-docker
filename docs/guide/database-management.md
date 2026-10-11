# Database Management

::: warning Work in Progress
This page is currently under construction and may be incomplete.
:::

CMaNGOS uses a MariaDB database to store all game data, player characters, and server logs.  
This guide covers common database operations like backups, restores, and running queries.

## Prerequisites

Before performing any database operations, make sure the database server is running:

```sh
docker compose up mariadb -d
```

The `-d` flag runs the container in detached mode (background).

## Backups

Regular backups are essential for protecting your server data.  
CMaNGOS Docker provides built-in tools for creating and restoring backups.

### Creating a backup

From within your project directory, run:

::: code-group

```sh [All databases]
./builder/run.sh backup-db --all > backups/cmangos_$(date +"%Y-%m-%d_%H-%M-%S").tar.gz
```

```sh [World database only]
./builder/run.sh backup-db --world > backups/world_$(date +"%Y-%m-%d").tar.gz
```

```sh [Characters database only]
./builder/run.sh backup-db --characters > backups/characters_$(date +"%Y-%m-%d").tar.gz
```

:::

::: tip Backup options
The `backup-db` command supports these flags:
- `--all` — Backup all databases
- `--world` — World data (NPCs, items, quests, etc.)
- `--characters` — Player characters and progression
- `--logs` — Server activity logs
- `--realmd` — Realm and account data
:::

### Restoring a backup

To restore from a backup file:

```sh
./builder/run.sh restore-db < backups/cmangos_2024-01-15_12-30-00.tar.gz
```

::: danger Destructive operation
Restoring a backup will **overwrite** the current database contents.  
Make sure you have a recent backup of your current data before proceeding.
:::

## Querying databases

To execute queries and perform various operations on the databases, CMaNGOS Docker provides both a graphical interface through **[phpMyAdmin](https://www.phpmyadmin.net/)** and the CLI `mysql` command within the `builder` Docker container.

Choose the one that best suits your needs.

### Using phpMyAdmin

phpMyAdmin is included in CMaNGOS Docker but is disabled by default.  
To run it, you can either start it manually or use the `debug` profile.

::: code-group

```sh [Start manually]
docker compose up phpmyadmin
```

```sh [Use debug profile]
docker compose --profile debug up
```

:::

After running one of these commands, visit [`http://localhost:8080`](http://localhost:8080) to access phpMyAdmin's graphical interface.

::: info Default credentials
Use the database credentials from your `.env` file to log in.  
The root user is `root` with the password you set in `MYSQL_SUPERPASS`.
:::

### Using the MySQL CLI

For command-line access, you can use the `builder` container to run MySQL commands directly.

::: code-group

```sh [Linux / Unix / macOS]
# Execute a single inline query
./builder/run.sh mysql -u root -p {database} -e "SELECT * FROM realmlist;"

# Execute queries from a file
./builder/run.sh mysql -u root -p {database} < path/to/queries.sql
```

```bat [Windows Command Prompt]
:: Execute a single inline query
docker run -it --rm ^
           --network "cmangos_default" ^
    ^
    ghcr.io/byloth/cmangos/{version}/builder:latest mysql -u root -p {database} -e "SELECT * FROM realmlist;"
```

```powershell [Windows PowerShell]
# Execute a single inline query
docker run -it --rm `
           --network "cmangos_default" `
    `
    ghcr.io/byloth/cmangos/{version}/builder:latest mysql -u root -p {database} -e "SELECT * FROM realmlist;"
```

:::

::: warning Placeholders
Replace `{database}` with the name of the database you want to query:
- `classicmangos`, `tbcmangos`, or `wotlkmangos` — World data
- `classiccharacters`, `tbccharacters`, or `wotlkcharacters` — Character data
- `classiclogs`, `tbclogs`, or `wotlklogs` — Log data
- `classicrealmd`, `tbcrealmd`, or `wotlkrealmd` — Realm data

For Windows users, also replace `{version}` with your expansion keyword.
:::

## Database structure

CMaNGOS uses four separate databases for each expansion:

| Database | Purpose |
|----------|---------|
| `{expansion}mangos` | World data (NPCs, items, quests, spells, loot tables, etc.) |
| `{expansion}characters` | Player data (characters, inventories, skills, achievements, etc.) |
| `{expansion}logs` | Server logs (chat, trades, GM commands, etc.) |
| `{expansion}realmd` | Account and realm data (login credentials, realm list, bans, etc.) |

Where `{expansion}` is one of: `classic`, `tbc`, or `wotlk`.
