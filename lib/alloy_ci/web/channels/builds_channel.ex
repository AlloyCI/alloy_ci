defmodule AlloyCi.Web.BuildsChannel do
  @moduledoc """
  """
  alias AlloyCi.{Builds, Projects}
  use AlloyCi.Web, :channel

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

  def join("builds:" <> build_id, _payload, socket) do
    build = Builds.get(build_id)

    if Projects.can_access?(build.project_id, %{id: socket.assigns.user_id}) do
      {:ok, socket}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  def replace_trace(build_id, trace) do
    AlloyCi.Web.Endpoint.broadcast("builds:#{build_id}", "replace_trace", %{trace: trace})
  end

  def send_trace(build_id, trace) do
    AlloyCi.Web.Endpoint.broadcast("builds:#{build_id}", "append_trace", %{trace: trace})
  end
end
