# Certbot

Certbot is a free, open-source tool from the EFF that automates
getting and installing SSL/TLS certificates from Let's Encrypt
to enable HTTPS on websites, making it easy to secure your site
with encrypted communication (HTTPS) without manual hassle.

## Specifications

- certbot will run in a container
- the certbot ***DNS-01 challenge* will be used
- nginx is running in a container as a reverse proxy

### DNS-01 challenge

This challenge asks you to prove that you control the DNS for your domain name
by putting a specific value in a TXT record under that domain name.

Benefits of the **DNS-01 challenge**:

- It allows you to issue wildcard certificates
(i.e it is easier to create certificates for subdomains)
- Your server does not need to be directly accessible to the internet
(you do not need to expose ports).

Certbot needs an API key from your registar in order to edit DNS records

#### On your server create the directories

```bash
mkdir -p ./certbot/etc/letsencrypt/live
mkdir -p ./certbot/cloudflare.ini
```

#### Example `docker-compose.yml` for certbot

```yaml
networks:
  proxy_net:
    name: proxy_net
    driver: bridge

services:
    reverse_proxy:
        container_name: reverse_proxy
        networks:
            proxy_net:
        image: nginx
        volumes:
          - ./nginx/nginx.conf:/etc/nginx/nginx.conf
          - ./nginx/conf.d:/etc/nginx/conf.d
          - ./nginx/templates:/etc/nginx/templates
          - ./nginx/error.log:/var/log/nginx/error.log
          - ./certbot/conf/:/etc/letsencrypt
          - ./certbot/www/:/var/www/certbot
        ports:
          - "80:80"
          - "443:443"
        # only needed for templates
        environment:
          - NGINX_HOST=localhost
          - NGINX_PORT=80
        restart: unless-stopped

# do not restart on failure
    certbot:
      container_name: certbot
      #  Cloudflare version able to use cloudflare's API, needed for DNS challenge
      image: certbot/dns-cloudflare
      volumes:
        - ./certbot/conf/:/etc/letsencrypt
        - ./certbot/cloudflare.ini:/cloudflare.ini
      command: certonly --keep-until-expiring --non-interactive --preferred-challenges dns --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini --dns-cloudflare-propagation-seconds 60 --email my_email -d "my_domain.com" -d "*.my_domain.com" --agree-tos
```

##### Notes

- When testing add the `--staging`  flag to the command.
Otherwise, if you make a lot of requests when testing you will be rate limited.
Check [staging environment](https://letsencrypt.org/docs/staging-environment/)
for the rate limits and
[certbot command line options](https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options)
for more details about certbot commands.
- For the certbot docker container do not put specify a `restart policy`.
The specified command gets a certificate (almost immediatelly) then exits.
This makes the container stop.
If a `restart policy` like `always` or `unless-stopped`
is specified the container is restarted,
executes the command then terminates again (infinite restart loop).

#### Provide certbot with your api key

I use cloudflare so I will use the
[certbot-dns-cloudflare](https://certbot-dns-cloudflare.readthedocs.io/en/stable/)
plugin.
Check [dns plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)
for the available certbot dns plugins.

For the `./certbot/cloudflare.ini` file:

```bash
chmod 600 cloudflare.ini
```

Add your API token inside the

```bash
# Cloudflare API token used by Certbot
dns_cloudflare_api_token = 0123456789abcdef0123456789abcdef01234567
```

## How to renew certificates

Run the container once to obtain a certificate then rerun it using a cron job.

## Always use https

Add the following to `nginx.conf`.

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name _;

  # redirect from http to https
    location / {
        return 301 https://$host$request_uri;
    }
}
```

This will redirect all `http` on `port 80` traffic to `https` on `port 443`.

---
Sources:

1. [Certbot with docker](https://eff-certbot.readthedocs.io/en/latest/install.html#running-with-docker)
2. [Manual certificates location](https://eff-certbot.readthedocs.io/en/latest/using.html#where-certs)
3. [ACME Challenge types](https://letsencrypt.org/docs/challenge-types/)
4. [Instructions for Cloudflare API with certbot](https://certbot-dns-cloudflare.readthedocs.io/en/stable/)
5. [Dns plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)
6. [Certbot staging](https://letsencrypt.org/docs/staging-environment/)
7. [Certbot commands](https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options)
