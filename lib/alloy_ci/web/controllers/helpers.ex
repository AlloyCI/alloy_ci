defmodule AlloyCi.Web.Controller.Helpers do
  @moduledoc false
  import Plug.Conn

  def redirect_back(conn, alternative \\ "/") do
    path =
      conn
      |> get_req_header("referrer")
      |> referrer

    path || alternative
  end

  defp referrer([]), do: nil
  defp referrer([h | _]), do: h
end
