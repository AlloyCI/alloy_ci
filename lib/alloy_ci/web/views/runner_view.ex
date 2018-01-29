defmodule AlloyCi.Web.RunnerView do
  use AlloyCi.Web, :view

  def builds_chart(runner) do
    runner
    |> Chartable.builds_chart()
    |> Poison.encode!()
  end
end
