# Alloy CI

[![build status](https://alloy-ci.com/projects/1/badge/master)](https://alloy-ci.com/projects/1)
[![Docker](https://img.shields.io/docker/pulls/alloyci/alloy_ci.svg)](https://hub.docker.com/r/alloyci/alloy_ci/)
[![Coverage Status](https://coveralls.io/repos/github/AlloyCI/alloy_ci/badge.svg?branch=master)](https://coveralls.io/github/AlloyCI/alloy_ci?branch=master)

AlloyCI is a Continuous Integration, Deployment, and Delivery coordinator,
written in Elixir, that takes advantage of the GitLab CI Runner, and its
capabilities as executor. It also provides its own runner, the [Alloy Runner](https://github.com/AlloyCI/alloy-runner),
which is a fork of the GitLab CI Runner, with extra capabilities.

It aims to bridge the gap between GitLab's CI runner and GitHub. GitLab's
CI runner is tightly coupled with GitLab, so it is not possible to use one of
these runners from a GitHub codebase.

With AlloyCI you will be able to register one of the Runner projects to the platform,
connect it to one of your GitHub repositories, and have it run your CI and
CD pipelines.

AlloyCI will report the status of your pipelines to your pull requests, branches,
and commits, so you can always know their status, just like any other CI service.

## Goals

- To provide a clean bridge between GitHub and the GitLab CI runner
- To provide an alternative to other open source CI services
- To leverage the great open source project that is the GitLab CI runner
- To provide GitHub users with the same top class CI/CD that GitLab has, without
  having to switch to, or use GitLab, or paying insane amounts for inferior services

### Stretch Goals

- To provide all the CI/CD/Pipelines functionality, currently available only to
  GitLab EE, for free
- To create a SaaS based on AlloyCI and provide a more cost effective alternative
  to the current CI service ecosystem

## Features

- [x] Basic CI functionality:
  - [x] Uses the [`.alloy-ci.yml`](doc/yaml/README.md) to define pipelines, jobs, and stages
  - [x] Can send the required build information to the runner for processing when requested
  - [x] Can receive status updates from runner
  - [x] Can report back to GitHub with the statuses
  - [x] Can send notifications via email with the status of a pipeline
  - [x] Can send notifications to Slack with the status of a pipeline
- [x] Extras
  - [x] Build statistics per project
  - [x] Build statistics per runner
  - [x] Support for GitHub Enterprise
- [x] Advanced CI functionality
  - [x] Can run jobs on multiple environments (using the [`image` feature](doc/docker/README.md) of the Docker executor.)
  - [x] Can use a local build cache to speed up jobs
  - [x] Can build and test from pull requests coming from a fork
  - [x] Can distinguish between tags and branches
  - [x] Can make use of `only` and `except` tags for jobs
  - [x] Can make use of secret variables stored on a per project basis
  - [x] Can receive uploaded artifacts from runners
  - [x] Can pass artifacts between build jobs as dependencies
  - [x] Can manually specify dependent jobs via the `.alloy-ci.yml` file
  - [x] Presents the artifacts to the user in a nice way, and allows download
- [ ] Deployment functionality
  - [ ] Can manually start deployments (manual actions)
  - [x] Can do auto deploys
  - [ ] Can make use of different environments
  - [ ] Can start Review Apps
- [x] [Auto Scaling Support](https://github.com/AlloyCI/alloy-runner/tree/master/docs/install/autoscaling.md) (supported directly by the runner)
  - [x] Can create runners on demand
  - [x] Can destroy runners when not in use

## Installation

Head over to our [documentation](doc/) for more information.

## Contributing

Pull requests are always welcome!

1. Clone the Repository
1. Run `mix deps.get` to install all dependencies
1. Run `cd assets && npm install` to install all Javascript dependencies
1. Make sure all environment variables are present. See [here](doc/README.md#configuration) for more info. 
   You can save them in a `.env` file, and source them before running any `mix` task
1. Create and migrate the database with `mix ecto.setup`
1. Run tests with `mix test` or start a development server with `mix phx.server`
1. Code & send your PR when ready

Before contributing, please read our [Code of Conduct](CODE_OF_CONDUCT.md) and
make sure you fully understand it. Violations will not be tolerated.

## Copyright

Copyright (c) 2018 Patricio Cano. See [LICENSE](LICENSE) for details.
