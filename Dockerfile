FROM ruby:2.7.1

RUN apt-get update && apt-get install -y nodejs npm && npm install -g yarn

WORKDIR /app

# Copy dependency config first for better build caching
COPY Gemfile Gemfile.lock .
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

RUN yarn install

ENV RAILS_LOG_TO_STDOUT true
EXPOSE 3000
CMD ["rails", "server", "--binding", "0.0.0.0"]
