defmodule AlloyCi.PageController do
  use AlloyCi.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
