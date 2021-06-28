# CEDAR Admin

## Prerequisites

* Ruby 2.7.1 or later
* Bundler
* Node.js
* Yarn
* PostgreSQL Database
* Docker (if building Docker image)

## Install

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

## Docker

Building the docker image:

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
