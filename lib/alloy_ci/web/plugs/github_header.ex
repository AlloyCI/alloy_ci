defmodule AlloyCi.Plugs.GithubHeader do
  @moduledoc """
  This Plug extracts the X-Github-Event header from a request, and stores it
  within conn's assigns, so we can pattern match it on our controller.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    [event] = get_req_header(conn, "x-github-event")
    assign(conn, :github_event, event)
  end
end
