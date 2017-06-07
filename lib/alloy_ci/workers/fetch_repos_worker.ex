defmodule AlloyCi.Workers.FetchReposWorker do
  @moduledoc """
  """
  alias AlloyCi.{Accounts, Project, ProjectPermission, Web.ProjectView}

  @github_api Application.get_env(:alloy_ci, :github_api)

  def perform(user_id, csrf_token) do
    user = Accounts.get_user!(user_id)
    token = Accounts.github_auth(user).token

    html = Phoenix.View.render_to_string(
      ProjectView,
      "repos.html",
      existing_ids: ProjectPermission.existing_ids,
      repos: @github_api.fetch_repos(token),
      changeset: Project.changeset(%Project{}),
      current_user: user,
      csrf: csrf_token
    )

    AlloyCi.Web.Endpoint.broadcast("repos:#{user_id}", "repos_ready", %{html: html})
  end
end
