# Getting Started

One of the main goals of the **CMaNGOS Docker** project is **optimization**.  
To achieve this, **two different types** of Docker images have been developed: one used for **maintenance** (larger) and one used for **execution** (smaller and optimized).

With this principle in mind, we can now begin!

::: warning Not production-ready
This procedure doesn't describe a _production-ready_ deployment and doesn't delve into security best practices: it's just a simple practical example of a basic CMaNGOS Docker configuration.  
Be careful when using it directly in a production environment!

If you're looking for more specific guidance, see the [Use in Production](/guide/use-in-production) page.
:::

## Choose your expansion

First of all, you have to decide which client version you want your server to support.  
Both CMaNGOS and CMaNGOS Docker use **three keywords** to identify it.

Select the one you need and **keep it in mind** for the next steps:

| Game name | Game version | Keyword |
|-----------|--------------|---------|
| World of Warcraft | **v1.12.x** | `classic` |
| World of Warcraft: The Burning Crusade | **v2.4.3** | `tbc` |
| World of Warcraft: Wrath of the Lich King | **v3.3.5a** | `wotlk` |

## Download the project

Create a new directory on your computer to store everything related to your WoW server.  
It's best **NOT** to use the same directory as the game client — keep them separate from each other.

Download the [`cmangos-docker.zip`](https://github.com/Byloth/cmangos-docker/archive/refs/heads/master.zip) archive, open it and extract its contents into the newly created directory.

::: tip Using Git
If you're familiar with [Git](https://git-scm.com/), you can clone the repository directly instead of downloading the archive:

```sh
git clone https://github.com/Byloth/cmangos-docker.git
```
:::

::: info Keeping files up to date
This archive may be updated over time.  
Make sure to check it periodically and follow the [update procedure](/guide/install-updates) when needed.
:::

## Locate the game client

To play World of Warcraft, you'll need a legally owned copy of the game installed on your computer.

Locate the installation directory. On Windows, the default location is typically `C:\Program Files\World of Warcraft`.  
Once you find it, copy the full path — we'll need it in the next step.

## Configure the environment

The `.env` file is a configuration file that customizes your WoW server setup.

Since it contains sensitive information (like passwords), it cannot be included pre-configured; to create it, copy the `.env.example` file and rename it to `.env`, then edit it with any text editor.

### Environment variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MYSQL_SUPERPASS` | Password for the MySQL `root` administrator account | `root00` |
| `MANGOS_DBUSER` | Username for the application's database connection | `mangos` |
| `MANGOS_DBPASS` | Password for the application's database connection | `mangos00` |
| `WOW_CLIENT_DIR` | Full path to your WoW game installation | `D:\Games\WoW` |
| `WOW_TIMEZONE` | Server timezone ([tz database format](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) | `Europe/Rome` |
| `WOW_VERSION` | Expansion keyword from the table above | `tbc` |

::: danger Security notice
Choose strong, unique passwords for `MYSQL_SUPERPASS` and `MANGOS_DBPASS`.  
The example values (`root00`, `mangos00`) are **not secure** and should only be used for local testing.
:::

Need inspiration?  
Generate a strong random password right here — it only uses characters that are safe to paste directly into your `.env` file:

<PasswordGenerator />

Once you're done, save the file and close your text editor.

## Create the data volume

Docker uses what it calls "volumes" to store files. See them as virtual disks.  
CMaNGOS stores the extracted game data, your database backups and other stuff in a dedicated Docker volume called [`cmangos_mangosd_data`](/guide/docker-volumes).

To create it once, open a terminal or a command prompt and type:

```sh
docker volume create cmangos_mangosd_data
```

## Start the database

Now it's time to start the database server for the first time:

```sh
docker compose up -d mariadb
```

Besides launching the database — which we'll need shortly to initialize it — this first `docker compose` command also creates automatically everything the stack needs to run.

## Extract game data

Due to legal reasons and copyright policies, CMaNGOS cannot be distributed in a fully _ready-to-run_ state. It requires **additional data files** that are copyrighted by Blizzard Entertainment.

These files are present within the WoW game client.  
If you legally own the game, you can extract them using the CMaNGOS extraction tool.

Open a terminal in your project directory and run:

::: code-group

```sh [All platforms]
docker compose run --rm builder extract
```

```sh [*nix shortcut]
./builder/run.sh extract
```

:::

::: info Two flavors, same command
Throughout this guide, every maintenance command is shown in two flavors:

- **All platforms** — the `docker compose run` form; works identically on Windows, macOS and Linux.
- **\*nix shortcut** — the `./builder/run.sh` wrapper script shipped with the repository; WSL, macOS and Linux only.

They're equivalent, so pick the one you prefer.
:::

::: info Extraction time
This process extracts maps, textures and other game data.  
Depending on your hardware, it may take **30 minutes to several hours** to complete.
:::

## Initialize the database

The database stores all game world information: NPCs, items, quests, spells and much more...  
This step creates the required databases and populates them with initial data.

From your project directory, run:

::: code-group

```sh [All platforms]
docker compose run --rm builder init-db
```

```sh [*nix shortcut]
./builder/run.sh init-db
```

:::

## Start the server

You're now ready to run your WoW server for the first time!

From your project directory, run:

```sh
docker compose up
```

The terminal will display server logs; as long as messages are being printed, your server is running.

::: tip Running in background
To run the server in the background (detached mode), add the `-d` flag:

```sh
docker compose up -d
```

You can then view logs with `docker compose logs -f` and stop with `docker compose down`.
:::

## Connect to your server

To play on your server, you need to configure the WoW client to connect to it.

### Edit realmlist.wtf

Locate the `realmlist.wtf` file inside your WoW client's `Data` directory and open it with a text editor.

Replace its contents with:

```
set realmlist 127.0.0.1
```

::: info Remote connections
If you're connecting from a different computer on your network, replace `127.0.0.1` with the server machine's IP address.  
For internet connections, you'll need to configure port forwarding on your router.
:::

### Create an account

Before you can log in, you need to create a game account.  
See the [Server Administration](/guide/server-administration) guide for instructions on creating accounts and managing users.

## Stop the server

To stop the server gracefully, press `Ctrl+C` in the terminal where it's running.  
This may take a few seconds as the server saves data and disconnects players.

::: tip Clean shutdown
To ensure everything is properly stopped:

```sh
docker compose down
```
:::

## Next steps

Now that your server is running, you may want to:

- [Create user accounts](/guide/server-administration#creating-accounts) to log into the game
- [Configure server settings](/guide/server-configuration) like experience rates or PvP rules
- [Set up the realm list](/guide/server-configuration#realm-configuration) for proper client connections
- [Learn about backups](/guide/database-management#backups) to protect your data
