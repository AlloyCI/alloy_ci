defmodule AlloyCi.Mixfile do
  @moduledoc """
  """
  use Mix.Project

  @version "0.9.1"

  def project do
    [
      app: :alloy_ci,
      version: @version,
      elixir: "~> 1.9",
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
      mod: {AlloyCi.App, []},
      extra_applications: [:elixir_make, :logger, :mix, :parse_trans]
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
      {:arc, "~> 0.11"},
      {:arc_ecto, "~> 0.11"},
      {:bamboo, "~> 1.4"},
      {:bamboo_smtp, "~> 1.4"},
      {:bcrypt_elixir, "~> 1.0"},
      {:comeonin, "~> 4.1"},
      {:cowboy, "~> 2.5"},
      {:distillery, "~> 2.0"},
      {:ecto, "~> 3.0", override: true},
      {:ecto_sql, "~> 3.0", override: true},
      {:ex_aws, "~> 2.1", override: true},
      {:ex_aws_s3, "~> 2.0"},
      {:gettext, "~> 0.15"},
      {:gravatar, "~> 0.1.0"},
      {:guardian_db, "~> 2.0", github: "ueberauth/guardian_db"},
      {:httpoison, "~> 1.0"},
      {:hackney, "~> 1.13", override: true},
      {:jason, "~> 1.1"},
      {:joken, "~> 1.5"},
      {:kerosene, "~> 0.9", github: "AlloyCI/kerosene"},
      {:mojito, "~> 0.7.1"},
      {:phoenix, "~> 1.4.0", override: true},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:secure_random, "~> 0.5"},
      {:sentry, "~> 7.0"},
      {:sweet_xml, "~> 0.6"},
      {:tentacat, "~> 1.0"},
      {:timex, "~> 3.3"},
      {:ueberauth_github, "~> 0.7"},
      {:ueberauth_identity, "~> 0.3.0"},
      {:yaml_elixir, "~> 2.1", github: "AlloyCI/yaml-elixir"},

      # Test and Dev dependencies
      {:excoveralls, "~> 0.9", only: :test},
      {:ex_machina, "~> 2.2", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.1", only: :dev}
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
      routes: ["phx.routes AlloyCi.Web.Router"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      sentry_recompile: ["deps.compile sentry --force", "compile"]
    ]
  end
end
