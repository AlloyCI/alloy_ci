defmodule AlloyCi.Web.LayoutView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Projects}

  def can_manage?(pipeline, user) do
    Projects.can_manage?(pipeline.project_id, user)
  end
end
