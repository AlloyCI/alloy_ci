defmodule AlloyCi.Web.Admin.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.Projects
  import Kerosene.HTML
  import AlloyCi.Web.ProjectView, only: [builds_chart: 1]
end
