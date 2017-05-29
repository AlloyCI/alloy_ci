defmodule AlloyCi.Github.Test do
  @moduledoc """
  """
  import Ecto.Query, warn: false
  alias AlloyCi.Repo

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

  def installation_client(pipeline) do
    token = installation_token(pipeline.installation_id)
    api_client(%{access_token: token["token"]})
  end

  def clone_url(project, pipeline) do
    token = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token["token"]}@#{domain()}/#{project.owner}/#{project.name}.git"
  end

  def domain do
    Application.get_env(:alloy_ci, :github_domain)
  end

  def fetch_repos(_token) do
    Poison.decode!(File.read!("test/fixtures/responses/repositories_list.json"))
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
    "https://#{domain()}/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end

  defp installation_token(_installation_id) do
    %{"token" => "v1.1f699f1069f60xxx"}
  end

  defp notify!(_project, _pipeline, _params) do
    {201, :ok}
  end

  defp pipeline_url(project, pipeline) do
    base_url = Application.get_env(:alloy_ci, :server_url)

    "#{base_url}/projects/#{project.id}/pipelines/#{pipeline.id}"
  end
end
