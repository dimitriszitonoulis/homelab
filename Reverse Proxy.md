# Nginx Reverse Proxy

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

| domain name | service |
|-------------|---------|
| s1.home | service1 |
| s2.home | service2 |

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

### Security

A server and its services can be on different networks
(server network and internal docker network)
with the reverse proxy acting as the middleman.

### https

Reverse proxies are an easy way to use SSL certificates with
**LetsEncrypt** and **certbot** to use **https**
instead of **http** to access a web service.

## Nginx config

### config location

The way nginx and its modules work is determined in the configuration file.
By default, the configuration file is named `nginx.conf` and placed
in the directory `/usr/local/nginx/conf`, `/etc/nginx`, or `/usr/local/etc/nginx`.

A configuration can also be split up to multiple configuration files.
To do that place the configuration files under `/etc/nginx/conf.d/` and include
everything under `/etc/nginx/conf.d/` in the main `http` block in `/etc/nginx/nginx.conf`.

You can include all files under `/etc/nginx/conf.d/` that end with `.conf`
with the following `inlcude` inside the `/etc/nginx.conf`.

```nginx
http {
    include /etc/nginx/conf.d/*.conf;
}
```

Each file under `/etc/nginx/conf.d/` must contain a `server` block.

### how to redirect

Specify a `location`, a URI for the server with hostname `server_name`.
All paths that match it will be redirected to `proxy_pass`.
After that nginx will get the response and send it back to the client.

If a `server_name` is not specified in a `server` block,
it will act as a **default catch-all** and it will be used,
as long as there is not another block matching the `hostname`
in the `Host header`. Not specifying a `hostname` is equivalent to `server_name _;`

To use the device's hostname specify: `server_name $hostname;`

A `location` can be entered  with:

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

### docker-compose.yml

An example `docker-compose.yml` for running `nginx` as a reverse proxy with docker:

```yaml

networks:
  proxy_net:
    name: proxy_net
    driver: bridge
  frontend_net:
    name: frontend_net
    driver: bridge

services:
    reverse_proxy:
        container_name: reverse_proxy
        networks:
            proxy_net:
            frontend_net:
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
```

#### Notes

All proxied containers should exist in the `proxy_net` and communicate
with the outside network through the reverse proxy.
The `frontend_net` is to be used only by the reverse proxy and containers
that need to directly connect with the outside network.

**However**,
in the example above the networks are not configured to do that.
The configuration of each network will vary widely on each user's need,
so I did not see the need to create an example configuration for the docker networks.

 ---
 Sources:
[^1]: [Nginx docs](https://nginx.org/en/docs/beginners_guide.html)
[^2]: [Nginx reverse proxy docs](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/) 
