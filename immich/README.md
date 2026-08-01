# Immich

## Description

Immich is an app used to manage and sync photos
similar to google photos.

## Transfer photos from google photos

### Get your photos

You will first need to download all your photos from google photos.
Google will send you a link from which you can download zip files that
contain all your photos.

Store all of the zip files inside a file with the name `takeout`.

### Immich go

To transfer photos from google photos use [immich-go](https://github.com/simulot/immich-go).

### Unzip all the files

Go inside the directory where all the zip files are saved

```bash
cd /path/to/takeout
```

Unzip all the zip files with the command:

```bash
unzip *.zip -d .
```

This will create a directory with the name `./Takeout/Google Photos`.

### Create a user api key

You will need to create an api key from your user account
(Account Settings>API Keys).

Check
[installation.md](https://github.com/simulot/immich-go/blob/main/docs/installation.md#api-permissions)
at immich-go about which permissions the api key should grant.

> [!NOTE]
> The api key will only be shown once,
> Save it somewhere temporarily because it is needed for a
> command later.

### Copy command

Use the following command:

```bash
sudo ./immich-go upload from-google-photos \
--server=http://<server port>:<server port> \
--api-key=<api key> \
/path/to/takeout/Takeout/Google\ Photos/ --dry-run
```

If this command succeeds with no errors,
run it again without the `--dry-run` flag.

```bash
sudo ./immich-go upload from-google-photos \
--server=http://<server port>:<server port> \
--api-key=<api key> \
/path/to/takeout/Takeout/Google\ Photos/
```

> [!NOTE]
> When copying files do not hide immich behind a reverse proxy.
> Immich-go uses hardcoded http paths of the immich api
> which will not work when the reverse proxy changes them
> (ex when changing http to https).
> Instead bind the default port that immich uses (default is 2283)
> to a port of your server (ex 2283).
> Then link to use will be: http://<server port>:2283.
