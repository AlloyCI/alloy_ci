defmodule AlloyCi.Github.Test do
  @moduledoc """
  Test impelementation of the GitHub API behavior. It is a mock module that
  simulates the communication with the GitHub API.
  """
  @behaviour AlloyCi.Github

  def alloy_ci_config(_project, _pipeline) do
    contents = ".alloy-ci.json" |> File.read! |> :base64.encode
    %{"content" => contents}
  end

  def api_client(token) do
    case domain() do
      "github.com" ->
        Tentacat.Client.new(token)
      domain ->
        Tentacat.Client.new(token, "https://#{domain}/")
    end
  end

  def clone_url(project, pipeline) do
    token = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token["token"]}@#{domain()}/#{project.owner}/#{project.name}.git"
  end

  def installation_id_for(_) do
    2190
  end

  def integration_client do
    api_client(%{integration_jwt_token: "v1.1f699f1069f60xxx"})
  end

  def is_installed?(_) do
    true
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
      description: "Pipleine succeeded"
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
    fetch_repos(user)
  end

  def skip_ci?(commit_messsage) do
    String.match?(commit_messsage, ~r/\[skip ci\]/) ||
    String.match?(commit_messsage, ~r/\[ci skip\]/)
  end

  def sha_url(project, pipeline) do
    "https://#{domain()}/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end

  ###################
  # Private functions
  ###################
  defp domain do
    Application.get_env(:alloy_ci, :github_domain)
  end

  defp installation_token(_installation_id) do
    %{"token" => "v1.1f699f1069f60xxx"}
  end

  defp notify!(_project, _pipeline, _params) do
    {201, :ok}
  end
end
