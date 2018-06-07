# AlloyCI Documentation

- [Installation](#installation)
  - [First Steps](#first-steps)
  - [Requirements](#requirements)
  - [Configuration](#configuration)
  - [Docker Installation](#docker-installation)
  - [Deploy to Heroku](#deploy-to-heroku)
  - [Manual Installation](#manual-installation)
  - [First Run](#first-run)
- [Configuration File](yaml/)
  - [Job Environment Variables](variables/)
  - [Examples](examples/)
- [Runners](runners/)

# Installation

## First Steps

Before installing AlloyCI on your server, there are some actions that you need to
take in order for AlloyCI to be able to function properly.

### Preparing GitHub for your AlloyCI instance

#### GitHub Apps (formerly known as integrations)

> **Note:** As of v0.5.0 AlloyCI also supports GitHub Enterprise v2.13 and above. Head over
> to the [GitHub Enterprise configuration docs](github_enterprise.md) for how to set it up, and then return
> to the [requirements](#requirements) section of this document.

In order to use your own instance of AlloyCI with GitHub.com, you will need to
register a new GitHub App. Go to https://github.com/settings/apps/new to get
started.

Fill in the form with your data, and the following for the specified fields:

- `User authorization callback URL:` => https://alloy-ci.example.com/auth/github/callback
- `Webhook URL:` => https://alloy-ci.example.com/api/github/handle_event
- `Webhook secret (optional):` => A random string of characters

Under permissions, make sure that the following permissions are enabled and with
the correct settings:


**Commit Statuses:**

- Read & Write

**Repository Contents:**

- Read & Write

**Subscribe to events**

Select the following checkboxes:

- [x] Status
- [x] Create
- [x] Push
- [x] Delete

---

Finally, select where the integration can be installed.

Once created, you will have almost everything you need to setup the environment
variables for AlloyCI. GitHub will redirect you to your newly created app.

On this page, GitHub will ask you to generate a private key for your installation.
Do so, and save the generated file. The contents of this file will be used for the
`GITHUB_PRIVATE_KEY` environment variable. Don't lose this file, or you will have
to generate a new key.

The `GITHUB_APP_ID` appears on the right column, right at the end.

The `GITHUB_APP_URL` will be the public link to your app. This field will
only show up, if you chose to make your installation public.

The Webhook secret you selected before will go to the `GITHUB_SECRET_TOKEN` variable.

**Important:** On this page you will also find some OAuth credentials. Unfortunately,
due to a bug in GitHub's OAuth system, we cannot use these credentials for the
`GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` variables. We will need to create
a new OAuth application in order to allow users to sign up via GitHub.

If you prefer your users to **manually create an account**, and then link that
account to their GitHub accounts, you can use these credentials and skip the next
step.

#### GitHub OAuth App

As mentioned before, if you'd like your users to create accounts via GitHub, you
will need to also create a separate OAuth app. To do so, go to
https://github.com/settings/applications/new

Fill in the form with your information, and as `Authorization callback URL`
use `https://alloy-ci.example.com/auth/github/callback`.

Once the app is created, you will be redirected to a page containing the client ID
and secret needed for the `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` variables.

Once you have values for all the `GITHUB_*` variables, you can continue with the
next steps.

## Requirements

The only outside dependency needed to run AlloyCI is PostgreSQL. You can either
run this as another Docker container, or an external service. The only thing needed
for AlloyCI to connect to the database is an environment variable called `DATABASE_URL`
with the DB data encoded in the following format:

```
postgres://<user>:<password>@<hostname>:<port>/<db_name>
```

### Proxy Server (optional)

AlloyCI, being a Phoenix application, starts a Web Server process to serve HTTP
requests. This server is perfectly capable of handling all HTTP requests on its
own, but it is common practice to use `nginx`, `Apache`, or any other web server
as a proxy, specially when SSL configuration is needed.

For an example on how to configure `nginx` as a reverse proxy, have a look at the
[nginx.conf.example](../nginx.conf.example) file.


## Configuration

There are several environment variables that AlloyCI needs to have available in
order to work properly. This variables also allow you to configure AlloyCI to match
your requirements.

The required variables are as follows:

| Name                       | Description                                      |
|----------------------------|--------------------------------------------------|
| DATABASE_URL               | Full PostgreSQL URL to the database server       |
| HOST                       | FQDN of the server running AlloyCI               |
| RUNNER_REGISTRATION_TOKEN  | Random string used to register global runners    |
| SERVER_URL                 | Full URL via which AlloyCI will be accessible    |
| SECRET_KEY_BASE            | 65 chars long random string used to sign cookies |
| GITHUB_CLIENT_ID           | OAuth Client ID of your GitHub App               |
| GITHUB_ENTERPRISE          | If the GitHub endpoint in use is an Enterprise installation, set to true, **otherwise don't add this** |
| GITHUB_ENDPOINT            | The GitHub endpoint URL, e.g https://github.example.com (only needed for GitHub Enterprise) |
| GITHUB_CLIENT_SECRET       | OAuth Client Secret of your GitHub App           |
| GITHUB_APP_ID              | The ID of the App created before        |
| GITHUB_APP_URL             | The URL where users can add the App to their accounts |
| GITHUB_PRIVATE_KEY         | The full private key used to sign GitHub's auth token |
| GITHUB_SECRET_TOKEN        | Secret token used to verify GitHub payloads |
| ENABLE_SLACK_NOTIFICATIONS | Please set it to "true" or "false" |
| ENABLE_EMAIL_NOTIFICATIONS | Please set it to "true" or "false" |
| ARTIFACT_SWEEP_INTERVAL    | Interval, in hours, for how often the system should check for expired artifacts |
| S3_STORAGE_ENABLED         | If you want to use an S3 compatible storage service for the build artifacts, set to true, **otherwise don't add this** |
| SENTRY_DSN                 | Set this to your Sentry DSN if you want to use it for error catching |

### Notifiers Configuration

Add the following variables as well, depending on which notification mechanism you 
enabled before.

**Slack:**

| Name                 | Description                                     |
|----------------------|-------------------------------------------------|
| SLACK_CHANNEL        | Name of the Slack channel to post notifications |
| SLACK_SERVICE_NAME   | Name of the service, e.g. AlloyCI               |
| SLACK_HOOK_URL       | URL of the WebHook created for notifications    |

**Email:**

| Name                 | Description                                     |
|----------------------|-------------------------------------------------|
| SMTP_SERVER          | SMTP Server to use for email connections        |
| SMTP_PORT            | SMTP Port                                       |
| SMTP_USERNAME        | Username for server authentication              |
| SMTP_PASSWORD        | Password for said username                      |
| SMTP_SSL             | Please set it to "true" or "false"              |
| ALLOWED_TLS_VERSIONS | e.g. "tlsv1.1,tlsv1.2"                          |
| FROM_ADDRESS         | Email address that will appear as sender        |
| REPLY_TO_ADDRESS     | Where the user will reply                       |

### S3 Storage Configuration

Add the following variables if you are using an S3 service. Almost all S3
compatible providers are supported.

| Name                 | Description                                     |
|----------------------|-------------------------------------------------|
| S3_REGION            | If **using AWS**, set the region to use here    |
| S3_BUCKET_NAME       | Name of the S3 bucket to use                    |
| S3_ACCESS_KEY_ID     | Your S3 Access Key ID                           |
| S3_SECRET_ACCESS_KEY | Your S3 Secret Access Key                       |
| S3_HOST              | If using **a service other than AWS**, set the host here, **otherwise don't add this** |
| S3_PORT              | If using **a service other than AWS**, set the connection port here |
| S3_HTTP_SCHEME       | If using **a service other than AWS**, set to `http://` or `https://` |



## Docker Installation

The recommended way of running AlloyCI is via our Docker images. You will find
them under `alloyci/alloy_ci` at [DockerHub](https://hub.docker.com/r/alloyci/alloy_ci/).

### Docker Compose

The easiest way to get AlloyCI up and running with Docker is to use Docker Compose.
You will find an example [`docker-compose.yml` file](../docker-compose.yml.example)
that will get you most of the way there. All you need to do is replace the environment
variables with the ones matching your environment.

Copy this file to your local machine, or wherever you'd like to run Docker from,
and edit it. Once the file is ready, running `docker-compose up -d` will start
all the necessary components for AlloyCI to run, and also start AlloyCI itself.

The example YAML file specifies the database requirement image, and the AlloyCI
image to use.

>**Notice:** You will need to have Docker installed and configured in order to use
Docker Compose. We suggest using Docker Machine with the Digital Ocean Driver to
get a cloud server up and running, and ready for production use in mere minutes.
> This procedure can also be used to install AlloyCI on AWS, Azure, or any other
cloud server provider that supports Docker. It can also be used with Kubernetes.

### Migrations

Database migrations are run automatically when the application starts, so there is
no need to run them manually.

Continue over to [First Run](#first-run) to set up the admin user for your instance.

### Reverse proxy

You can use nginx as a reverse proxy for AlloyCI and its Docker Container, if you
don't want to directly expose the container. The setup is the same as with any
other reverse proxy configuration, and you can find and example in the [nginx.conf.example](../nginx.conf.example) 
file.

## Deploy to Heroku

The easiest way to deploy AlloyCI to Heroku is to use the button below:

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Heroku should ask you to fill in the required environment variables. If it doesn't,
you will need to create them yourself. They are the same as the ones stated above,
plus `MIX_ENV` which needs to be set to `heroku`.

### Migrations

Database migrations need to be run manually. After the Heroku app has beed deployed,
please run the following command from your terminal:

```bash
$ heroku run -a <app_name> "MIX_ENV=heroku mix ecto.migrate"
```

### Limitations

For the time being, you will not be able to use the artifact upload feature with Heroku,
given that it does not provide permanent disk access. S3 support for artifact files is
planned for the feature, certainly before 1.0 is released.

## Manual Installation

The reason why we recommend Docker as the preferred installation method is because
of how Elixir applications are prepared for release. Elixir applications need to be
compiled. This means that if you build your release on a macOS machine, and want
to deploy it to a Linux server, the build will be incompatible. Using Docker
allows us to circumvent this, because the build is created inside the same container
that will be deployed to production. Nonetheless it is still possible to deploy
an Elixir application without using Docker, there are just extra precautions and
steps you need to take.

The guide assumes you have Elixir v1.6.1, and Erlang OTP v20 already installed and
ready to run.

>**Notice:** The following steps can be performed on your local machine or directly
on the target server that will run AlloyCI in production.

### Clone

Clone the code to your machine:

```shell
$ git clone https://github.com/AlloyCI/alloy_ci.git
$ cd alloy_ci/
```

### Build Release

After cloning the AlloyCI repo, you need to get the dependencies required for the
server to run.

```shell
$ mix deps.get
```

Once the Elixir dependencies are installed, you need to compile the Javascript files.

```shell
$ cd assets/
# Install all JS dependencies
$ npm install
# Compile the CSS and JS files
$ ./node_modules/brunch/bin/brunch b -p
# Generate digest file
$ cd ../ && mix phx.digest
```

Once the dependencies have been installed, and the asset files compiled. you are ready to
build the release.

```shell
$ MIX_ENV=prod mix release --env=prod
```

This will build the release for the `prod` environment. The release files are located at
the root of where you cloned the project, under `_build/prod/rel/alloy_ci`. In order to
"deploy" the release to a remote server, you will need the compressed release file, which
is further down the directory tree, under `releases/<version>/alloy_ci.tar.gz`.

---
**Notice:**

The default configuration assumes that the target Erlang OTP is the same
version as the one building the release, so it does not include the Erlang Runtime.

If you wish to include the entire Erlang VM with your release, and not worry
about the Erlang version running on your target server, under `rel/config.exs`
add/change the following code to:

```elixir
...
environment :prod do
  ...
  set include_erts: true
  ...
end
...
```

Build the release again after changing these values.

---

### Configure Server

AlloyCI uses environment variables to set up its configuration, so before starting
the server, make sure your environment is set up with the variables described
[above](#configuration). Also you need to set `REPLACE_OS_VARS=true` before starting
AlloyCI as well.

### Upload

Use any of the known methods to upload the `alloy_ci.tar.gz` file to your server,
like `scp`, `ftp`, `sftp`, etc.

Once uploaded, decompress it with `tar xfz alloy_ci.tar.gz`.

### Start

After decompressing the `alloy_ci.tar.gz` file, you can start AlloyCI with the
following commands:

- Interactive: `bin/alloy_ci console`
- Foreground: `bin/alloy_ci foreground`
- Daemon: `bin/alloy_ci start`

### Migrations

Database migrations are run automatically when the application starts, so there is
no need to run them manually.

### Artifacts

Build artifact files are uploaded to a directory called `uploads`. It will be created, if
it doesn't exist, and it lives at the root of where the release files were decompressed, so
the directory will look like this:

```
├── bin
├── lib
├── releases
└── uploads
```

## First Run

After installing AlloyCI, you will still need to setup an admin user for your
instance. In order to do this, go to `/register` to register a new account. Once
the account is ready, run the following command to open a remote console to the
database:

**Docker:**
```shell
$ docker exec -it <container_id> bin/alloy_ci remote_console
```

**Heroku:**
```shell
$ heroku run -a <app_name> "MIX_ENV=heroku iex -S mix"
```

**Manual:**
```shell
$ path/to/alloy_ci/bin/alloy_ci remote_console
```

Once the console is open, copy the following command to make the user you just
created an admin:

```elixir
AlloyCi.User |> AlloyCi.Repo.get(1) |> AlloyCi.User.make_admin!
```

Once the user has been made an admin, you'll have access to the admin menus on the
WebUI. You might need to re-authenticate yourself in order to access the admin area.

### Important Notice

Users that register on AlloyCI via the `/register` form **will** need to manually
link their GitHub account in order to use AlloyCI properly.

## Start using AlloyCI

Now that everything is set up, it is time to actually use AlloyCI. Adding projects
is quite easy via the WebUI, but before you add one, you will need to create the
configuration file needed for AlloyCI to know what to do with your project.

You need to add a [`.alloy-ci.yml`](yaml/) file to the root of your
project. You can read the full documentation to see all that available features, or
you can head over to the [examples](examples/) to see a basic `.alloy-ci.yml`
file for different programming languages and get a quick start.

### Runners

Without Runners, there is no machine to actually run your code. Head over to the
[Runners documentation](runners/) to see how you can install, register,
and configure your Runner for AlloyCI.

### What's next?

Once a project has been added, AlloyCI will be notified by GitHub whenever a new
push happens on your project. With this information, AlloyCI will proceed to create
a new pipeline and configure the build jobs found on the `.alloy-ci.yml` file.
