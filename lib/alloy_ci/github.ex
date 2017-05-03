defmodule AlloyCi.Github do
  @moduledoc """
  """
  import Ecto.Query, warn: false
  alias AlloyCi.{Pipelines, Repo}

  def clone_url(project, pipeline) do
    token = Pipelines.installation_token(pipeline)

    "https://x-access-token:#{token["token"]}@#{domain()}/#{project.owner}/#{project.name}.git"
  end

  def sha_url(project, pipeline) do
    "https://#{domain()}/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end

  def domain do
    Application.get_env(:alloy_ci, :github_domain)
  end

  def api_client(token) do
    case domain() do
      "github.com" = _ ->
        Tentacat.Client.new(token)
      domain ->
        Tentacat.Client.new(token, "https://#{domain}/")
    end
  end

  def repos_for(user) do
    query = from auth in "authentications",
              where: auth.user_id == ^user.id and auth.provider == "github",
              select: auth.token
    token = Repo.one(query)
    client = api_client(%{access_token: token})
    Tentacat.Repositories.list_mine(client, sort: "pushed")
  end
end
