defmodule AlloyCi.Mixfile do
  @moduledoc """
  """
  use Mix.Project

  def project do
    [app: :alloy_ci,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
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
      :phoenix,
      :phoenix_pubsub,
      :phoenix_html,
      :cowboy,
      :logger,
      :gettext,
      :phoenix_ecto,
      :postgrex,
      :ueberauth,
      :ueberauth_github,
      :ueberauth_identity,
      :tentacat,
      :comeonin
    ]
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
      {:phoenix, "~> 1.3.0-rc", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:gravatar, "~> 0.1.0"},
      {:cowboy, "~> 1.0"},
      {:guardian_db, "~> 0.8"},
      {:ueberauth_identity, "~> 0.2.3"},
      {:ueberauth_github, "~> 0.4"},
      {:tentacat, "~> 0.5"},
      {:ex_machina, "~> 2.0", only: [:dev, :test]},
      {:exvcr, "~> 0.8", only: :test},
      {:credo, "~> 0.3", only: [:dev, :test]}
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
