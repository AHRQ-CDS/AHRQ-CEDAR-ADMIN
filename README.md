<center><strong>Note: development of CEDAR will enter hiatus starting on Sept 30th, 2023.</strong></center><br>

# The CEDAR Project

The [CEDAR project](https://cds.ahrq.gov/cedar/) provides a standards-based API that supports search, access, and use of patient centered outcomes research and other research findings across multiple repositories and programs within [AHRQ's Center for Evidence and Practice Improvement (CEPI)](https://www.ahrq.gov/cpi/centers/cepi/index.html).

Health IT developers can use CEDAR to integrate AHRQ CEPI research findings directly into their existing systems, where the findings can then be accessed and used by researchers, clinicians, policymakers, patients, and others. CEDAR optimizes the use of patient centered outcomes research and other research data by following standard guidelines for improving the Findability, Accessibility, Interoperability, and Reuse (the FAIR principles) of digital assets, providing fast and efficient access to information.

CEDAR is publicly available for other platforms to use to discover and retrieve AHRQ evidence from multiple resources simultaneously.

## CEDAR Admin

CEDAR Admin supports the CEDAR project's indexing and administrative capabilities. The CEDAR Admin repository provides:

1. Functionality to index the contents of external evidence repositories and map artifact metadata to the CEDAR data model
2. A web application for CEDAR administrators

User documentation for CEDAR administrators can be found in the [CEDAR Admininstration Guide](docs/ADMIN-GUIDE.md).

For information about using or contributing to this project, please see

- [Contribution Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE-OF-CONDUCT.md)
- [Terms and Conditions](TERMS-AND-CONDITIONS.md)

## Development Details

CEDAR Admin is a Ruby on Rails application.

### Prerequisites

* Ruby 2.7.1 or later
* Bundler
* Node.js
* Yarn
* PostgreSQL Database
* Docker (if building Docker image)

### Installing Dependencies

After cloning this repository, run

```
bundle install
yarn install
rails db:create
rails db:migrate
rails db:seed
```

### Testing

To run tests, run

```
rails test
```

### Running CEDAR Admin

After installing and testing, to run the CEDAR Admin application:
(Consider populating the app via the import commands below if this is your first run)

```
rails server
```

Documentation for the CEDAR Admin user interface can be found in the [CEDAR Administration Guide](docs/ADMIN-GUIDE.md).

### Importing UMLS Concepts

Download the MRCONSO.RRF file from: [https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html](https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html) and move it to the CEDAR directory. Run

```
rake import:umls_concepts
```

Due to the size of the MRCONSO.RRF file, this can take several hours to complete, be patient.

### Importing Data from Repositories

To import data from the US Preventative Services Task Force, run

```
rake import:uspstf
```

### Environment Variables

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

### Authenticating Users

Due to the sensitivity of certain data elements (e.g. client IP addresses and search terms), users will need to authenticate. Currently only LDAP authentication is supported.

For convenience, the default in a development environment (`Rails.env.development? == true`) is that any credentials will work and there is no need to create or manage user accounts. This default can be overridden using an environment variable `CEDAR_DEVELOPMENT_LDAP_AUTH=yes`. In a production environment (`Rails.env.production == true`), LDAP authentication is always enabled.

To configure LDAP authentication and authorization details provide the various `CEDAR_ADMIN_LDAP_*` environment variables described above as part of your deployment environment.

### Docker

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

### Unmerged Branches

Two git branches contain pilot or experimental work that was never deployed to production but may be
of interest for future development of CEDAR: the `fevir_importer` branch contains work conducted
while piloting bi-directional data exchange between CEDAR and the[FEvIR Platform](https://fevir.net/)
and the `similarity` branch contains work exploring the use of a language model for calculating
similarirty between artifacts. These branches are documented in more detail in the [unmerged
branches documentation](docs/UNMERGED-BRANCHES.md).

## LICENSE

Copyright 2022 Agency for Healthcare Research and Quality.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this software except
in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing permissions and limitations under the
License.
