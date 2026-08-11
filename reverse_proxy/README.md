# Reverse Proxy

## Why use a reverse proxy?

### Multiple open ports

If a server is running multiple web services,
multiple ports of the server must be exposed.

#### Without reverse proxy

**Example config:**

**service1** will be bound to **server port 12345**
**service2** will be bound to **server port 12346**

**How to access:**

In order to visit the web pages of those services
a client would have to open a browser and search:
server_IP:12345/ -> for **service1**
server_IP:12346/ -> for **service2**
(The server's hostname can also be used instead of the server's IP address).

**Takeaway:**

As the number of services increases so does the number of exposed ports.
Notice that both services have the same IP (server_IP)
and are differentiated based on the port they use.

#### With reverse proxy

With a reverse proxy only **port 443**
(and optionally **port 80**) of the server need to be
open and bounded to the appropriate port (or ports) of the reverse proxy.
Then, the reverse proxy uses domain names to let the client access each service.
For this to work it is important to create **DNS A records**
that match the domain of the services to the IP address
of the server they are hosted on.

**Example config:**

The domain name for each service is specified
in the configuration file of the reverse proxy.

| domain name | service  |
| ----------- | -------- |
| s1.home     | service1 |
| s2.home     | service2 |

DNS A records:

| domain  | IP address   |
| ------- | ------------ |
| s1.home | 192.168.10.2 |
| s2.home | 192.168.10.2 |

Where 192.168.10.2 is the IP address
of the server where the services are hosted at.

**How to access:**

Τo access any of the services open a browser and search:
s1.home -> for **service1**
s2.home -> for **service2**

**Takeaway:**

This is both cleaner and safer than exposing multiple ports.
Now the services are differentiated using the hostname (s1.home or s2.home)
that is entered on the browser.
When the browser makes a request it sends that hostname
to the reverse proxy.
The reverse proxy uses that hostname to distinguish
between the services.

### Security

A server and its services can be on different networks
(server network and internal docker network)
with the reverse proxy acting as the middleman.
Because only the reverse proxy is reachable from the outside,
backend services can remain on an internal network.
This reduces the attack surface
since users cannot connect directly to those services.

### https

Reverse proxies are an easy way to use SSL certificates with
**LetsEncrypt** and **certbot** to use **https**
instead of **http** to access a web service.

## Nginx

### Specifications

- Nginx will run as a container.
- The nginx configuration will be split into multiple
  files, one file per proxied container.
- The nginx container will be on the same network as
  the proxied containers.

### Configuration

The way nginx and its modules work is determined in the configuration file.
By default, the configuration file is named `nginx.conf` and placed
in the directory `/usr/local/nginx/conf`, `/etc/nginx`, or `/usr/local/etc/nginx`.

A configuration can also be split up to multiple configuration files
(each config file should have the extension `.conf`).
To do that place the configuration files under `/etc/nginx/conf.d/` and include
everything under `/etc/nginx/conf.d/` in the main `http` block in `/etc/nginx/nginx.conf`.

You can include all files under `/etc/nginx/conf.d/` that end with `.conf`
with the following `inlcude` inside `/etc/nginx.conf`.

```nginx
http {
    include /etc/nginx/conf.d/*.conf;
}
```

Each file under `/etc/nginx/conf.d/` must contain a `server` block.

Check my configuration for more examples.

#### How to redirect

Specify a `location`, a URI for the server with hostname `server_name`.
All paths that match it will be redirected to `proxy_pass`.
After that nginx will get the response and send it back to the client.

> [!NOTE]
> When a client requests a service (ex s1.home),
> the browser includes that hostname in the HTTP Host header.
> Nginx uses the value of this header to choose
> the correct server block and forward the request to the matching service.

If a `server_name` is not specified in a `server` block,
it will act as a **default catch-all** and it will be used,
as long as there is not another block matching the `hostname`
in the `Host header`. Not specifying a `hostname` is equivalent to `server_name _;`

To use the device's hostname specify: `server_name $hostname;`

A `location` can be entered with:

- `path name` and all the paths that match it will be redirected to `proxy_pass`.
- `regular expression`. Regular expressions must be preceded with `~`.

From the Nginx [reverse proxy docs](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/#passing-a-request-to-a-proxied-server):
To pass a request to an HTTP proxied server, the `proxy_pass`
directive is specified inside a `location`.

For example:

```nginx
server {
  server_name _;

  location /some/path/ {
      proxy_pass http://www.example.com/link/;
  }
}
```

This example configuration results in passing all requests processed in
this location to the proxied server at the specified address.
This address can be specified as a domain name or an IP address.
The address may also include a port:

```nginx
server {
  server_name _;

  location ~ \.php {
      proxy_pass http://127.0.0.1:8000;
  }
}
```

Note that in the first example above,
the address of the proxied server is followed by a URI,
`/link/`.
If the URI is specified along with the address,
it replaces the part of the request URI that matches the location parameter.

For example,
the request with the `/some/path/page.html` URI will be proxied to
`http://www.example.com/link/page.html`.
However, if the address is specified without a URI,
or it is not possible to determine the part of URI to be replaced,
the full request URI is passed (possibly, modified).

### Containerization

All proxied containers should exist on the same docker network as the reverse proxy
so that they are able to communicate with each other.
It is a good idea to define a docker network and include
the proxied containers and the proxy (see the custom networks example below).

The reverse_proxy can redirect traffic from a host to a proxied container
using the proxied container's name thanks to the embedded dns server
of a docker network.

#### Redirection example

Redirecting from a specific host to a container can be done
by placing the following the `.conf` file for that
specific container (assumes that the `nginx` configuration
is split up into multiple files).

```nginx

server {
    server_name subdomain1.mydomain.com;
    location / {
        proxy_pass http://container1:3000;
    }
}

```

Check my `nginx` config for more examples.

#### Custom networks example

It is a good practice to create 2 networks:

- An internal network that contains all
  the proxied containers as well as the reverse proxy.
- An front facing network that contains only the reverse proxy
  and communicates with the outside world.

That way the proxy acts like the middleman between the
outside world and the containers.
Take note that for this setup to work all the containers should only be in the internal
network (as long as they do not need direct access to the outside world).

> [!NOTE]
> In my setup I have only one user defined network
> to which the containers and the reverse_proxy
> are connected.

Let's say we have 3 `docker-compose.yml` files.

- One defines the reverse_proxy ()
- One defines a proxied service (proxy.yml)
- One that defines the docker networks (service.yml)
  and includes the other 2 files (main-compose.yml)

File structure will be the following:

```bash
├── main.yml
├── service.yml
└── proxy.yml
```

`main.yml`:

```yaml
networks:
  backend_net:
    name: backend
    internal: true
  frontend_net:
    name: frontend_net
    external: false

include:
  - ./proxy.yml
  - ./service.yml
```

> [!NOTE]
> Here `external: true` means that network
> is defined in this file.
> It has nothing to do with whether the network
> can communicate with the outside world.

`proxy.yml`

```yaml
networks:
  backend_net:
    name: backend_net
    internal: true
```

The `docker-compose.yml` for every container should be like:

```yaml
networks:
  backend_net:
    external: true
  frontend_net:
    external: true

services:
  reverse_proxy:
    container_name: reverse_proxy
    networks:
      - frontend_net
      - backend_net
    ...
```

> [!NOTE]
> Here external means that the network was defined outside
> of this file

`service.yml`

```yaml
networks:
  backend_net:
    external: true

services:
  reverse_proxy:
    container_name: reverse_proxy
    networks:
      - backend_net
    ...
```

## certbot

Certbot is a free, open-source tool from the EFF that automates
getting and installing SSL/TLS certificates from Let's Encrypt
to enable HTTPS on websites, making it easy to secure your site
with encrypted communication (HTTPS) without manual hassle.

### Specifications

- certbot will run in a container
- the certbot **DNS-01** challenge will be used
- nginx is running in a container as a reverse proxy

### DNS-01 challenge

This challenge asks you to prove that you control the DNS for your domain name
by putting a specific value in a TXT record under that domain name.

In order for Certbot to do that it will need an API key from your registar.

Benefits of the **DNS-01 challenge**:

- It allows you to issue wildcard certificates
  (i.e it is easier to create certificates for subdomains).
- Your server does not need to be directly accessible to the internet
  (you do not need to expose ports).

### Setup

Follow the next steps to use the provided docker-compose.yml

#### Provide your api key to certbot

Use the following commands to
create the file where the api key will be stored

```bash
cd /path/to/reverse_proxy_docker-compose.yml
touch ./certbot/cloudflare.ini
```

I use cloudflare so I will use the
[certbot-dns-cloudflare](https://certbot-dns-cloudflare.readthedocs.io/en/stable/)
plugin.
Check available certbot
[dns plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins).

Set the correct file permissions for`./certbot/cloudflare.ini`:

```bash
chmod 600 cloudflare.ini
```

Add your API token by entering the following inside the file:

```bash
# Cloudflare API token used by Certbot
dns_cloudflare_api_token = 0123456789abcdef0123456789abcdef01234567
```

> [!WARNING]
> In the `docker-compose.yml` file I provide
> certbot executes the command:
> `command: certonly --keep-until-expiring --non-interactive
--preferred-challenges dns --dns-cloudflare
--dns-cloudflare-credentials /cloudflare.ini
--dns-cloudflare-propagation-seconds 60
--email my_email -d "my_domain.com" -d "*.my_domain.com"
--agree-tos`.
> When testing to see if the certbot container is working
> be sure to add the `--staging` flag.
> Otherwise, if you make a lot of requests, you will be rate limited.
> Check [staging environment](https://letsencrypt.org/docs/staging-environment/)
> for the rate limits and
> [certbot command line options](https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options)
> for more details about certbot commands.

> [!NOTE]
> Do not specify a `restart policy` for the certbot container
> because a policy does not differentiate between a container stopping
> succesfully or stopping from an error.
> Under normal operation the command that certbot executes gets
> a certificate (almost immediately)
> which makes the container stop (succesfull stop).
> If a `restart policy` like `always` or `unless-stopped`
> was specified, after the container got a valid certificate and stopped
> it would start again.
> It would then execute the command, terminate (succesfully)
> and repeat (infinite restart loop).

### How to renew certificates

Run the container once to obtain a certificate for the 1st time.
After that create a cronjob that starts the container
after a certain period of time.

### Always use https

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
Since `_` is used as the `server_name` this server block will match
all hostnames.

---

Nginx sources:

1. [Nginx docs](https://nginx.org/en/docs/beginners_guide.html)
2. [Nginx reverse proxy docs](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

Certbot Sources:

1. [Certbot with docker](https://eff-certbot.readthedocs.io/en/latest/install.html#running-with-docker)
2. [Manual certificates location](https://eff-certbot.readthedocs.io/en/latest/using.html#where-certs)
3. [ACME Challenge types](https://letsencrypt.org/docs/challenge-types/)
4. [Instructions for Cloudflare API with certbot](https://certbot-dns-cloudflare.readthedocs.io/en/stable/)
5. [Dns plugins](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)
6. [Certbot staging](https://letsencrypt.org/docs/staging-environment/)
7. [Certbot commands](https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options)
