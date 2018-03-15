defmodule AlloyCi.Web.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Projects, Runners}
  import Kerosene.HTML
  import AlloyCi.Builds, only: [ref_type: 1]
  import AlloyCi.Web.SharedView, only: [platform_icon: 1]

  def app_url do
    Application.get_env(:alloy_ci, :app_url)
  end

  def builds_chart(project) do
    project
    |> Chartable.builds_chart()
    |> Poison.encode!()
  end

  def clean_ref(ref) do
    ref |> String.replace(ref |> ref_type() |> cleanup_string(), "")
  end

  def global_runners do
    Runners.global_runners()
  end

  def has_github_auth(user) do
    case Accounts.github_auth(user) do
      nil -> false
      _ -> true
    end
  end

  def ref_icon(ref) do
    ref
    |> ref_type()
    |> render_icon()
  end

  def tags(nil) do
    "No tags defined"
  end

  def tags(tags) do
    tags
    |> Enum.map(&tag_element/1)
  end

  ###################
  # Private functions
  ###################
  defp cleanup_string("branches"), do: "refs/heads/"
  defp cleanup_string("tags"), do: "refs/tags/"
  defp cleanup_string(_), do: "refs/"

  defp render_icon("branches") do
    {:safe, "<i class='fa fa-random'></i>"}
  end

  defp render_icon("tags") do
    {:safe, "<i class='fa fa-tags'></i>"}
  end

  defp render_icon("forks") do
    {:safe, "<i class='fa fa-code-fork'></i>"}
  end

  defp tag_element(value) do
    content_tag :div, class: "inline m-r-1" do
      [
        content_tag :button,
          type: "button",
          class: "btn btn-sm btn-info text-white m-t-1" do
          [value <> " "]
        end
      ]
    end
  end
end
