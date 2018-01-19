defmodule AlloyCi.Plugs.RawBody do
  @moduledoc """
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    mount = Keyword.get(opts, :mount)

    if mount in conn.path_info do
      raw_body(conn)
    else
      conn
    end
  end

  def raw_body(conn) do
    {:ok, body, _} = read_body(conn)
    put_private(conn, :raw_body, body)
  end
end
