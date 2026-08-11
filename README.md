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

```bash
./deploy.sh up
```

> [!WARNING]
> The script is meant to be used on linux machines.
> As such, it executes docker commands by running:
> `sudo docker`.
> If this script is run on windows,
> you should run it inside wsl.

### Configuration

Some of the services have sensitive info which I have hidden in
`.env` files.

In order to completely replicate my setup you will need to
create `.env` files for the configuration of each app.
The files should be placed in the same directory as the `docker-compose.yml`
of each app and one `.env` file must be placed at the
root directory of this project, because it is needed by the deployment script.

I have uploaded fake `.env` as examples.
However, as of now not all services have these example files.

For this reason, I highly recommend to read the guide for each service
as well as the official documentation to understand how it works.
