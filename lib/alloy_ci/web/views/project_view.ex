defmodule AlloyCi.Web.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Authentication, Repo}
  import Ecto.Query

  def has_github_auth(user) do
    case fetch_auth(user) do
      %Authentication{} = _ -> true
      _ -> false
    end

  end

  defp fetch_auth(user) do
    Authentication
    |> where(user_id: ^user.id)
    |> where(provider: "github")
    |> Repo.one
  end
end
