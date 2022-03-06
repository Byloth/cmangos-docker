# CMaNGOS running on Docker

## Getting Started

All has been built aim to be as simple as possible.  
That's why, just following this few steps you'll be able to
run your CMaNGOS server without need any further configuration.

### Building all the required images

This may take a while, depending on your computer performance and your internet connection.  
Please be patient.

**CMaNGOS Builder**

```sh
cd builder/
./build.sh
```

**CMaNGOS Runner**

```sh
cd runner/
./build.sh
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

### Initializing the database

`# TODO: write a decent description for here on...`

```bash
docker-compose up mariadb
```

```bash
cd builder/
./run.sh init-db
```

### Backing up the database

```bash
docker-compose up mariadb
```

```bash
cd builder/
./exec.sh backup-db --all > cmangos-backup.tar.gz
```

### Restoring the database

```bash
docker-compose up mariadb
```

```bash
cd builder/
./exec.sh restore-db < cmangos-backup.tar.gz
```
### Updating the database

```bash
docker-compose up mariadb
```

```bash
cd builder/
./run.sh update-db
```

### Starting the server

```bash
docker-compose up
```

### Creating a new account

`mangosd`

```
account create [username] [password]
```

#### Enabling expansion for an account

```
account set addon [username] [0 to 1]
```

1. Basic version
2. The Burning Crusade


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
