# Nextcloud aio

Nextcloud all in one (nextcloud-AIO) is a container
that bundles together apps from the nextcloud suite.

## Specifications

- Nginx runs in a container as a reverse proxy
- Certbot runs in a container and issues certificates through the DNS-01 challenge.

Things can be configured to run with a different reverse proxy
or with nginx running locally.
Certbot can also run locally.
However, the configuration for those cases is not handled here.

## Initial deployment

### Docker compose file

Check out the
[official docker compose file](https://github.com/nextcloud/all-in-one/blob/main/compose.yaml)
for the nextcloud AIO instance.

Example file for using `nextcloud` with `reverse proxy`:

```yaml
networks:
  proxy_net:
    name: proxy_net
    driver: bridge
services:
    nextcloud-AIO-mastercontainer:
        container_name: nextcloud-AIO-mastercontainer
        image: ghcr.io/nextcloud-releases/all-in-one:latest
        networks:
            proxy_net:
        init: true
        restart: unless-stopped
        volumes:
          - nextcloud_AIO_mastercontainer:/mnt/docker-AIO-config 
          - /var/run/docker.sock:/var/run/docker.sock:ro
        ports:
            - 8080:8080 
        environment:
          APACHE_PORT: 11000 
          APACHE_IP_BINDING: 0.0.0.0
          APACHE_ADDITIONAL_NETWORK: proxy_net
          NEXTCLOUD_DATADIR: /mnt/lv_data/nextcloud
          NEXTCLOUD_UPLOAD_LIMIT: 1024G
          NEXTCLOUD_MEMORY_LIMIT: 1024M
          SKIP_DOMAIN_VALIDATION: false
volumes:
    nextcloud_AIO_mastercontainer:
        name: nextcloud_AIO_mastercontainer
```

A lot of the settings cannot be changed. Refer to the documentation for more info.

#### External drive

With `NEXTCLOUD_MOUNT`   you can use an external drive to save `nextcloud` data.
For the above `docker-compose.yml` you must create the folder `/mnt/lv_data/nextcloud`.

To do that run:

```bash
sudo chmod -R 750 /mnt/my_share
```

#### proxy_net

The `proxy_net` is a docker network used by the reverse proxy to access containers.

#### DNS with local server

See:

- step 4 from [running a local instance](https://github.com/nextcloud/all-in-one/blob/main/local-instance.md):
- [docker daemon](https://docs.docker.com/engine/daemon/)
- [docker daemon options](https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file)

Enter the ip-address of your local dns-server in the `daemon.json` file
for docker so that that all docker containers use the correct local dns-server.

Edit `/etc/docker/daemon.json`:

```bash
{
  "dns": ["<local_dns_server_ip>", "<back_up_server_ip>"]
}
```

Example:

```bash
{
  "dns": ["192.168.123.123", "1.1.1.1"]
}
```

If the local dns server is also a docker container (ex `pihole`)
other containers might not be able to run because they make requests to a server
that does not exist yet
(if `pihole` hasn't started at the same time as the other containers).
This is why a **backup server** is specified.

#### Deployment

Run `docker compose up -d`.

Open a browser and visit the nextcloud AIO container
with the **IP** of the server that hosts the AIO instance
on port 8080 (not the IP of the container on the docker network).

Example: `https://192.168.123.123:8080`

The AIO interface is served via https with a self signed certificate.
It must be accepted in the browser.

A passphrase is given (save it).
It is requested in the next step to login to the AIO interface.

### Domain

After the login to the AIO interface,
a domain must be specified for the nextcloud instance.

This domain is used for the **nextcloud-aio-apache**
which runs an apache server,
hosted on port 11000 of the  container.
It is used to access the nextcloud instance and will be created later
by the AIO mastercontainer (important for the reverse proxy config,
see [below](##Reverse proxy config).

On the initial setup if a local DNS server (like pihole) is used,
do not add a local A record for the nextcloud domain and server IP
(host server not container apache server).
If nextcloud sees that the domain corresponds
to a private IP address through a local DNS record,
it will mark the domain as insecure.
If the same (domain name correspoding to private IP)
happens through the DNS record of a domain registar,
nextcloud AIO accepts the domain.

#### DNS records

Create the following records for your domain in the domain registar.

| Type | Name | Content | Proxy status |
| --- | --- | --- | --- |
| A | @ | server local IP | DNS |
| CNAME | * | my_domain | DNS |

**Notes:**

1) The `@` at the `A` record means to use the root domain (`my_domain`)
2) The `*` at the `CNAME` record is used to create subdomains.

All the services live in containers in the same host,
so they share the host's IP address.
The are also accessible through subdomains with the help of a reverse proxy.
So, all subdomains should point to the same host
and then be handled by the reverse proxy.

#### Reverse proxy config

Add the following to the reverse proxy config.
This must be added after the initial login
(the one requiring the passphrase) is performed.

```nginx
server {
    ## check example config: 
    listen 443 ssl;
    http2 on;

    proxy_buffering off;
    proxy_request_buffering off;

    client_max_body_size 0; ## disable checks for body size
    client_body_buffer_size 512k;
    proxy_read_timeout 86400s;

    ssl_certificate /etc/letsencrypt/live/my_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/my_domain/privkey.pem;

    server_name nc.my_domain;

    location / {
        proxy_pass http://nextcloud-aio-apache:11000/;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Scheme $scheme;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header Early-Data $ssl_early_data;
     }
}
```

You can also check out:

- [Official reverse proxy config for nginx](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md)
- [My reverse proxy config for nginx](./nginx)

After adding, run:

```bash
sudo docker exec -it <reverse_proxy_container_name> nginx -s reload
```

**DO NOT RUN:**

```bash
sudo docker compose restart <reverse_proxy_container_name>
```

The apache container does not exist yet.
This means that the hostname **nextcloud-aio-apache** does not belong to any container.
With the `restart` command the reverse proxy sees a hostname
that does not exist and restarts.
After restarting it sees the same hostname
(but **nextcloud-aio-apache** still does not exist) so it restarts again.
The reverse proxy container has entered a restart loop.

### Nextcloud containers

Choose the containers that the master container must download
On the top of the page are the credentials for the admin account.
Wait until all the containers are installed and running (might take a while).

Login and configure nextcloud.

### If something goes wrong

All the nextcloud containers and their volumes must be deleted.

#### Remove containers

Assuming that there are no other containers that need to be running
Run:

```bash
sudo docker compose down
```

or

```bash
sudo docker compose down nextcloud-aio-mastercontainer
```

If the master container has managed to install other containers
they must be stopped and removed.

The following command stops and removes all containers
(regardless of whether or not they where created from the master container):

```bash
sudo docker stop $(sudo docker ps -a -q) && sudo docker rm $(sudo docker ps -a -q)
```

#### Remove volumes

Nextcloud automatically creates volumes stored in `/var/lib/docker`.

**DO NOT REMOVE THEM BY HAND**.
Instead run one of the following prune commands

To  remove all unused containers, networks,
images (both dangling and unreferenced), and volumes (shows confirmation prompt).

```bash
sudo docker system prune -f --all --volumes
```

 To forcefully remove (no confirmation prompt) all unused
 containers, networks, images (both dangling and unreferenced), and volumes.

```bash
sudo docker system prune -f --all --volumes
```

#### Remove certificates

Remove the accepted self signed certificate from your browser certificate.
It was created in [deployment step](#Deployment).

---
Sources:

1. [Nextcloud AIO github](https://github.com/nextcloud/all-in-one)
2. [Nextcloud docker compose](https://github.com/nextcloud/all-in-one/blob/main/compose.yaml)
3. [Nextcloud Under Reverse Proxy](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md)
4. [Nextcloud local instance](https://github.com/nextcloud/all-in-one/blob/main/local-instance.md)
