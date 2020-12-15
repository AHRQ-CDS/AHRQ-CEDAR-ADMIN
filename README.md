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
```

## Test

To run tests, run

```
rails test
```

## Docker

Building and running a docker image:

```
docker build -t cedar_admin .
docker run -p 3000:3000 cedar_admin
```

The docker image can be built using a certificate if needed within certain environments:

```
docker build -t cedar_admin --build-arg certificate=<certificate> .
docker run -p 3000:3000 cedar_admin
```
