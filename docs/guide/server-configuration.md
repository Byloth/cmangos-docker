# Server Configuration

This guide covers how to configure your CMaNGOS server, from basic settings like experience rates to advanced realm configuration.

## How configuration works

CMaNGOS Docker uses a **configuration override** system.  
The container includes default configuration files and you only need to specify the values you want to change.

Your custom settings go in files located in the `runner/config/` directory:

| File | Purpose |
|------|---------|
| `mangosd.conf` | World server settings (gameplay, rates, features) |
| `realmd.conf` | Login server settings (authentication, security) |
| `ahbot.conf` | [Auction House Bot](/guide/customization#auction-house-bot) settings |
| `aiplayerbot.conf` | [PlayerBots](/guide/customization#playerbots) settings |
| `anticheat.conf` | [AntiCheat](/guide/customization#anticheat) settings |

Every time a container starts, its entrypoint copies the default `<file>.dist` shipped in the image and applies each `Property = value` line of your file on top of it: the matching line is replaced, or the property is appended if the `.dist` file doesn't have it.

::: tip Override principle
You don't need to copy the entire default configuration.  
Just add the specific properties you want to change; all other settings keep the defaults of the `.dist` file.
:::

::: warning Every file needs its `.dist`
`ahbot.conf`, `aiplayerbot.conf` and `anticheat.conf` are optional: if you delete one, the entrypoint simply skips it.  
But a file in `runner/config/` must match a `.dist` file in the image: if the image has no `<file>.dist` for it, the container stops with an error.
:::

### What the shipped files set

The files in `runner/config/` are not empty: out of the box, they set these values.

| File | Settings |
|------|----------|
| `mangosd.conf` | `GameType = 0`, `RealmZone = 8`, `RabbitDay = 954547200`, `Motd = "Welcome to Azeroth!"` |
| `realmd.conf` | None (comments only) |
| `ahbot.conf` | `AhBot.Enabled = 1`, `AuctionHouseBot.Seller.Enabled = 0`, `AuctionHouseBot.Buyer.Enabled = 0` |
| `aiplayerbot.conf` | `AiPlayerbot.Enabled = 1`, `AiPlayerbot.RandomBotAutologin = 0`, `AiPlayerbot.MinRandomBots = 200`, `AiPlayerbot.MaxRandomBots = 200`, `AiPlayerbot.RandomBotLoginAtStartup = 0`, `AiPlayerbot.RandomBotsMaxLoginsPerInterval = 5` (read the [PlayerBots](/guide/customization#playerbots) warning before changing it) |
| `anticheat.conf` | `Enable = 0`, `Movement.SpeedHack.Enable = 0`, `Movement.BadFallReset.Enable = 0`, `Antispam.Enable = 0`, `Warden.Enable = 0` |

Change or remove any of them like any other setting.

## World server configuration

Edit `runner/config/mangosd.conf` to customize gameplay settings.

### Basic syntax

Each setting is a key-value pair:

```ini
PropertyName = value
```

**Example:**
```ini
GameType = 1
Rate.XP.Kill = 2
Motd = "Welcome to my server!"
```

### Common settings

#### Server type

| Property | Default | Description |
|----------|---------|-------------|
| `GameType` | `0` | Server type displayed in realm list |
| `RealmZone` | `1` (the shipped `mangosd.conf` sets `8`) | Timezone/region for the realm |

**GameType values:**
- `0` — Normal (PvE)
- `1` — PvP
- `4` — Normal (with contested zones)
- `6` — RP (Roleplay)
- `8` — RP-PvP

#### Experience and progression

| Property | Default | Description |
|----------|---------|-------------|
| `Rate.XP.Kill` | `1` | XP multiplier for killing mobs |
| `Rate.XP.Quest` | `1` | XP multiplier for quests |
| `Rate.XP.Explore` | `1` | XP multiplier for exploration |
| `Rate.Rest.InGame` | `1` | Rest XP accumulation rate |
| `MaxPlayerLevel` | `60/70/80` | Maximum character level |
| `StartPlayerLevel` | `1` | Starting level for new characters |

**Example — 3x XP server:**
```ini
Rate.XP.Kill = 3
Rate.XP.Quest = 3
Rate.XP.Explore = 3
```

#### Loot and economy

| Property | Default | Description |
|----------|---------|-------------|
| `Rate.Drop.Item.Normal` | `1` | Drop rate for regular items |
| `Rate.Drop.Item.Uncommon` | `1` | Drop rate for uncommon (green) items |
| `Rate.Drop.Item.Rare` | `1` | Drop rate for rare (blue) items |
| `Rate.Drop.Item.Epic` | `1` | Drop rate for epic (purple) items |
| `Rate.Drop.Money` | `1` | Gold drop rate |
| `StartPlayerMoney` | `0` | Starting gold (in copper) |

::: info Currency conversion
WoW currency is stored in copper. 1 gold = 100 silver = 10,000 copper.

To give new characters 10 gold: `StartPlayerMoney = 100000`
:::

#### Quality of life

| Property | Default | Description |
|----------|---------|-------------|
| `AllFlightPaths` | `0` | `1` = All flight paths unlocked |
| `InstantFlightPaths` | `0` | `1` = Instant travel (no flight animation) |
| `InstantLogout` | `0` | `1` = Instant logout anywhere |
| `AlwaysMaxSkillForLevel` | `0` | `1` = Auto-max weapon skills |

#### Server messages

| Property | Default | Description |
|----------|---------|-------------|
| `Motd` | `"Welcome to Azeroth!"` (set by the shipped `mangosd.conf`) | Message of the Day shown on login |

**Example:**
```ini
Motd = "Welcome to Azeroth! Type .help for commands."
```

::: tip Complete reference
For all available settings, see the official CMaNGOS configuration files:

- [Classic mangosd.conf.dist](https://github.com/cmangos/mangos-classic/blob/master/src/mangosd/mangosd.conf.dist.in)
- [TBC mangosd.conf.dist](https://github.com/cmangos/mangos-tbc/blob/master/src/mangosd/mangosd.conf.dist.in)
- [WotLK mangosd.conf.dist](https://github.com/cmangos/mangos-wotlk/blob/master/src/mangosd/mangosd.conf.dist.in)
:::

## Login server configuration

Edit `runner/config/realmd.conf` to customize authentication and security settings.

### Security settings

| Property | Default | Description |
|----------|---------|-------------|
| `WrongPass.MaxCount` | `0` | Max failed login attempts (`0` = unlimited) |
| `WrongPass.BanTime` | `600` | Ban duration in seconds after max failures |
| `WrongPass.BanType` | `0` | `0` = Ban IP, `1` = Ban account |
| `MaxPingTime` | `30` | Minutes between two pings to the database |

**Example — Ban IP for 1 hour after 5 failed attempts:**
```ini
WrongPass.MaxCount = 5
WrongPass.BanTime = 3600
WrongPass.BanType = 0
```

## Realm configuration

The realm configuration tells the game client where to connect and what type of server it is.  
This information is stored in the `realmlist` table of the `{expansion}realmd` database (e.g. `tbcrealmd`).

### Default configuration

CMaNGOS creates a default realm entry that works for local (same-machine) connections:

| Field | Default value |
|-------|---------------|
| name | MaNGOS |
| address | 127.0.0.1 |
| port | 8085 |

### When to modify

You need to modify the realm configuration if:

- Players connect from **other computers** on your network
- Players connect **over the internet**
- You want to **customize the realm name**
- The client gets stuck in a **realm selection loop**

### Updating realm settings

First, ensure the database is running:

```sh
docker compose up mariadb -d
```

Then update the default realm entry with these SQL queries:

```sql
-- Select your realm database (replace "tbc" with your expansion keyword)
USE tbcrealmd;

-- Update the default entry
UPDATE realmlist
SET name = 'My Server', address = '192.168.1.100', port = 8085
WHERE id = 1;
```

::: tip Running queries
See [Database Management — Querying databases](/guide/database-management#querying-databases) for instructions.
:::

### Realm table fields

| Field | Description | Common values |
|-------|-------------|---------------|
| `id` | Unique realm identifier | Usually `1` for single-realm setups |
| `name` | Realm name shown in client | Any string |
| `address` | Server IP address | `127.0.0.1` (local), LAN IP or public IP |
| `port` | World server port | `8085` (default) |
| `icon` | Realm type icon | `0`=Normal, `1`=PvP, `4`=Normal, `6`=RP, `8`=RP-PvP |
| `realmflags` | Status flags | `0`=Online, `2`=Offline |
| `timezone` | Timezone category | `1`=Development, `2`=United States, `6`=Korea, `8`=English, etc. |
| `allowedSecurityLevel` | Minimum GM level to connect | `0`=Everyone, `1`+=Staff only |

::: info `icon` and `timezone` follow `mangosd.conf`
Every time it starts, mangosd overwrites `icon` and `timezone` of its realm with the [`GameType` and `RealmZone`](#server-type) values from `mangosd.conf` (the `timezone` values are the same as `RealmZone`'s).  
To change them, edit those settings instead of the table.
:::

### Common scenarios

#### Local play only

For playing on the same computer:

```sql
UPDATE realmlist
SET name = 'Local Server', address = '127.0.0.1', port = 8085
WHERE id = 1;
```

#### LAN play

For playing with others on your local network, use your computer's LAN IP:

```sql
UPDATE realmlist
SET name = 'LAN Server', address = '192.168.1.100', port = 8085
WHERE id = 1;
```

::: tip Finding your LAN IP
- **Windows:** Run `ipconfig` in Command Prompt
- **macOS/Linux:** Run `ip addr` or `ifconfig` in Terminal

Look for an address like `192.168.x.x` or `10.0.x.x`.
:::

#### Internet play

For public internet access, use your public IP or domain name:

```sql
UPDATE realmlist
SET name = 'My Public Server', address = 'wow.example.com', port = 8085
WHERE id = 1;
```

::: warning Port forwarding required
For internet play, you must configure your router to forward these ports:
- **3724** — Login server (realmd)
- **8085** — World server (mangosd)

The setup process varies by router. Search for "port forwarding" + your router model.
:::

::: info Custom ports
If you changed the published ports with `REALMD_PORT` or `MANGOSD_PORT` in your `.env` file, forward those instead, and:

- with a custom `MANGOSD_PORT`, set the same value in the `port` field of the `realmlist` table;
- with a custom `REALMD_PORT`, add it to the client's `realmlist.wtf`, e.g. `set realmlist 192.168.1.100:3725`.
:::

### Troubleshooting realm issues

#### Client stuck in realm selection loop

This is the most common realm configuration issue.  
The client connects to the login server, sees the realm, but can't connect to the world server.

**Causes and solutions:**

1. **Wrong address in realmlist table**
   - Check that the `address` field matches where players connect from
   - For LAN play, use the server's LAN IP, not `127.0.0.1`

2. **World server not running**
   - Check that both `realmd` and `mangosd` containers are running
   - Run `docker compose ps` to verify

3. **Firewall blocking connections**
   - Ensure ports 3724 and 8085 are open
   - Temporarily disable firewall to test

#### "Unable to connect"

- Verify the realm `address` is reachable from the client
- Check that the correct ports are open/forwarded
- Ensure `realmlist.wtf` in the client points to the correct login server

## Applying configuration changes

Configuration files are read at startup, so a restart is required for changes to take effect.  
After modifying them, restart the two servers:

```sh
docker compose restart mangosd realmd
```

Each container rebuilds its configuration from your files every time it starts, so there's no need to recreate it.

::: tip Database changes
Changes to the `realmlist` table take effect immediately — no server restart needed. Players may need to re-login to see updated realm information.
:::
