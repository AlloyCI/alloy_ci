# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :alloy_ci,
  ecto_repos: [AlloyCi.Repo],
  github_api: AlloyCi.Github.Live,
  github_domain: System.get_env("GITHUB_DOMAIN"),
  integration_id: System.get_env("GITHUB_INTEGRATION_ID"),
  private_key: System.get_env("GITHUB_PRIVATE_KEY"),
  runner_registration_token: System.get_env("RUNNER_REGISTRATION_TOKEN"),
  server_url: System.get_env("SERVER_URL")

# Configures the endpoint
config :alloy_ci, AlloyCi.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: AlloyCi.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AlloyCi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Uberauth GitHub
config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user,repo"]},
    identity: {Ueberauth.Strategy.Identity, [callback_methods: ["POST"]]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

# Configures Guardian
config :guardian, Guardian,
  issuer: "AlloyCi.#{Mix.env}",
  ttl: {30, :days},
  verify_issuer: true,
  serializer: AlloyCi.GuardianSerializer,
  secret_key: System.get_env("SECRET_KEY_BASE"),
  hooks: GuardianDb,
  permissions: %{
    default: [
      :read_profile,
      :write_profile,
      :read_token,
      :revoke_token,
    ],
  }

config :guardian_db, GuardianDb,
  repo: AlloyCi.Repo,
  sweep_interval: 60 # 60 minutes

config :exq,
  name: Exq,
  url: System.get_env("REDIS_URL"),
  concurrency: :infinite,
  queues: ["default"],
  poll_timeout: 50,
  scheduler_poll_timeout: 200,
  scheduler_enable: true,
  max_retries: 25,
  shutdown_timeout: 5000

config :exq_ui,
  server: false

config :tentacat,
  :extra_headers, [{"Accept", "application/vnd.github.machine-man-preview+json"}]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
