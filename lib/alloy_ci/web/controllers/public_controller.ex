defmodule AlloyCi.Web.PublicController do
  use AlloyCi.Web, :controller

  plug :put_layout, "public_layout.html"
  plug :put_layout, "register_layout.html" when action in [:register]

  def index(conn, _params, current_user, _claims) do
    render conn, "index.html", current_user: current_user
  end

  def register(conn, _params, current_user, _claims) do
    render conn, "register.html", current_user: current_user
  end
end
