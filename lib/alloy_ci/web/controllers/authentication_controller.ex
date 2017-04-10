defmodule AlloyCi.Web.AuthenticationController do
  use AlloyCi.Web, :controller

  alias AlloyCi.Accounts

  plug EnsureAuthenticated, handler: AlloyCi.Web.AuthController, typ: "access"

  def index(conn, _params, current_user, _claims) do
    render(conn, "index.html", current_user: current_user,
           authentications: Accounts.authentications(current_user))
  end
end
