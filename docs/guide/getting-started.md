# Getting Started

One of the main goals of the **CMaNGOS Docker** project is **optimization**.
To achieve this, **two different types** of Docker images have been developed: one used for **maintenance** (larger) and one used for **execution** (smaller and optimized).

With this principle in mind, we can now begin!

::: warning Not production-ready
This procedure doesn't describe a _production-ready_ deployment and doesn't delve into security best practices. It's just a simple practical example of a basic CMaNGOS Docker configuration; be careful when using it directly in a production environment.

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

Download the [`cmangos-docker.zip`](https://github.com/Byloth/cmangos-docker/archive/refs/heads/master.zip) archive, open it, and extract its contents into the newly created directory.

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

Since it contains sensitive information (like passwords), it cannot be included pre-configured. To create it, copy the `.env.example` file and rename it to `.env`, then edit it with any text editor.

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

Once you're done, save the file and close your text editor.

## Extract game data

Due to legal reasons and copyright policies, CMaNGOS cannot be distributed in a fully _ready-to-run_ state. It requires **additional data files** that are copyrighted by Blizzard Entertainment.

These files are present within the WoW game client.  
If you legally own the game, you can extract them using the CMaNGOS extraction tool.

::: code-group

```sh [Linux / Unix / macOS]
./builder/run.sh extract
```

```bat [Windows Command Prompt]
docker run -it --rm ^
           --volume "cmangos_mangosd_data:/home/mangos/data" ^
           --volume "{path}:/home/mangos/wow-client" ^
    ^
    ghcr.io/byloth/cmangos/{version}/builder:latest extract
```

```powershell [Windows PowerShell]
docker run -it --rm `
           --volume "cmangos_mangosd_data:/home/mangos/data" `
           --volume "{path}:/home/mangos/wow-client" `
    `
    ghcr.io/byloth/cmangos/{version}/builder:latest extract
```

:::

::: warning Placeholders
For Windows users: replace `{path}` with your WoW installation directory path and `{version}` with your chosen expansion keyword (`classic`, `tbc`, or `wotlk`).
:::

::: info Extraction time
This process extracts maps, textures, and other game data.  
Depending on your hardware, it may take **30 minutes to several hours** to complete.
:::

## Initialize the database

The database stores all game world information: NPCs, items, quests, spells, and much more. This step creates the required databases and populates them with initial data.

Open a terminal in your project directory and start the database server:

```sh
docker compose up mariadb
```

This terminal will display log output. Leave it running and open a **second terminal** in the same directory.

In the second terminal, initialize the databases:

::: code-group

```sh [Linux / Unix / macOS]
./builder/run.sh init-db
```

```bat [Windows Command Prompt]
docker run -it --rm ^
           --env MYSQL_SUPERUSER="root" ^
           --env MYSQL_SUPERPASS="root00" ^
           --env MANGOS_DBHOST="mariadb" ^
           --env MANGOS_DBUSER="mangos" ^
           --env MANGOS_DBPASS="mangos00" ^
           --network "cmangos_default" ^
           --volume "cmangos_mangosd_data:/home/mangos/data" ^
    ^
    ghcr.io/byloth/cmangos/{version}/builder:latest init-db
```

```powershell [Windows PowerShell]
docker run -it --rm `
           --env MYSQL_SUPERUSER="root" `
           --env MYSQL_SUPERPASS="root00" `
           --env MANGOS_DBHOST="mariadb" `
           --env MANGOS_DBUSER="mangos" `
           --env MANGOS_DBPASS="mangos00" `
           --network "cmangos_default" `
           --volume "cmangos_mangosd_data:/home/mangos/data" `
    `
    ghcr.io/byloth/cmangos/{version}/builder:latest init-db
```

:::

::: warning Placeholders
For Windows users: replace `{version}` with the correct expansion keyword and update the environment variable values to match your `.env` file.
:::

Once initialization completes, return to the first terminal and press `Ctrl+C` to stop the database server.

## Start the server

You're now ready to run your WoW server for the first time!

From your project directory, run:

```sh
docker compose up
```

The terminal will display server logs. As long as messages are being printed, your server is running.

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
