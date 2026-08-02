# Searxng

## Description

Searxng is a meta search engine that
does not collect information about users.

## Reverse proxy

When configuring searxng to run behind a reverse proxy
keep in mind that the container will use the port
defined in the .env as `SEARXNG_PORT`.

I am using nginx as my reverse proxy so I will
need to replace the value of `SEARXNG_PORT` in the
`proxy_pass` of my directive.

```nginx
proxy_pass http://searxng-core:SEARXNG_PORT;
```

## All engines timeout error

When I first tried to run the instance I got an error
where all the search engines would timeout.

After some searching I realised that my problem is similar
to the one in [issue 4590](https://github.com/searxng/searxng/discussions/4590).

I used the same solution and specified my router's IP as `dns` in `docker-compose.yml`

> [!NOTE]
> When writing this readme my setup has nginx as a reverse proxy
> with pihole (dns) and searxng behind the reverse proxy.
> Every application is run in its own container.

## Favicons

By default searxng does not show favicons when showing the results of a search.
This is done because activating them
generates a significantly higher load in the client/server communication
and increases resources needed on the server.

To use favicons check the [documentation](https://docs.searxng.org/admin/searx.favicons.html)

I copied the default settings from the docs and everything worked.
