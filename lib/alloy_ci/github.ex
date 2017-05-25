defmodule AlloyCi.Github do
  @moduledoc """
  """
  import Ecto.Query, warn: false
  alias AlloyCi.Repo
  import Joken
  use Timex

  def alloy_ci_config(project, pipeline) do
    token = installation_token(pipeline.installation_id)
    client = api_client(%{access_token: token["token"]})
    Tentacat.Contents.find_in(project.owner, project.name, ".alloy-ci.json", pipeline.sha, client)
  end

  def api_client(token) do
    case domain() do
      "github.com" = _ ->
        Tentacat.Client.new(token)
      domain ->
        Tentacat.Client.new(token, "https://#{domain}/")
    end
  end

  def clone_url(project, pipeline) do
    token = installation_token(pipeline.installation_id)

    "https://x-access-token:#{token["token"]}@#{domain()}/#{project.owner}/#{project.name}.git"
  end

  def domain do
    Application.get_env(:alloy_ci, :github_domain)
  end

  def fetch_repos(token) do
    client = api_client(%{access_token: token})
    Tentacat.Repositories.list_mine(client, sort: "pushed")
  end

  def installation_token(installation_id) do
    key = JOSE.JWK.from_pem(Application.get_env(:alloy_ci, :private_key))
    integration_id = Application.get_env(:alloy_ci, :integration_id)

    payload = %{
      "iat" => DateTime.utc_now |> Timex.to_unix,
      "exp" => Timex.now |> Timex.shift(minutes: 9) |> Timex.to_unix,
      "iss" => String.to_integer(integration_id)
    }

    signed_jwt = payload |> token() |> sign(rs256(key)) |> get_compact()

    client = api_client(%{integration_jwt_token: signed_jwt})
    {_, response} = Tentacat.Integrations.Installations.get_token(client, installation_id)
    response
  end

  def repos_for(user) do
    query = from auth in "authentications",
              where: auth.user_id == ^user.id and auth.provider == "github",
              select: auth.token
    token = Repo.one(query)
    fetch_repos(token)
  end

  def skip_ci?(commit_messsage) do
    String.match?(commit_messsage, ~r/\[skip ci\]/) || String.match?(commit_messsage, ~r/\[ci skip\]/)
  end

  def sha_url(project, pipeline) do
    "https://#{domain()}/#{project.owner}/#{project.name}/commit/#{pipeline.sha}"
  end
end
