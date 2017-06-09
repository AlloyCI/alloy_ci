defmodule AlloyCi.Workers.FetchReposWorker do
  @moduledoc """
  """
  alias AlloyCi.{Accounts, Project, ProjectPermission, Web.ProjectView}

  @github_api Application.get_env(:alloy_ci, :github_api)

  def perform(user_id, csrf_token) do
    auth =
      user_id
      |> Accounts.get_user!
      |> Accounts.github_auth

    rendered_content =
      Phoenix.View.render_to_string(
        ProjectView,
        "repos.html",
        existing_ids: ProjectPermission.existing_ids,
        repos: @github_api.fetch_repos(auth.token),
        changeset: Project.changeset(%Project{}),
        csrf: csrf_token
      )

    AlloyCi.Web.Endpoint.broadcast(
      "repos:#{user_id}", 
      "repos_ready",
      %{html: rendered_content}
    )
  end
end
