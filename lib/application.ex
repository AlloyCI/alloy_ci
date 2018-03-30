defmodule AlloyCi.Application do
  @moduledoc """
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    setup_config()
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlloyCi.Supervisor]
    Supervisor.start_link(children(Mix.env()), opts)
  end

  def children(env) when env != "test" do
    import Supervisor.Spec, warn: false
    children()
  end

  def children do
    import Supervisor.Spec
    # Define workers and child supervisors to be supervised
    [
      # Start the Ecto repository
      supervisor(AlloyCi.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AlloyCi.Web.Endpoint, []),
      worker(Guardian.DB.Token.SweeperServer, []),
      worker(AlloyCi.ArtifactSweeper, [System.get_env("ARTIFACT_SWEEP_INTERVAL")])
      # Start your own worker by calling: AlloyCi.Worker.start_link(arg1, arg2, arg3)
      # worker(AlloyCi.Worker, [arg1, arg2, arg3]),
    ]
  end

  defp setup_config do
    github_oauth_config()
  end

  defp github_oauth_config do
    defaults = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Github.OAuth)

    if System.get_env("GITHUB_ENTERPRISE") do
      Application.put_env(
        :ueberauth,
        Ueberauth.Strategy.Github.OAuth,
        Keyword.merge(
          defaults,
          authorize_url: System.get_env("GITHUB_ENDPOINT") <> "/login/oauth/authorize",
          token_url: System.get_env("GITHUB_ENDPOINT") <> "/login/oauth/access_token",
          site: System.get_env("GITHUB_ENDPOINT") <> "/api/v3"
        )
      )

      Application.put_env(
        :alloy_ci,
        AlloyCi.Github,
        endpoint_api: System.get_env("GITHUB_ENDPOINT") <> "/api/v3",
        endpoint: System.get_env("GITHUB_ENDPOINT")
      )
    end
  end
end
