# Alloy CI

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Alloy CI aims to bridge the gap between GitLab's CI runner and GitHub. GitLab's
CI runner is tightly coupled with GitLab, so it is not possible to use one of
these runners from a GitHub codebase.

With AlloyCI you will be able to register a GitLab CI runner to the platform,
connect it to one of your GitHub's repositories, and have it run your CI and
CD pipelines.

AlloyCI will report the status of your pipelines to your pull requests and
branches, so you can always know their status, just like any other CI service.

## Goals

- To provide a clean bridge between GitHub and the GitLab CI runner
- To provide an alternative to other open source CI services
- To leverage the great open source project that is the GitLab CI runner
- To provide GitHub users with the same top class CI/CD that GitLab has, without
  having to switch to GitLab, or paying insane amounts for inferior services

### Stretch Goals

- To create a SaaS based on AlloyCI and provide a more cost effective alternative
  to the current CI service ecosystem
- To provide all the CI/CD/Pipelines functionality, currently available only to
  GitLab EE, for free

## Features

- [x] Basic CI functionality:
  - [x] Can parse a basic [`.alloy-ci.json`](doc/json/README.md) file correctly, and create build jobs accordingly
  - [x] Can send the required build information to the runner for processing when requested
  - [x] Can receive status updates from runner
  - [x] Can report back to GitHub with the statuses
- [ ] Advanced CI functionality
  - [x] Can use a local build cache to speed up jobs
  - [ ] Can distinguishing between tags and branches
  - [ ] Can receive uploaded artifacts from runners
  - [ ] Can pass artifacts between build jobs
  - [ ] Can make use of `only` and `except` tags for jobs
- [ ] Deployment functionality
  - [ ] Can manually start deployments (manual actions)
  - [x] Can do auto deploys
  - [ ] Can start Review Apps
- [x] [Autoscaling Support](doc/install/autoscaling.md) (supported directly by the runner)
  - [x] Can create runners on demand
  - [x] Can destroy runners when not in use

## Installation

### Heroku

### Docker

### Manual  
