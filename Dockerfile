FROM ruby:2.7.1

RUN apt-get update && apt-get install -y nodejs npm cron && npm install -g yarn

WORKDIR /app

# Copy dependency config first for better build caching
COPY Gemfile Gemfile.lock ./
RUN gem install bundler
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
# TODO: This requires production keys, which doesn't make sense to have available at build time
# See https://github.com/rails/rails/issues/32947
# ENV RAILS_ENV production
# RUN bundle exec rails assets:precompile
# RUN bundle exec rails webpacker:compile

# Logging should be handled at the docker image level
ENV RAILS_LOG_TO_STDOUT true

EXPOSE 3000

# This image can be used both to run the server and background job;
# the actual commands are specified in the docker-compose.yml file

# CMD ["bundle", "exec", "rails", "server", "--environment", "production"]
# CMD bundle exec whenever --update-crontab && cron -f -L15
