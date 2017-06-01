defmodule AlloyCi.Web.BuildsChannel do
  @moduledoc """
  """
  use AlloyCi.Web, :channel

  def join("builds:" <> build_id, payload, socket) do
    {:ok, socket}
  end

  def send_trace(build_id, trace) do
    AlloyCi.Web.Endpoint.broadcast("builds:#{build_id}", "append_trace", %{trace: trace})
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (builds:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
