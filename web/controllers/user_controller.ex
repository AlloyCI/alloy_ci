defmodule AlloyCi.UserController do
  use AlloyCi.Web, :controller

  plug :put_layout, "register_layout.html"

  def new(conn, _params, current_user, _claims) do
    render conn, "new.html", current_user: current_user
  end
end
