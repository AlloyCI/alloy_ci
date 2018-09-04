defmodule AlloyCi.Workers.FetchReposWorker do
  @moduledoc false
  alias AlloyCi.{
    Accounts,
    Authentication,
    Project,
    ProjectPermission,
    Web.ProjectView,
    Web.ReposChannel
  }

  @github_api Application.get_env(:alloy_ci, :github_api)

  @spec perform({any(), any()}) :: :ok | {:error, any()}
  def perform({user_id, csrf_token}) do
    :timer.sleep(500)

    auth =
      user_id
      |> Accounts.get_user()
      |> Accounts.github_auth()

    ReposChannel.ready(user_id, rendered_content(auth, csrf_token))
  end

  @spec rendered_content(Authentication.t(), any()) :: any()
  def rendered_content(auth, csrf_token) do
    Phoenix.View.render_to_string(
      ProjectView,
      "repos.html",
      existing_ids: ProjectPermission.existing_ids(),
      is_installed: Accounts.installed_on_owner?(auth.uid),
      repos: @github_api.fetch_repos(auth.token),
      changeset: Project.changeset(%Project{}),
      csrf: csrf_token
    )
  end
end
