<h1 align="center">
  CMaNGOS running on Docker ⚔
</h1>

<div align="center">
  <strong>Continued Massive Network Game Object Server</strong><br />
  <sub>A collection of Docker images ready-to-use to host your emulated private server for WoW wherever you want.</sub>
</div>

<div align="center">
  <a href="https://github.com/Byloth/cmangos-docker/actions/workflows/build-classic.yml"
     title="Build Classic"
    ><img src="https://github.com/Byloth/cmangos-docker/actions/workflows/build-classic.yml/badge.svg"
          alt="Build Classic Badge" /></a>
  <a href="https://github.com/Byloth/cmangos-docker/actions/workflows/build-tbc.yml"
     title="Build TBC"
    ><img src="https://github.com/Byloth/cmangos-docker/actions/workflows/build-tbc.yml/badge.svg"
          alt="Build TBC Badge" /></a>
  <a href="https://github.com/Byloth/cmangos-docker/actions/workflows/build-wotlk.yml"
     title="Build WotLK"
    ><img src="https://github.com/Byloth/cmangos-docker/actions/workflows/build-wotlk.yml/badge.svg"
          alt="Build WotLK Badge" /></a>
</div>

<h3 align="center">
  <a href="https://github.com/Byloth?tab=packages&repo_name=cmangos-docker"
     title="CMaNGOS Docker images"
    >Docker images</a>
  <span> | </span>
  <a href="https://github.com/Byloth/cmangos-docker/wiki"
     title="CMaNGOS Docker Wiki"
    >Wiki</a>
  <span> | </span>
  <a href="https://github.com/Byloth/cmangos-docker/issues/new/choose"
     title="CMaNGOS Docker Support"
    >Support</a>
  <span> | </span>
  <a href="https://github.com/Byloth/cmangos-docker/projects"
     title="CMaNGOS Docker Roadmap"
    >Roadmap</a>
</h3>

<div align="center">
  <strong>External links to the CMaNGOS official project</strong><br />
  <sup>
    <a href="https://cmangos.net/"
       title="CMaNGOS - Continued Massive Network Game Object Server"
      >Website</a>
    <span> | </span>
    <a href="https://github.com/cmangos"
       title="CMaNGOS on GitHub"
      >GitHub</a>
    <span> | </span>
    <a href="https://discord.gg/Dgzerzb"
       title="CMaNGOS on Discord"
      >Discord</a>
    <span> | </span>
    <a href="https://github.com/cmangos/issues/wiki"
       title="CMaNGOS Documentation"
      >Documentation</a>
    <span> | </span>
    <a href="https://github.com/cmangos/issues/issues/new/choose"
       title="CMaNGOS Support"
      >Help</a>
  </sup>
</div>

---

## Summary

- [Requirements](#requirements)
- [Getting Started](#getting-started)
    - [Building all the required images](#building-all-the-required-images)
    - [Extracting files from the WoW client](#extracting-files-from-the-wow-client)
    - [Managing the database](#managing-the-database)
        - [Initializing the database](#initializing-the-database)
        - [Backing up the database](#backing-up-the-database)
        - [Restoring the database](#restoring-the-database)
        - [Updating the database](#updating-the-database)
    - [Run the server](#run-the-server)
    - [Creating a new account](#creating-a-new-account)
        - [Enabling expansion for an account](#enabling-expansion-for-an-account)
        - [Setting GM level for an account](#setting-gm-level-for-an-account)
    - [Stopping the server](#stopping-the-server)

## Requirements

`# TODO: Decently document the requirements...`

## Getting Started

All has been built aim to be as simple as possible.  
That's why, just following this few steps you'll be able to
run your CMaNGOS server without need any further configuration.

### Building all the required images

This may take a while, depending on your computer performance and your internet connection.  
Please be patient.

```sh
./build.sh --target all
```

### Extracting files from the WoW client

Make sure you've already created your enviroment file in
the root of this project with the following content:

```sh
# .env
#

WOW_CLIENT_DIR="</path/to/your/wow/client>"
```

Then, simply run the following command, follow the instructions and wait:

```sh
cd builder/
./run.sh extract
```

### Managing the database

#### Initializing the database

`# TODO: Write a decent description for here on...`

```bash
docker-compose up mariadb
```

```bash
cd builder/
./run.sh init-db
```

#### Backing up the database

```bash
docker-compose up mariadb
```

```bash
cd builder/
./run.sh backup-db --all > cmangos-backup.tar.gz
```

#### Restoring the database

```bash
docker-compose up mariadb
```

```bash
cd builder/
./run.sh restore-db < cmangos-backup.tar.gz
```
#### Updating the database

```bash
docker-compose up mariadb
```

```bash
cd builder/
./run.sh update-db
```

### Run the server

```bash
./run-server.sh
```

### Creating a new account

```
account create [username] [password]
```

#### Enabling expansion for an account

```
account set addon [username] [0 to 1]
```

0. Basic version
1. The Burning Crusade
2. Wrath of the Lich King

#### Setting GM level for an account

```
account set gmlevel [username] [0 to 3]
```

0. Player
1. Moderator
2. Game Master
3. Administrator

### Stopping the server

```
.server shutdown [delay]
```

`delay`: number of seconds
