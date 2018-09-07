# Build Stage
FROM elixir:latest as build

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/opt/app/ TERM=xterm

RUN \
  curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
  apt-get install -y nodejs

## Install Hex+Rebar
RUN mix local.hex --force && \
  mix local.rebar --force

WORKDIR /opt/app

ENV MIX_ENV=prod

## Cache elixir deps
RUN mkdir config
COPY config/* config/
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile, sentry_recompile

## Cache node deps
COPY assets/*.json ./assets/
RUN cd ./assets && npm install

## Compile assests & create digest
COPY . .
RUN cd ./assets && ./node_modules/brunch/bin/brunch b -p
RUN mix phx.digest

## Compile Elixir release
RUN MIX_ENV=prod mix release --env=prod

# Release Stage
FROM elixir:slim

EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod REPLACE_OS_VARS=true SHELL=/bin/sh

WORKDIR /app
COPY --from=build /opt/app/_build/prod/rel/alloy_ci ./

ENTRYPOINT ["bin/alloy_ci"]
