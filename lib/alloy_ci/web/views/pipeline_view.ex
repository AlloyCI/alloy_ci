defmodule AlloyCi.Web.PipelineView do
  use AlloyCi.Web, :view
  alias AlloyCi.Projects
  import AlloyCi.Web.BuildView, only: [build_actions: 3, build_duration: 1]

  def can_manage?(pipeline, user) do
    Projects.can_manage?(pipeline.project_id, user)
  end

  def timeline_status("success"), do: "user-timeline-success"
  def timeline_status("failed"), do: "user-timeline-danger"
  def timeline_status("running"), do: "user-timeline-warning"
  def timeline_status(_), do: "user-timeline-default"
end
