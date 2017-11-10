defmodule AlloyCi.Web.ReposChannel do
  @moduledoc """
  """
  use AlloyCi.Web, :channel
  alias AlloyCi.Web.Endpoint

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (repos:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def join("repos:" <> _user_id, _payload, socket) do
    {:ok, socket}
  end

  def ready(user_id, content) do
    Endpoint.broadcast(
      "repos:#{user_id}",
      "repos_ready",
      %{html: content}
    )
  end
end
