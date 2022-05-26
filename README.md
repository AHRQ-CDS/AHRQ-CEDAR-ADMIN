# CEDAR Admin

The CEDAR Admin repository provides:

1. A web application for CEDAR administrators
2. Functionality to index the contents of external evidence repositories and map artifact metadata to the CEDAR data model

See also:

- [Contribution Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE-OF-CONDUCT.md)
- [Terms and Conditions](TERMS-AND-CONDITIONS.md)

## Prerequisites

* Ruby 2.7.1 or later
* Bundler
* Node.js
* Yarn
* PostgreSQL Database
* Docker (if building Docker image)

## Install Dependencies

After cloning this repository, run

```
bundle install
yarn install
rails db:create
rails db:migrate
rails db:seed
```

## Test

To run tests, run

```
rails test
```

## Run

After installing and testing, to run the CEDAR Admin application:
(Consider populating the app via the import commands below if this is your first run)

```
rails server
```

## Importing UMLS Concepts

Download the MRCONSO.RRF file from: [https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html](https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html) and move it to the CEDAR directory. Run

```
rake import:umls_concepts
```

Due to the size of the MRCONSO.RRF file, this can take several hours to complete, be patient.

## Importing Data from Repositories

To import data from the US Preventative Services Task Force, run

```
rake import:uspstf
```

## Environment Variables

CEDAR respects the following environment variables:

  * `CEDAR_USPSTF_API_KEY` - API key for accessing USPSTF for indexing
  * `CEDAR_CDS_CONNECT_BASE_URL` - URL for accessing CDS Connect for indexing
  * `CEDAR_CDS_CONNECT_USERNAME` - Username for accessing CDS Connect for indexing
  * `CEDAR_CDS_CONNECT_PASSWORD` - Password for accessing CDS Connect for indexing
  * `CEDAR_SRDR_BASE_URL` - URL for accessing SRDR for indexing
  * `CEDAR_SRDR_API_KEY` - API key for accessing SRDR for indexing
  * `CEDAR_EHC_FEED_URL` - URL (with embedded token) for accessing EHC for indexing

For production deployments:

  * `CEDAR_ADMIN_DATABASE` - Name of the postgres database to connect to
  * `CEDAR_ADMIN_DATABASE_USERNAME` - Postgres database username
  * `CEDAR_ADMIN_DATABASE_PASSWORD` - Postgres database password
  * `CEDAR_ADMIN_LDAP_HOST` - Hostname of LDAP server
  * `CEDAR_ADMIN_LDAP_PORT` - Port of LDAP serer (defaults to 389)
  * `CEDAR_ADMIN_LDAP_ATTRIBUTE` - LDAP attribute (defaults to uid)
  * `CEDAR_ADMIN_LDAP_BASE` - Base from which LDAP server will search for users
  * `CEDAR_ADMIN_LDAP_GROUP` - LDAP group allowed to access CEDAR Admin
  * `CEDAR_ADMIN_LDAP_SSL` - Connect to LDAP via SSL (true or false, defaults to false)

For use in development:

  * `CEDAR_DEVELOPMENT_LDAP_AUTH` - Authenticate via an LDAP server while in development mode (yes or no, defaults to no)

## Authenticating Users

Due to the sensitivity of certain data elements (e.g. client IP addresses and search terms), users will need to authenticate. Currently only LDAP authentication is supported.

For convenience, the default in a development environment (`Rails.env.development? == true`) is that any credentials will work and there is no need to create or manage user accounts. This default can be overridden using an environment variable `CEDAR_DEVELOPMENT_LDAP_AUTH=yes`. In a production environment (`Rails.env.production == true`), LDAP authentication is always enabled.

To configure LDAP authentication and authorization details provide the various `CEDAR_ADMIN_LDAP_*` environment variables described above as part of your deployment environment.

## Docker

Building the docker image for deployment:

```
docker build -t cedar_admin .
```

The docker image can be built using an SSL certificate if needed within certain environments:

```
docker build -t cedar_admin --build-arg certificate=<certificate> .
```

Running the docker image directly for the server

```
docker run -p 3000:3000 --env CEDAR_USPSTF_API_KEY=<key> cedar_admin rails server --binding 0.0.0.0
```

Running the docker image directly for the worker

```
docker run --env CEDAR_USPSTF_API_KEY=<key> cedar_admin sh -c "bundle exec whenever --update-crontab && cron -f -L15"
```

Using docker compose to run both the server and the worker

First create a .env file that sets CEDAR_USPSTF_API_KEY and CEDAR_ADMIN_DATABASE_PASSWORD:

```
CEDAR_USPSTF_API_KEY=<key>
CEDAR_ADMIN_DATABASE_PASSWORD=<password>
```

then

```
docker-compose build
docker-compose up
```

If the database needs to be created and migrations need to run, in a separate terminal run

```
docker-compose run web rails db:create db:migrate RAILS_ENV=production
```
