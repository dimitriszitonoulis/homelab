# Homelab

## Contents

This repository contains the configuration for my homelab
along with guides on how each service works.

## How to run

Clone the repository with the command:

```bash
git clone https://github.com/dimitriszitonoulis/homelab.git
```

Install the docker engine and run:

- For mac, windows

```bash
docker compose up -d
```

- linux

```bash
sudo docker compose up -d
```

### Notes

Some of the services have sensitive info which I have hidden in
a `.env` file.

I have uploaded a fake `.env` to show what the file
should look like.

In order to completely replicate my setup you will need to
create a `.env` file in the same directory the `docker-compose.yml`
is saved. You will also need to provide the appropriate value for
each variable in the `.env` file.

For this reason, I highly recommend to read the guide for each service
as well as the official documentation to understand how it works.
