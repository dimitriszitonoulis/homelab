# Paperless-ngx

Paperless-ngx is a community-supported open-source document management system
that transforms your physical documents into a searchable online
archive so you can keep, well, less paper.

## Instalation

To install paperless-ngx with docker follow the instructions at the
[install page](https://docs.paperless-ngx.com/setup/#docker).

## Configuration

I am running this setup on docker so instead of using the paperless.conf file
(intended for the normal install),
I will use the `docker-compose.env` file.

For a more in depth guide read
[configuration page](https://docs.paperless-ngx.com/configuration/).

### Example docker-compose.env file

```yaml

###############################################################################
# Paperless-ngx settings                                                      #
###############################################################################

# See http://docs.paperless-ngx.com/configuration/ for all available options.

# The UID and GID of the user used to run paperless in the container. Set this
# to your UID and GID on the host so that you have write access to the
# consumption directory.
USERMAP_UID=1000
USERMAP_GID=1000

# See the documentation linked above for all options. A few commonly adjusted settings
# are provided below.

# This is required if you will be exposing Paperless-ngx on a public domain
# (if doing so please consider security measures such as reverse proxy)
#PAPERLESS_URL=https://paperless.example.com

# Required. A unique secret key for session tokens and signing.
# Generate with: python3 -c "import secrets; print(secrets.token_urlsafe(64))"
PAPERLESS_SECRET_KEY=secret_key

# Use this variable to set a timezone for the Paperless Docker containers. Defaults to UTC.
PAPERLESS_TIME_ZONE=Continent/Region

# Broker
PAPERLESS_REDIS=redis://broker:6379

# Database
PAPERLESS_DBHOST=db
# PAPERLESS_DBPORT=5432
PAPERLESS_DBENGINE=postgresql
PAPERLESS_DBNAME=paperless
PAPERLESS_DBUSER=paperless
PAPERLESS_DBPASS=db_password
PAPERLESS_DB_OPTIONS="sslmode=require,sslrootcert=/certs/ca.pem,pool.max_size=5"
PAPERLESS_EMAIL_PARSE_DEFAULT_LAYOUT=1

# Hosting and security
PAPERLESS_URL="https://paperless.mydomain.com"

PAPERLESS_ADMIN_USER=admin
PAPERLESS_ADMIN_PASSWORD=admin_password

# Authentication and SSO
PAPERLESS_ACCOUNT_ALLOW_SIGNUPS=false

# OCR settings
# The default language to use for OCR. Set this to the language most of your
# documents are written in.
PAPERLESS_OCR_LANGUAGE=eng

# Postgres
POSTGRES_DB=paperless
POSTGRES_USER=paperless
# same as PAPERLESS_DBPASS
POSTGRES_PASSWORD=dp_password

# Tika and Gotenberg
PAPERLESS_TIKA_ENABLED=1
PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000
PAPERLESS_TIKA_ENDPOINT=http://tika:9998

```
