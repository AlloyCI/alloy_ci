defmodule AlloyCi.Github.Live do
  @moduledoc """
  Production implementation of the GitHub API behaviour. All interaction with
  the GitHub API goes through this module.
  """
  @behaviour AlloyCi.Github

  import Ecto.Query, warn: false
  alias AlloyCi.Repo
  import Joken

  def alloy_ci_config(project, pipeline) do
    client = installation_client(pipeline)
    Tentacat.Contents.find_in(project.owner, project.name, ".alloy-ci.json", pipeline.sha, client)
  end

  def clone_url(project, pipeline) do
    token = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token["token"]}@github.com/#{project.owner}/#{project.name}.git"
  end

  def fetch_repos(token) do
    client = Tentacat.Client.new(%{access_token: token})
    Tentacat.Repositories.list_mine(client, sort: "pushed")
  end

  def installation_id_for(github_uid) do
    github_uid
    |> filter_installations()
    |> List.first
    |> Map.get("id")
  end

  def integration_client do
    key = JOSE.JWK.from_pem(Application.get_env(:alloy_ci, :private_key))
    integration_id = Application.get_env(:alloy_ci, :integration_id)

    payload = %{
      "iat" => DateTime.utc_now |> Timex.to_unix,
      "exp" => Timex.now |> Timex.shift(minutes: 9) |> Timex.to_unix,
      "iss" => String.to_integer(integration_id)
    }

    signed_jwt = payload |> token() |> sign(rs256(key)) |> get_compact()

    Tentacat.Client.new(%{integration_jwt_token: signed_jwt})
  end

  def is_installed?(github_uid) do
    result = filter_installations(github_uid)
    !Enum.empty?(result)
  end

  def list_installations do
    client = integration_client()
    Tentacat.Integrations.Installations.app_installations(client)
  end

  def notify_cancelled!(project, pipeline) do
    params = %{
      state: "error",
      description: "Pipeline has been cancelled"
    }

    notify!(project, pipeline, params)
  end

  def notify_pending!(project, pipeline) do
    params = %{
      state: "pending",
      description: "Pipeline is pending"
    }

    notify!(project, pipeline, params)
  end

  def notify_success!(project, pipeline) do
    params = %{
      state: "success",
      description: "Pipeline succeeded"
    }

    notify!(project, pipeline, params)
  end

  def notify_failure!(project, pipeline) do
    params = %{
      state: "failure",
      description: "Pipeline failed"
    }

    notify!(project, pipeline, params)
  end

  def repos_for(user) do
    query = from auth in "authentications",
            where: auth.user_id == ^user.id and auth.provider == "github",
            select: auth.token
    token = Repo.one(query)
    fetch_repos(token)
  end

  def skip_ci?(commit_messsage) do
    String.match?(commit_messsage, ~r/\[skip ci\]/) ||
    String.match?(commit_messsage, ~r/\[ci skip\]/)
  end

  def sha_url(project, pipeline) do
    "https://github.com/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end

  ###################
  # Private functions
  ###################
  defp filter_installations(github_uid) do
    Enum.reject(list_installations(), fn installation ->
      installation["account"]["login"] != github_uid
    end)
  end

  defp installation_client(pipeline) do
    token = installation_token(pipeline.installation_id)
    Tentacat.Client.new(%{access_token: token["token"]})
  end

  defp installation_token(installation_id) do
    client = integration_client()
    {_, response} = Tentacat.Integrations.Installations.get_token(client, installation_id)
    response
  end

  defp notify!(project, pipeline, params) do
    base = %{
      target_url: pipeline_url(project, pipeline),
      context: "ci/alloy-ci"
    }
    params = Map.merge(params, base)
    client = installation_client(pipeline)

    Tentacat.Repositories.Statuses.create(
      project.owner, project.name, pipeline.sha, params, client
    )
  end

  defp pipeline_url(project, pipeline) do
    base_url = Application.get_env(:alloy_ci, :server_url)

    "#{base_url}/projects/#{project.id}/pipelines/#{pipeline.id}"
  end
end
