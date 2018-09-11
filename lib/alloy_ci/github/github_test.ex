defmodule AlloyCi.Github.Test do
  @moduledoc """
  Test implementation of the GitHub API behavior. It is a mock module that
  simulates the communication with the GitHub API.
  """
  @behaviour AlloyCi.Github

  alias AlloyCi.{Pipeline, Project}

  @spec alloy_ci_config(any(), any()) :: %{optional(<<_::56>>) => binary()}
  def alloy_ci_config(_project, _pipeline) do
    contents = ".alloy-ci.yml" |> File.read!() |> :base64.encode()
    %{"content" => contents}
  end

  @spec app_auth_url() :: binary()
  def app_auth_url do
    "https://github.com/settings/connections/applications/" <> System.get_env("GITHUB_CLIENT_ID")
  end

  @spec app_client() :: Tentacat.Client.t()
  def app_client do
    Tentacat.Client.new(%{jwt: "v1.1f699f1069f60xxx"})
  end

  @spec clone_url(Project.t(), Pipeline.t()) :: binary()
  def clone_url(project, pipeline) do
    %{"token" => token} = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token}@github.com/#{project.owner}/#{project.name}.git"
  end

  @spec commit(any(), any(), any()) :: map()
  def commit(_, sha, _) do
    %{"sha" => sha, "commit" => %{"message" => "test commit"}}
  end

  @spec installation_id_for(any()) :: pos_integer()
  def installation_id_for(_) do
    2190
  end

  @spec fetch_repos(binary()) :: any()
  def fetch_repos(_token) do
    Poison.decode!(File.read!("test/fixtures/responses/repositories_list.json"))
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
  def pull_request(_project, _pr_number, _installation_id) do
    Poison.decode!(File.read!("test/fixtures/responses/test_pull_response.json"))
  end

  @spec skip_ci?(binary()) :: boolean()
  def skip_ci?(commit_message) do
    String.match?(commit_message, ~r/\[skip ci\]/) ||
      String.match?(commit_message, ~r/\[ci skip\]/)
  end

  @spec sha_url(Project.t(), Pipeline.t()) :: binary()
  def sha_url(project, pipeline) do
    "https://github.com/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end

  ###################
  # Private functions
  ###################
  defp installation_token(_installation_id) do
    %{"token" => "v1.1f699f1069f60xxx"}
  end

  defp notify!(_project, _pipeline, _params) do
    {201, :ok, :ok}
  end
end
