defmodule AlloyCi.App do
  @moduledoc """
  Main entry point for the AlloyCI OTP application
  """
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    setup_config()
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    children = [
      AlloyCi.Repo,
      AlloyCi.Web.Endpoint,
      AlloyCi.BackgroundScheduler,
      Guardian.DB.Token.SweeperServer,
      {AlloyCi.ArtifactSweeper, System.get_env("ARTIFACT_SWEEP_INTERVAL")},
      AlloyCi.BuildsTraceCache,
      {Task.Supervisor, name: AlloyCi.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: AlloyCi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Set up runtime related configuration
  """
  def setup_config do
    arc_storage_config()
    github_oauth_config()
  end

  defp arc_storage_config do
    if System.get_env("S3_STORAGE_ENABLED") do
      Application.put_env(:arc, :storage, Arc.Storage.S3)
      Application.put_env(:arc, :bucket, System.get_env("S3_BUCKET_NAME") || "uploads")

      ex_aws_config()
    end
  end

  defp ex_aws_config do
    base = %{
      access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
      secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY")
    }

    if System.get_env("S3_HOST") do
      config =
        Map.merge(
          %{
            scheme: System.get_env("S3_HTTP_SCHEME"),
            host: %{"custom" => System.get_env("S3_HOST")},
            port: System.get_env("S3_PORT"),
            region: "custom"
          },
          base
        )

      Application.put_env(:ex_aws, :s3, config)
    else
      Application.put_env(
        :ex_aws,
        :s3,
        Map.merge(%{region: System.get_env("S3_REGION") || "us-east-1"}, base)
      )
    end
  end

  defp github_oauth_config do
    base = [
      client_id: System.get_env("GITHUB_CLIENT_ID"),
      client_secret: System.get_env("GITHUB_CLIENT_SECRET")
    ]

    if System.get_env("GITHUB_ENTERPRISE") do
      Application.put_env(
        :ueberauth,
        Ueberauth.Strategy.Github.OAuth,
        Keyword.merge(
          base,
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
    else
      Application.put_env(:ueberauth, Ueberauth.Strategy.Github.OAuth, base)
    end
  end
end
