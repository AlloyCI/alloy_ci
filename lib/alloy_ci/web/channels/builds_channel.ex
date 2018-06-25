defmodule AlloyCi.Web.BuildsChannel do
  @moduledoc false
  alias AlloyCi.{Builds, Projects, Web.Endpoint, Web.PipelineView}
  use AlloyCi.Web, :channel

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (builds:lobby).
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def join("build:" <> build_id, _payload, socket) do
    build = Builds.get(build_id)

    if Projects.can_access?(build.project_id, %{id: socket.assigns.user_id}) do
      {:ok, socket}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  def replace_trace(build_id, trace) do
    Endpoint.broadcast("build:#{build_id}", "replace_trace", %{trace: trace})
  end

  def send_trace(_build_id, ""), do: nil

  def send_trace(build_id, trace) do
    Endpoint.broadcast("build:#{build_id}", "append_trace", %{trace: trace})
  end

  def update_status(build) do
    Endpoint.broadcast("build:#{build.id}", "update_status", %{content: render_build(build)})
  end

  def render_build(build) do
    Phoenix.View.render_to_string(
      PipelineView,
      "build.html",
      build: build,
      conn: %Plug.Conn{}
    )
  end
end
