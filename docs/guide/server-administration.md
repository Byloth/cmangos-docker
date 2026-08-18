# Server Administration

This guide covers day-to-day server administration tasks: managing user accounts, assigning permissions and using the server console.

## The CMaNGOS console

The CMaNGOS server (`mangosd`) provides an interactive command-line interface for real-time server management.  
Through this console, you can create accounts, modify player data, broadcast messages and perform various administrative tasks.

### Accessing the console

While your server is running, open a new terminal and attach to the server container:

```sh
docker attach cmangos-mangosd-1
```

You'll now see a command prompt where you can type CMaNGOS commands.

::: danger Detaching safely
**DO NOT** press `Ctrl+C` to exit the console — this will **stop the entire server** and disconnect all players.

To safely detach from the console without stopping the server:
1. Press `Ctrl+P`
2. Then press `Ctrl+Q`

This key sequence detaches your terminal while leaving the server running.
:::

### Console commands overview

The console supports hundreds of commands for server management. Here are the most commonly used categories:

| Category | Example commands | Description |
|----------|------------------|-------------|
| Account | `account create`, `account set` | User account management |
| Server | `server info`, `server shutdown` | Server status and control |
| Player | `character rename`, `kick` | Player management |
| GM | `announce`, `notify` | Game Master tools |
| Debug | `debug`, `log` | Troubleshooting |

::: tip Getting help
Type `help` in the console to see all available commands or `help <command>` for details about a specific command.
:::

## Creating accounts

Before players can log into your server, they need a game account.

### Create a new account

In the CMaNGOS console, type:

```
account create {username} {password}
```

Replace `{username}` and `{password}` with the desired credentials.

**Example:**
```
account create john secretpass123
```

::: warning Password requirements
- Passwords are case-sensitive
- Avoid special characters that might cause issues with the client
- Players can change their password later using the `account set password` command
:::

### Account information

To view information about an existing account:

```
account {username}
```

This displays the account ID, expansion level, GM level and other details.

## Expansion access

Even if your server supports a specific expansion (like WotLK), you can control which expansion content each account can access.  
This mimics official servers where players must purchase expansions separately.

### Expansion levels

| Level | Access to | Max character level |
|-------|-----------|---------------------|
| `0` | Classic (Vanilla) only | 60 |
| `1` | Classic + The Burning Crusade | 70 |
| `2` | Classic + TBC + Wrath of the Lich King | 80 |

::: info Cumulative access
Higher levels include all previous content. Setting level `2` grants access to Classic, TBC and WotLK content.
:::

### Set expansion level

```
account set addon {username} {level}
```

**Examples:**
```
account set addon john 0    # Classic only
account set addon john 1    # Up to TBC
account set addon john 2    # Up to WotLK
```

## Game Master levels

Game Masters (GMs) are privileged users who can perform administrative actions in-game, such as teleporting players, spawning items or banning cheaters.

### GM permission levels

| Level | Role | Capabilities |
|-------|------|--------------|
| `0` | Player | Normal gameplay, no special permissions |
| `1` | Moderator | Can kick players, mute chat, view reports |
| `2` | Game Master | Can teleport, spawn NPCs/items, modify characters |
| `3` | Administrator | Full access to all commands, server management |

### Assign GM level

```
account set gmlevel {username} {level}
```

**Examples:**
```
account set gmlevel john 1    # Promote to Moderator
account set gmlevel john 3    # Promote to Administrator
account set gmlevel john 0    # Remove GM privileges
```

::: warning Security consideration
Only grant GM privileges to trusted individuals. Higher GM levels can significantly impact the game world and player experience. Consider starting new staff at level 1 and promoting gradually.
:::

## Common administrative tasks

### Broadcasting messages

Send a message to all online players:

```
announce Your message here
```

The message appears in the center of every player's screen.

For a less intrusive notification (chat window only):

```
notify Your message here
```

### Kicking players

Disconnect a player from the server:

```
kick {playername}
```

### Banning accounts

Temporarily ban an account:

```
ban account {username} {duration} {reason}
```

Duration format: `#d` for days, `#h` for hours, `#m` for minutes.

**Examples:**
```
ban account cheater 7d Using exploits
ban account spammer 24h Chat spam
```

To permanently ban:

```
ban account {username} 0 {reason}
```

To unban:

```
unban account {username}
```

### Server shutdown

Schedule a server shutdown (with warning to players):

```
server shutdown {seconds}
```

**Example:**
```
server shutdown 300    # Shutdown in 5 minutes
```

Players receive countdown warnings. To cancel a scheduled shutdown:

```
server shutdown cancel
```

For immediate shutdown (no warning):

```
server exit
```

## Managing accounts via database

For bulk operations or automated account management, you can directly modify the `realmd` database.

### Account table structure

The main account information is stored in the `account` table:

| Column | Description |
|--------|-------------|
| `id` | Unique account identifier |
| `username` | Login username |
| `gmlevel` | GM permission level (0-3) |
| `expansion` | Maximum expansion access (0-2) |
| `locked` | Whether account is locked |

### Example queries

**List all accounts:**
```sql
SELECT id, username, gmlevel, expansion FROM account;
```

**Find accounts by username pattern:**
```sql
SELECT * FROM account WHERE username LIKE 'john%';
```

**Bulk update expansion level:**
```sql
UPDATE account SET expansion = 2 WHERE expansion < 2;
```

::: tip Database access
See the [Database Management](/guide/database-management#querying-databases) guide for instructions on running SQL queries.
:::

## Troubleshooting

### "Account already exists"

The username is taken. Choose a different username or check if you're recreating an existing account.

### Player can't see certain content

Check the account's expansion level. If a player can't access Outland, their account might be set to expansion level 0 (Classic only).

### GM commands not working in-game

1. Verify the account has GM privileges: `account {username}`
2. Make sure the character is logged in with the correct account
3. Some commands require specific GM levels — check with `.help {command}`

### Players stuck in "realm selection" loop

This usually indicates a realmlist configuration issue. See [Realm Configuration](/guide/server-configuration#realm-configuration) for troubleshooting steps.
