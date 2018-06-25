defmodule AlloyCi.Web.PipelinesChannel do
  @moduledoc false
  alias AlloyCi.{Pipelines, Projects, Web.Endpoint, Web.ProjectView}
  use AlloyCi.Web, :channel

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (pipelines:lobby).
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def join("pipeline:" <> pipeline_id, _payload, socket) do
    pipeline = Pipelines.get(pipeline_id)

    if Projects.can_access?(pipeline.project_id, %{id: socket.assigns.user_id}) do
      {:ok, socket}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  def update_status(pipeline) do
    Endpoint.broadcast("pipeline:#{pipeline.id}", "update_status", %{
      content: render_pipeline(pipeline)
    })
  end

  defp render_pipeline(pipeline) do
    Phoenix.View.render_to_string(
      ProjectView,
      "pipeline.html",
      pipeline: pipeline,
      project: pipeline.project,
      conn: %Plug.Conn{}
    )
  end
end
