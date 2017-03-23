# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :alloy_ci,
  ecto_repos: [AlloyCi.Repo]

# Configures the endpoint
config :alloy_ci, AlloyCi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ihHz/ZrHEy2bZF/T3ROjOy01oYwWg5Oe9Egv4sGmcEJJntCnlGAgryfi+AFzAm2x",
  render_errors: [view: AlloyCi.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AlloyCi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
