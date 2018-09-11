defmodule AlloyCi.Web.ProjectView do
  use AlloyCi.Web, :view
  alias AlloyCi.{Accounts, Project, Projects, User}
  import Kerosene.HTML
  import AlloyCi.Builds, only: [clean_ref: 1, ref_type: 1]
  import AlloyCi.Web.RunnerView, only: [platform_icon: 1, global_runners: 0]

  @github_api Application.get_env(:alloy_ci, :github_api)

  @spec app_url() :: binary()
  def app_url do
    Application.get_env(:alloy_ci, :app_url)
  end

  @spec reauth_url() :: binary()
  def reauth_url do
    @github_api.app_auth_url()
  end

  @spec builds_chart(Project.t()) ::
          binary()
          | maybe_improper_list(
              binary() | maybe_improper_list(any(), binary() | []) | byte(),
              binary() | []
            )
  def builds_chart(project) do
    project
    |> Chartable.builds_chart()
    |> Poison.encode!()
  end

  @spec has_github_auth(User.t()) :: boolean()
  def has_github_auth(user) do
    case Accounts.github_auth(user) do
      nil -> false
      _ -> true
    end
  end

  @spec ref_icon(binary()) :: {:safe, binary()}
  def ref_icon(ref) do
    ref
    |> ref_type()
    |> render_icon()
  end

  @spec tags(any()) :: <<_::120>> | [any()]
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
