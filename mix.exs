defmodule AlloyCi.Mixfile do
  @moduledoc """
  """
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :alloy_ci,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() in [:prod, :heroku],
      start_permanent: Mix.env() in [:prod, :heroku],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AlloyCi.Application, []},
      applications: applications(Mix.env())
    ]
  end

  def applications(:test) do
    applications(:default) ++ [:ex_machina]
  end

  def applications(_) do
    [
      :bamboo,
      :bamboo_smtp,
      :comeonin,
      :cowboy,
      :elixir_make,
      :ex_utils,
      :gettext,
      :gravatar,
      :guardian,
      :guardian_db,
      :joken,
      :kerosene,
      :logger,
      :mix,
      :mix_docker,
      :phoenix,
      :phoenix_ecto,
      :phoenix_html,
      :phoenix_pubsub,
      :postgrex,
      :secure_random,
      :timex,
      :tentacat,
      :ueberauth,
      :ueberauth_github,
      :ueberauth_identity,
      :que
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4"},
      {:comeonin, "~> 3.0"},
      {:cowboy, "~> 1.1"},
      {:gettext, "~> 0.11"},
      {:gravatar, "~> 0.1.0"},
      {:guardian_db, "~> 0.8"},
      {:httpoison, "~> 0.12"},
      {:joken, "~> 1.5"},
      {:kerosene, "~> 0.7"},
      {:mix_docker, "~> 0.5"},
      {:phoenix, "~> 1.3", override: true},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_pubsub, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},
      {:secure_random, "~> 0.5"},
      {:tentacat, "~> 0.8"},
      {:timex, "~> 3.1"},
      {:ueberauth_github, "~> 0.5", github: "ueberauth/ueberauth_github"},
      {:ueberauth_identity, "~> 0.2.3"},
      {:que, "~> 0.4.1", github: "AlloyCI/que"},

      # Test and Dev dependencies
      {:excoveralls, "~> 0.7", only: :test},
      {:ex_machina, "~> 2.0", github: "thoughtbot/ex_machina", only: [:dev, :test]},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.0", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
