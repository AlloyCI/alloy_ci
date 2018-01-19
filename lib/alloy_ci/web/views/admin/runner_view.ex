defmodule AlloyCi.Web.Admin.RunnerView do
  use AlloyCi.Web, :view
  import Kerosene.HTML

  def builds_chart(runner) do
    runner
    |> Chartable.builds_chart()
    |> Poison.encode!()
  end

  def projects_chart(runner) do
    runner
    |> Chartable.projects_chart()
    |> Poison.encode!()
  end

  def global_token do
    Application.get_env(:alloy_ci, :runner_registration_token)
  end
end
