defmodule AlloyCi.Projects do
  @moduledoc """
  The boundary for the Projects system.
  """
  import Ecto.Query, warn: false
  alias AlloyCi.{Pipelines, Project, ProjectPermission, Repo}

  def get_by(id, user) do
    permission =
      ProjectPermission
      |> Repo.get_by(project_id: id, user_id: user.id)
      |> Repo.preload(:project)
    case permission do
      %ProjectPermission{} ->
        project = permission.project |> Repo.preload(:pipelines)
        {:ok, project}
      _ -> {:error, nil}
    end
  end

  def get_by_repo_id(id) do
    Project
    |> Repo.get_by(repo_id: id)
  end

  def create_project(params, user) do
    Repo.transaction(fn ->
      changeset = Project.changeset(%Project{}, params)
      with {:ok, project} <- Repo.insert(changeset) do
        permissions_changeset = ProjectPermission.changeset(
                                  %ProjectPermission{},
                                  %{project_id: project.id,
                                    repo_id: project.repo_id,
                                    user_id: user.id}
                                )
        case Repo.insert(permissions_changeset) do
          {:ok, _} -> project
          {:error, changeset} -> changeset |> Repo.rollback
        end
      else
        {:error, changeset} -> changeset |> Repo.rollback
      end
    end)
  end

  def delete_project(id, user) do
    with {:ok, project} <- get_by(id, user) do
      Repo.delete(project)
    end
  end

  def clone_url(project, pipeline) do
    token = Pipelines.installation_token(pipeline)

    "https://x-access-token:#{token["token"]}@github.com/#{project.owner}/#{project.name}.git"
  end

  def repos_for(user) do
    query = from auth in "authentications",
              where: auth.user_id == ^user.id and auth.provider == "github",
              select: auth.token
    token = Repo.one(query)
    client = Tentacat.Client.new(%{access_token: token})
    Tentacat.Repositories.list_mine(client, sort: "pushed")
  end
end
