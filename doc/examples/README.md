## Elixir

The following configuration requires the use of the Docker executor. It uses the
latest available version of the `elixir` Docker image to run all tests, and
depends on the latest `postgres` Docker image.

The build jobs that will be created are called: `mix` and `credo`. A list of
`cache` paths has been globally defined, as well as the `before_script` that
will run before each of the build job's own scripts.

```yaml
---
image: elixir:latest

services:
- postgres:latest

cache:
  paths:
  - _build/
  - deps/

variables:
  MIX_ENV: test
  DATABASE_URL: postgres://postgres@postgres:5432/alloy_ci_test

before_script:
- mix local.hex --force
- mix local.rebar --force
- mix deps.get
- mix ecto.setup

mix:
  stage: test
  tags:
  - elixir
  - postgres
  script:
  - mix test

credo:
  stage: test
  tags:
  - elixir
  script:
  - mix credo

```

## Ruby

This is the most basic configuration example for a Rails App. Since this configuration
does not specify a Docker image, the Runner's default image will be used. If this
default was not set to Ruby, the build job will fail.

```yaml
---
Rspec Tests:
  script:
  - bundle install --path vendor/bundle
  - bundle exec rake db:setup
  - bundle exec rspec

```

A more complete example for a Rails App, that uses a full definition for Docker
images, with `entrypoint` configuration, and `aliases`. The tests to be performed
will be run against the PostgreSQL database and against the MySQL database,
separately.

```yaml
---
image:
  name: ruby:2.3
  entrypoint:
  - "/bin/bash"

services:
- name: postgres:latest
  alias: postgres-1
  command:
  - "/bin/sh"
- name: mysql:latest
  alias: mysql-1
  command:
  - "/bin/bash"

before_script:
- bundle install --path vendor/bundle

Rspec PostgreSQL:
  script:
  - bundle exec rake db:postgres:setup
  - bundle exec rspec

Rspec MySQL:
  script:
  - bundle exec rake db:mysql:setup
  - bundle exec rspec
```
