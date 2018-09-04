defmodule AlloyCi.Github.Live do
  @moduledoc """
  Production implementation of the GitHub API behaviour. All interaction with
  the GitHub API goes through this module.
  """
  @behaviour AlloyCi.Github

  import Ecto.Query, warn: false
  import Joken
  alias AlloyCi.{Pipeline, Project}

  @spec alloy_ci_config(Project.t(), Pipeline.t()) :: map()
  def alloy_ci_config(project, pipeline) do
    pipeline.installation_id
    |> installation_client()
    |> Tentacat.Contents.find_in(project.owner, project.name, ".alloy-ci.yml", pipeline.sha)
    |> access_body()
  end

  @spec app_client() :: Tentacat.Client.t()
  def app_client do
    key = JOSE.JWK.from_pem(Application.get_env(:alloy_ci, :private_key))
    app_id = Application.get_env(:alloy_ci, :app_id)

    payload = %{
      "iat" => DateTime.utc_now() |> Timex.to_unix(),
      "exp" => Timex.now() |> Timex.shift(minutes: 9) |> Timex.to_unix(),
      "iss" => String.to_integer(app_id)
    }

    signed_jwt = payload |> token() |> sign(rs256(key)) |> get_compact()

    Tentacat.Client.new(%{jwt: signed_jwt}, endpoint())
  end

  @spec clone_url(Project.t(), Pipeline.t()) :: binary()
  def clone_url(project, pipeline) do
    %{"token" => token} = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token}@#{clone_domain()}/#{project.owner}/#{project.name}.git"
  end

  @spec commit(Project.t(), any(), integer()) :: map()
  def commit(project, sha, installation_id) do
    installation_id
    |> installation_client()
    |> Tentacat.Commits.find(sha, project.owner, project.name)
    |> access_body()
  end

  @spec fetch_repos(binary()) :: any()
  def fetch_repos(token) do
    %{access_token: token}
    |> Tentacat.Client.new(endpoint())
    |> Tentacat.Repositories.list_mine(sort: "pushed")
  end

  @spec installation_id_for(any()) :: pos_integer()
  def installation_id_for(github_uid) do
    github_uid
    |> filter_installations()
    |> List.first()
    |> Map.get("id")
  end

  @spec list_installations() :: map()
  def list_installations do
    app_client()
    |> Tentacat.App.Installations.list_mine()
    |> access_body()
  end

  @spec notify_cancelled!(Project.t(), Pipeline.t()) :: any()
  def notify_cancelled!(project, pipeline) do
    params = %{
      state: "error",
      description: "Pipeline has been cancelled"
    }

    notify!(project, pipeline, params)
  end

  @spec notify_failure!(Project.t(), Pipeline.t()) :: any()
  def notify_failure!(project, pipeline) do
    params = %{
      state: "failure",
      description: "Pipeline failed"
    }

    notify!(project, pipeline, params)
  end

  @spec notify_pending!(Project.t(), Pipeline.t()) :: any()
  def notify_pending!(project, pipeline) do
    params = %{
      state: "pending",
      description: "Pipeline is pending"
    }

    notify!(project, pipeline, params)
  end

  @spec notify_success!(Project.t(), Pipeline.t()) :: any()
  def notify_success!(project, pipeline) do
    params = %{
      state: "success",
      description: "Pipeline succeeded"
    }

    notify!(project, pipeline, params)
  end

  @spec pull_request(Project.t(), binary() | integer(), integer()) :: map()
  def pull_request(project, pr_number, installation_id) do
    installation_id
    |> installation_client()
    |> Tentacat.Pulls.find(project.owner, project.name, pr_number)
    |> access_body()
  end

  @spec skip_ci?(binary()) :: boolean()
  def skip_ci?(commit_message) do
    String.match?(commit_message, ~r/\[skip ci\]/) ||
      String.match?(commit_message, ~r/\[ci skip\]/)
  end

  @spec sha_url(Project.t(), Pipeline.t()) :: binary()
  def sha_url(project, pipeline) do
    "#{github_url()}/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end

  ###################
  # Private functions
  ###################
  defp access_body(response), do: elem(response, 1)

  defp clone_domain do
    String.replace(github_url(), "https://", "")
  end

  defp endpoint do
    (Application.get_env(:alloy_ci, AlloyCi.Github) || [])
    |> Keyword.get(:endpoint_api, "https://api.github.com/")
  end

  defp github_url do
    (Application.get_env(:alloy_ci, AlloyCi.Github) || [])
    |> Keyword.get(:endpoint, "https://github.com")
  end

  defp filter_installations(github_uid) do
    Enum.reject(list_installations(), fn installation ->
      installation["target_id"] != String.to_integer(github_uid)
    end)
  end

  defp installation_client(installation_id) do
    %{"token" => token} = installation_token(installation_id)
    Tentacat.Client.new(%{access_token: token}, endpoint())
  end

  defp installation_token(installation_id) do
    app_client()
    |> Tentacat.App.Installations.token(installation_id)
    |> access_body()
  end

  defp notify!(project, pipeline, params) do
    base = %{
      target_url: pipeline_url(project, pipeline),
      context: "ci/alloy-ci"
    }

    params = Map.merge(params, base)

    pipeline.installation_id
    |> installation_client()
    |> Tentacat.Repositories.Statuses.create(
      project.owner,
      project.name,
      pipeline.sha,
      params
    )
  end

  defp pipeline_url(project, pipeline) do
    base_url = Application.get_env(:alloy_ci, :server_url)

    "#{base_url}/projects/#{project.id}/pipelines/#{pipeline.id}"
  end
end
