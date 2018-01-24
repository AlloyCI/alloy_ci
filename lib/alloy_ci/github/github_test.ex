defmodule AlloyCi.Github.Test do
  @moduledoc """
  Test implementation of the GitHub API behavior. It is a mock module that
  simulates the communication with the GitHub API.
  """
  @behaviour AlloyCi.Github

  def alloy_ci_config(_project, _pipeline) do
    contents = ".alloy-ci.json" |> File.read!() |> :base64.encode()
    %{"content" => contents}
  end

  def app_client do
    Tentacat.Client.new(%{jwt: "v1.1f699f1069f60xxx"})
  end

  def clone_url(project, pipeline) do
    token = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token["token"]}@github.com/#{project.owner}/#{project.name}.git"
  end

  def commit(_, sha, _) do
    %{"sha" => sha, "commit" => %{"message" => "test commit"}}
  end

  def installation_id_for(_) do
    2190
  end

  def fetch_repos(_token) do
    Poison.decode!(File.read!("test/fixtures/responses/repositories_list.json"))
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

  def pull_request(_project, _pr_number, _installation_id) do
    Poison.decode!(File.read!("test/fixtures/responses/test_pull_response.json"))
  end

  def repos_for(user) do
    fetch_repos(user)
  end

  def skip_ci?(commit_message) do
    String.match?(commit_message, ~r/\[skip ci\]/) ||
      String.match?(commit_message, ~r/\[ci skip\]/)
  end

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
    {201, :ok}
  end
end
