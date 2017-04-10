# Alloy CI

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Alloy CI aims to bridge the gap between GitLab's CI runner and GitHub. GitLab's
CI runner is tightly coupled with GitLab, so it is not possible to use one of
these runners from a GitHub codebase.

With Alloy you will be able to register a GitLab CI runner to the platform,
connect it to one of your GitHub's repositories, and have it run your CI and
CD pipelines.

Alloy will report the status sent to the runner to your pull requests and
branches, so you can always know their status, just like any other CI service.

## Goals

- To provide a clean bridge between GitHub and the GitLab CI runner
- To provide an alternative to other open source CI services
- To leverage the great open source project that is the GitLab CI runner
- To provide GitHub users with the same top class CI/CD that GitLab has, without
  having to switch to GitLab

### Stretch Goals

- To create a SaaS based on Alloy and provide a more cost effective alternative
  to the current CI service ecosystem
- To provide all the CI/CD/Pipelines functionality, currently available only to
  GitLab EE, for free

## Features

- [ ] Basic CI functionality:
  - [ ] Sends a notification to the runner to clone the code
  - [ ] Can execute the `.gitlab-ci.yml` file
  - [ ] Can report back and create a job for each job inside the yml file
  - [ ] Can receive status updates from runner
  - [ ] Can report back to GitHub with the statuses
- [ ] Deployment functionality
  - [ ] Allow deployments to be started from Alloy
  - [ ] Allow autodeploys
  - [ ] Support Review Apps
- [ ] Autoscaling Support
  - [ ] Create runners on demand
  - [ ] Destroy runners when not in use

# To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
