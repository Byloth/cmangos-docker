# [CMaNGOS](https://cmangos.net/) running on Docker ⚔

[![Build Classic](https://github.com/Byloth/cmangos-docker/actions/workflows/build-classic.yml/badge.svg)](https://github.com/Byloth/cmangos-docker/actions/workflows/build-classic.yml)
[![Build TBC](https://github.com/Byloth/cmangos-docker/actions/workflows/build-tbc.yml/badge.svg)](https://github.com/Byloth/cmangos-docker/actions/workflows/build-tbc.yml)
[![Build WotLK](https://github.com/Byloth/cmangos-docker/actions/workflows/build-wotlk.yml/badge.svg)](https://github.com/Byloth/cmangos-docker/actions/workflows/build-wotlk.yml)

A collection of Docker images ready-to-use to host your emulated private server for WoW wherever you want.

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
- [Roadmap](#roadmap)

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

## Roadmap

- [ ] Improve the whole documentation.
- [ ] Supporting correctly the database update process #3: `apply_core_update`.
- [ ] Adding the details of CMaNGOS and database version that generate the `.tar.gz` backup file right inside of it. 
- [ ] Adding as one or more specific Docker containers the application to easily manage the server, allowing new user to sign-up, view profiles, all player characters an so on...
- [ ] Solve the random issue with GitHub Actions: `API rate limit exceeded for...` ([📝 Here the docs](https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting))
