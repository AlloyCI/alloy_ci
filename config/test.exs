use Mix.Config

# General application configuration
config :alloy_ci,
  ecto_repos: [AlloyCi.Repo],
  github_api: AlloyCi.Github.Test,
  app_id: "1",
  app_url: "https://github.com/alloy-ci",
  private_key: "priv-key",
  runner_registration_token: "lustlmc3gMl59smZ",
  server_url: "https://alloy-ci.com"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :alloy_ci, AlloyCi.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configures Notifiers
config :alloy_ci, AlloyCi.Notifier,
  slack: "false",
  email: "false"

# Configure your database
config :alloy_ci, AlloyCi.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 10 * 60 * 1000
