# Installing Updates

::: warning Work in Progress
This page is currently under construction and may be incomplete.
:::

CMaNGOS Docker images are built and published nightly, incorporating the latest changes from the CMaNGOS project.  
This guide explains how to update your server to the latest version.

::: danger Always backup first!
Before installing any updates, **always** create a [backup](/guide/database-management#creating-a-backup) of your databases.  
Updates can occasionally cause issues, and having a recent backup ensures you can recover your data.
:::

## Update process

Updating your CMaNGOS Docker installation involves three steps:

1. Update your local project files (if needed)
2. Pull the latest Docker images
3. Update the database schema

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

Download the latest Docker images:

```sh
docker compose pull
```

This command will download any updated images for all services defined in your `docker-compose.yml`.

### Step 3: Update the database

After pulling new images, you may need to apply database schema updates:

```sh
./builder/run.sh update-db
```

This command applies any pending database migrations without destroying your existing data.

::: warning World database updates
Some updates may require a full world database reload. If prompted, or if you experience issues after updating, you can perform a full world database update:

```sh
./builder/run.sh update-db --world
```

**Note:** This will reset world data to defaults but preserves character data.
:::

## Restarting after updates

After completing all update steps, restart your server:

```sh
docker compose down
docker compose up -d
```

## Checking versions

To see which version of CMaNGOS your images were built from, you can inspect the image labels:

```sh
docker inspect ghcr.io/byloth/cmangos/{version}:latest --format='{{.Config.Labels}}'
```

Replace `{version}` with your expansion keyword (`classic`, `tbc`, or `wotlk`).

## Rollback

If an update causes problems, you can roll back to a previous version:

1. Restore your database backup
2. Pull a specific dated image tag:

```sh
docker pull ghcr.io/byloth/cmangos/{version}:2024-01-14
```

Replace `{version}` with your expansion keyword (`classic`, `tbc`, or `wotlk`).

3. Update your `docker-compose.yml` to use the specific tag instead of `latest`
4. Restart the server
