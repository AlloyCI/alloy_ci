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
  app_id: System.get_env("GITHUB_APP_ID"),
  app_url: System.get_env("GITHUB_APP_URL"),
  private_key: System.get_env("GITHUB_PRIVATE_KEY"),
  runner_registration_token: System.get_env("RUNNER_REGISTRATION_TOKEN"),
  server_url: System.get_env("SERVER_URL")

config :alloy_ci, AlloyCi.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: AlloyCi.Web.ErrorView, accepts: ~w(html json)],
  pubsub_server: AlloyCi.PubSub

config :arc, storage: Arc.Storage.Local

config :kerosene, theme: :bootstrap4

config :phoenix, :json_library, Jason

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, [default_scope: "user,repo"]},
    identity: {Ueberauth.Strategy.Identity, [callback_methods: ["POST"]]}
  ]

config :alloy_ci, AlloyCi.Guardian,
  issuer: "AlloyCi.#{Mix.env()}",
  ttl: {30, :days},
  verify_issuer: true,
  secret_key: System.get_env("SECRET_KEY_BASE")

config :guardian, Guardian.DB,
  repo: AlloyCi.Repo,
  # 60 minutes
  sweep_interval: 60

config :tentacat, :extra_headers, [{"Accept", "application/vnd.github.machine-man-preview+json"}]

# Configures Notifiers
config :alloy_ci, AlloyCi.Notifier,
  slack: System.get_env("ENABLE_SLACK_NOTIFICATIONS"),
  email: System.get_env("ENABLE_EMAIL_NOTIFICATIONS")

# Configures Email Settings
config :alloy_ci, AlloyCi.Notifiers.Email,
  adapter: Bamboo.LocalAdapter,
  from_address: "info@alloy-ci.com",
  reply_to_address: "no-reply@alloy-ci.com"

# Configures Slack settings
config :alloy_ci, AlloyCi.Notifiers.Slack,
  channel: System.get_env("SLACK_CHANNEL"),
  service_name: System.get_env("SLACK_SERVICE_NAME"),
  hook_url: System.get_env("SLACK_HOOK_URL"),
  icon_emoji: System.get_env("SLACK_ICON")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
