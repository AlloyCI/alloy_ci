defmodule AlloyCi.Web.RunnerView do
  use AlloyCi.Web, :view
  alias AlloyCi.Runners

  def builds_chart(runner) do
    runner
    |> Chartable.builds_chart()
    |> Poison.encode!()
  end

  def global(%{global: true}) do
    content_tag :span, data: [toggle: "tooltip", placement: "bottom"], title: "Global runner" do
      icon("globe")
    end
  end

  def global(_) do
    content_tag :span,
      data: [toggle: "tooltip", placement: "bottom"],
      title: "Project specific runner" do
      icon("plug")
    end
  end

  def global_runners do
    Runners.global_runners()
  end

  def platform_icon("darwin") do
    content_tag :span, data: [toggle: "tooltip", placement: "bottom"], title: "Darwin" do
      icon("apple")
    end
  end

  def platform_icon("windows") do
    content_tag :span, data: [toggle: "tooltip", placement: "bottom"], title: "Windows" do
      icon("windows")
    end
  end

  def platform_icon("linux") do
    content_tag :span, data: [toggle: "tooltip", placement: "bottom"], title: "Linux" do
      icon("linux")
    end
  end

  def platform_icon(p) do
    content_tag :span, data: [toggle: "tooltip", placement: "bottom"], title: p do
      icon("desktop")
    end
  end
end
