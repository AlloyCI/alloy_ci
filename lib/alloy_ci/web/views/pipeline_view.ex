defmodule AlloyCi.Web.PipelineView do
  use AlloyCi.Web, :view
  alias AlloyCi.Projects

  def build_actions(_, %{status: s}) when s in ~w(pending running created), do: ""

  def build_actions(conn, build) do
    content_tag :span,
      class: "float-right",
      data: [toggle: "tooltip", placement: "bottom"],
      title: "Restart this build" do
      link to: project_build_path(conn, :create, build.project_id, %{id: build.id}),
           method: :post,
           class: "action-link" do
        icon("refresh", "fa-lg")
      end
    end
  end

  def build_duration(%{finished_at: f, started_at: s}) when is_nil(f) or is_nil(s) do
    "Pending"
  end

  def build_duration(build) do
    (Timex.to_unix(build.finished_at) - Timex.to_unix(build.started_at))
    |> TimeConvert.to_compound()
  end

  def build_status_icon("created"), do: icon("calendar", "fa-lg")
  def build_status_icon("failed"), do: icon("close", "fa-lg")
  def build_status_icon("pending"), do: icon("circle-o-notch", "fa-lg")
  def build_status_icon("running"), do: icon("circle-o-notch", "fa-spin fa-lg")
  def build_status_icon("success"), do: icon("check", "fa-lg")
  def build_status_icon(_), do: icon("ban")

  def can_manage?(pipeline, user) do
    Projects.can_manage?(pipeline.project_id, user)
  end

  def timeline_status("success"), do: "user-timeline-success"
  def timeline_status("failed"), do: "user-timeline-danger"
  def timeline_status("running"), do: "user-timeline-warning"
  def timeline_status(_), do: "user-timeline-default"
end
