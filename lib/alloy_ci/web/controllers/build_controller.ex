defmodule AlloyCi.Web.BuildController do
  use AlloyCi.Web, :controller
  alias AlloyCi.Builds
  plug EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access"

  def show(conn, %{"id" => id, "project_id" => project_id}, current_user, _) do
    build = Builds.get_build(id, project_id, current_user)
    conn
    |> put_status(200)
    |> json(%{trace: build.trace})
  end
end
