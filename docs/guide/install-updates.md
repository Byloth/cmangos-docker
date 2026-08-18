# Installing Updates

CMaNGOS Docker images are built and published nightly, incorporating the latest changes from the CMaNGOS project.  
This guide explains how to update your server to the latest version safely.

::: danger Always backup first!
Before installing any updates, **always** create a [backup](/guide/database-management#creating-a-backup) of your databases.  
Updates can occasionally cause issues and having a recent backup ensures you can recover your data.
:::

## Update process

Updating your CMaNGOS Docker installation involves four steps:

1. Update your local project files (if needed)
2. Pull the latest Docker images
3. Update the database schema
4. Restart the server

### Step 1: Update project files

If there have been changes to the `docker-compose.yml` file or other configuration files, you'll need to update your local copy.

If you cloned the repository with Git:

```sh
git pull origin master
```

If you downloaded the ZIP archive, download the latest version and carefully merge any changes with your existing files, being careful not to overwrite your customizations.

::: tip Check the changelog
Before updating, check the [releases page](https://github.com/Byloth/cmangos-docker/releases) or commit history for any breaking changes that might require additional steps.
:::

### Step 2: Pull latest Docker images

Download the latest Docker images for all services:

```sh
docker compose --profile builder pull
```

::: warning Don't forget the builder
The builder service sits behind the `builder` profile, so a plain `docker compose pull` will **not** update it.  
Running an outdated builder against updated runners can cause database schema mismatches — always include `--profile builder` when pulling.
:::

### Step 3: Update the database

After pulling new images, apply any pending database schema updates:

::: code-group

```sh [All platforms]
docker compose run --rm builder update-db
```

```sh [*nix shortcut]
./builder/run.sh update-db
```

:::

This command applies the latest structure and data changes without destroying your existing character or world customizations.

:::: warning World database updates
Some updates may require a full world database reload.  
If prompted or if you experience issues after updating, you can perform a deeper world database update:

::: code-group

```sh [All platforms]
docker compose run --rm builder update-db --world
```

```sh [*nix shortcut]
./builder/run.sh update-db --world
```

:::

**Note:** This will reset world data to the latest defaults; any custom NPCs, loot tables or quest modifications you may have made manually will be overwritten!  
Don't worry, though: characters data and users progress are preserved.
::::

### Step 4: Restart the server

After completing all update steps, restart your server:

```sh
docker compose down
docker compose up -d
```

## Checking versions

To see which version of CMaNGOS your images were built from, inspect the image labels:

```sh
# Runner image
docker inspect ghcr.io/byloth/cmangos/{version}:latest --format='{{index .Config.Labels "net.cmangos.mangos-{version}.revision"}}'

# Builder image
docker inspect ghcr.io/byloth/cmangos/{version}/builder:latest --format='{{index .Config.Labels "net.cmangos.mangos-{version}.revision"}}'
```

As always, replace `{version}` with your expansion keyword (`classic`, `tbc` or `wotlk`).

The output is the upstream CMaNGOS commit SHA that the image was built from.  
You can compare it with the [upstream repository](https://github.com/cmangos) to see how current your installation is.

## Rollback

If an update causes problems, you can roll back to a previous version:

1. [Restore](/guide/database-management#restoring-a-backup) your database from the backup you created before updating.

2. Pin a specific dated image tag.  
   Nightly builds are tagged with their build date (`YYYY-MM-DD`) and the `CMANGOS_VERSION` variable in your `.env` file selects which tag to use — for the runner **and** the builder alike:
   ```ini
   # Example: rollback to the build from 18 August 2026
   CMANGOS_VERSION="2026-08-18"
   ```

3. Pull the pinned images and restart the server:
   ```sh
   docker compose --profile builder pull
   docker compose down
   docker compose up -d
   ```

When you're ready to move back to the latest version, remove the `CMANGOS_VERSION` line from your `.env` file (or set it back to `latest`) and repeat step 3.
