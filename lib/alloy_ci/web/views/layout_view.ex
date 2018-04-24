defmodule AlloyCi.Web.LayoutView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Projects}
  import AlloyCi.Web.ProjectView, only: [ref_icon: 1]
  import AlloyCi.Builds, only: [clean_ref: 1]

  def can_manage?(pipeline, user) do
    Projects.can_manage?(pipeline.project_id, user)
  end
end
