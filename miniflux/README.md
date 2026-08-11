# miniflux

## Description

Miniflux is an opinionated RSS reader.
It is very lighweight and minimalistic as it focuces on
simplicity and functionality.

As written in the main page:
_Miniflux is a minimalist software. **The purpose of this application is
to read feeds**. Nothing else._

## Environmental variables

### Changing default variables

As most of my services in my homelab I have created a `.env` file
to store configuration settings.

I have deciced to change the default values for the following variables:

- **ADMIN_PASSWORD**
- **POSTGRESS_PASSWORD**

> [!NOTE]
> When changing the value for `POSTGRESS_PASSWORD` the variable `DATABASE_URL`
> must also be changed accordingly.
> The `DATABASE_URL` has the form:
> DATABASE_URL=postgres://<POSTGRESS_USER>:<POSTGRESS_PASSWORD>@db/miniflux?sslmode=disable
> So, replace POSTGRESS_PASSWORD with the one in the .env file.
> Also, do not change the value of `POSTGRESS_USER`
> as the default user name is needed.

> [!NOTE]
> When trying out different settings you might need to delete the
> directory or volume where miniflux writes its data.
> For example if you build miniflux once and change the `ADMIN_PASSWORD`
> (without removing the created volume) and then rebuild miniflux
> you will not be able to login as admin.
> This is because the old password is still saved in the volume.
> To solve this simply remove the volume across rebuilds
> if you have changed any of the environmental variables.

### Notes on global variables

The [documentation](https://miniflux.app/docs/configuration.html)
mentions that miniflux uses either environmental variable or a config file.
If miniflux is running in docker the configuration variables should
be defined in the `.env` file as stated in [issue 3115](https://github.com/miniflux/v2/issues/3115).
