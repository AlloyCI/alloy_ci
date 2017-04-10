defmodule AlloyCi.AuthenticationController do
  use AlloyCi.Web, :controller

  plug EnsureAuthenticated, handler: AlloyCi.AuthController, typ: "access"

  alias AlloyCi.Repo

  def index(conn, _params, current_user, _claims) do
    render conn, "index.html", current_user: current_user, authentications: authentications(current_user)
  end

  defp authentications(user) do
    user = user |> Repo.preload(:authentications)
    user.authentications
  end
end
