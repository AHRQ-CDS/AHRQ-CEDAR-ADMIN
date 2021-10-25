FROM ruby:2.7.4-alpine

RUN apk update && apk upgrade && apk add --update --no-cache build-base postgresql-dev postgresql-client shared-mime-info nodejs npm yarn tzdata libxml2-dev libxslt-dev

WORKDIR /app

# Copy dependency config first for better build caching
COPY Gemfile Gemfile.lock ./
RUN gem install bundler
RUN bundle config set without 'development test'
RUN bundle install

# To successfully run yarn within a firewall may require a certificate with building the image
# Usage: docker build -t cedar_admin --build-arg certificate=<certificate-file> .
ARG certificate
COPY "${certificate}" /usr/local/share/ca-certificates/ca-certificates.crt
RUN update-ca-certificates

# TODO: Ideally we'd like to run yarn install before the COPY of . for better
# caching, but looks like node version mismatch causes issues
#COPY package.json yarn.lock .
#RUN yarn install

COPY . .
RUN rm -rf node_modules log tmp

RUN yarn install

# Build the production assets
# Note: This requires keys, which doesn't make sense to have available at build time
# See https://github.com/rails/rails/issues/32947
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails webpacker:compile

# Logging should be handled at the docker image level
ENV RAILS_LOG_TO_STDOUT true

EXPOSE 3000

# This image can be used both to run the server and background job;
# the actual commands are specified in the docker-compose.yml file

# CMD ["bundle", "exec", "rails", "server", "--environment", "production"]
# CMD bundle exec whenever --update-crontab && cron -f -L15
