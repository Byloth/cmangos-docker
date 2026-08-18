# Customization

Once your server is up and running, you will probably want to make it feel like your own.  
This guide covers the most common ways to customize your CMaNGOS Docker server, from built-in modules to world-level modifications.

::: tip Before you start
For basic gameplay settings — experience rates, drop rates, server type and realm configuration — see the [Server Configuration](/guide/server-configuration) guide.  
This page covers everything else.
:::

## Built-in modules

CMaNGOS Docker images come with several optional modules already compiled in.  
You only need to enable and configure them — no rebuilding required.

All module configuration files live in the `runner/config/` directory.  
The server reads them at startup and merges your overrides with the built-in defaults.

### PlayerBots

The [PlayerBots](https://github.com/cmangos/playerbots) module adds AI-controlled characters to your world.  
They can fill battlegrounds, roam the open world or even act as alts you command directly.

Enable the module by editing `runner/config/aiplayerbot.conf`:

```ini
AiPlayerbot.Enabled = 1
```

By default, random bots will not auto-login. To populate your server with roaming bots:

```ini
AiPlayerbot.RandomBotAutologin = 1
```

:::: warning Database requirement
PlayerBots requires additional database tables. If you initialized your database before enabling this module, you will need to update it. Use the interactive database manager:

::: code-group

```sh [All platforms]
docker compose run --rm builder manage-db
```

```sh [*nix shortcut]
./builder/run.sh manage-db
```

:::

Then follow the PlayerBots database installation prompts.
::::

::: tip Fine-tuning bot behavior
The full list of PlayerBots settings is extensive.  
For the complete reference, see the upstream configuration files in the [cmangos/playerbots](https://github.com/cmangos/playerbots) repository:

- [aiplayerbot.conf.dist.in](https://github.com/cmangos/playerbots/blob/master/playerbot/aiplayerbot.conf.dist.in) (Classic)
- [aiplayerbot.conf.dist.in.tbc](https://github.com/cmangos/playerbots/blob/master/playerbot/aiplayerbot.conf.dist.in.tbc) (TBC)
- [aiplayerbot.conf.dist.in.wotlk](https://github.com/cmangos/playerbots/blob/master/playerbot/aiplayerbot.conf.dist.in.wotlk) (WotLK)
:::

### Auction House Bot

The Auction House Bot automatically posts and buys auctions, keeping the economy alive even when few players are online.

Enable it by editing `runner/config/ahbot.conf`:

```ini
AhBot.Enabled = 1
AuctionHouseBot.Seller.Enabled = 1
AuctionHouseBot.Buyer.Enabled = 1
```

You can enable just the seller, just the buyer or both.  
The bot will use default pricing and item selection unless you customize further.

::: tip Balancing the economy
The full configuration reference covers item quality weights, pricing multipliers and faction-specific behavior.  
Copy the relevant defaults from the upstream [ahbot.conf.dist.in](https://github.com/cmangos/playerbots/blob/master/ahbot/ahbot.conf.dist.in) file and tune the values in `runner/config/ahbot.conf`.
:::

### AntiCheat

The AntiCheat module monitors player behavior for speed hacking, teleport exploitation and spam.

Enable it by editing `runner/config/anticheat.conf`:

```ini
Enable = 1
Movement.SpeedHack.Enable = 1
Movement.BadFallReset.Enable = 1
Antispam.Enable = 1
Warden.Enable = 1
```

Each check can be toggled independently.  
Warden is Blizzard's anti-cheat scanner; enabling it may cause compatibility issues with some client modifications.

::: warning False positives
AntiCheat systems can occasionally flag legitimate behavior — especially on laggy connections or with unusual movement abilities.  
Monitor your logs after enabling it and adjust thresholds if needed.
:::

## World modifications

For deeper changes — custom NPCs, modified loot tables, new quests or event scheduling — you will work directly with the database.  
These changes are made through SQL queries or scripts.

### Where to make changes

World data lives in the `{expansion}mangos` database.  
Common tables include:

| Table | What it controls |
|-------|------------------|
| `creature` | NPC spawns, positions and basic stats |
| `creature_template` | NPC definitions, models and default behavior |
| `item_template` | Item stats, icons and drop behavior |
| `quest_template` | Quest text, objectives and rewards |
| `gameobject` | Object spawns (chests, doors, mining nodes) |
| `creature_loot_template` | What NPCs drop on death |
| `game_event` | In-game events and their schedules |

::: tip Getting started with SQL
If you are new to database editing, start with the [Database Management](/guide/database-management) guide.  
Use phpMyAdmin for a graphical interface or the MariaDB CLI for scripted changes.
:::

::: warning Backup first
Always create a [backup](/guide/database-management#creating-a-backup) before running bulk UPDATE or DELETE queries.  
A single misplaced `WHERE` clause can break your world data.
:::

### Applying custom content packs

Many CMaNGOS community members share SQL patches that add new content.  
To apply one:

::: code-group

```sh [docker compose]
docker compose run --rm -T builder bash -c \
    'mariadb -h"${MANGOS_DBHOST}" -u"${MYSQL_SUPERUSER}" -p"${MYSQL_SUPERPASS}" classicmangos' < my-custom-patch.sql
```

```sh [*nix shortcut]
./builder/run.sh bash -c \
    'mariadb -h"${MANGOS_DBHOST}" -u"${MYSQL_SUPERUSER}" -p"${MYSQL_SUPERPASS}" classicmangos' < my-custom-patch.sql
```

:::

Replace `classicmangos` with your expansion's world database name and `my-custom-patch.sql` with the path to your patch file.  
See [Database Management — Querying databases](/guide/database-management#querying-databases) for more details on running SQL against your server.

### Scheduling in-game events

The `game_event` table controls seasonal events, world bosses and holiday activities.  
Each event has a `start_time` and `end_time` (datetime values delimiting when it can occur at all), plus `occurence` and `length` (both in **minutes**) that make it repeat periodically within that window.

To list the defined events:

```sql
SELECT entry, description, start_time, end_time, occurence, length
FROM game_event;
```

Events are activated automatically by the server based on those timings — there is no "active" switch in the table.  
To force one on or off right away, use the [server console](/guide/server-administration#the-cmangos-console) instead:

```
event list       -- list events and their state
event 1          -- show details about event 1
event start 1    -- force-start event 1
event stop 1     -- force-stop event 1
```

Connected players may need to relog or move to a new zone to see updates.

## Applying changes

Most configuration changes require a server restart:

```sh
docker compose down
docker compose up -d
```

Database changes (SQL queries, event updates) take effect immediately and do not require a restart.
