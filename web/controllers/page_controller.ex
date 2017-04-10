defmodule AlloyCi.PageController do
  use AlloyCi.Web, :controller

  plug :put_layout, "public_layout.html"

  def index(conn, _params, current_user, _claims) do
    render conn, "index.html", current_user: current_user
  end
end
