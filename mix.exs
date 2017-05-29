defmodule AlloyCi.Mixfile do
  @moduledoc """
  """
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :alloy_ci,
     version: @version,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AlloyCi.Application, []},
      applications: applications(Mix.env)
    ]
  end

  def applications(env) when env in [:test] do
    applications(:default) ++ [:ex_machina]
  end

  def applications(_) do
    [
      :comeonin,
      :cowboy,
      :exq,
      :exq_ui,
      :gettext,
      :logger,
      :phoenix,
      :phoenix_ecto,
      :phoenix_html,
      :phoenix_pubsub,
      :postgrex,
      :ueberauth,
      :ueberauth_github,
      :ueberauth_identity,
      :timex,
      :tentacat
    ]
  end

  def version do
    @version
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:comeonin, "~> 3.0"},
      {:cowboy, "~> 1.0"},
      {:exq, "~> 0.8.6"},
      {:exq_ui, "~> 0.8.6"},
      {:gettext, "~> 0.11"},
      {:gravatar, "~> 0.1.0"},
      {:guardian_db, "~> 0.8"},
      {:joken, "~> 1.4"},
      {:phoenix, "~> 1.3.0-rc", override: true},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_pubsub, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},
      {:secure_random, "~> 0.5"},
      {:tentacat, "~> 0.6", github: "supernova32/tentacat"},
      {:timex, "~> 3.1"},
      {:ueberauth_github, "~> 0.4"},
      {:ueberauth_identity, "~> 0.2.3"},

      # Test and Dev dependencies
      {:excoveralls, "~> 0.6", only: :test},
      {:ex_machina, "~> 2.0", only: [:dev, :test]},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
