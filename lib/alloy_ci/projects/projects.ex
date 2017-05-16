defmodule AlloyCi.Projects do
  @moduledoc """
  The boundary for the Projects system.
  """
  alias AlloyCi.{Project, ProjectPermission, Repo}

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

  def get_by_token(token) do
    Project
    |> Repo.get_by(token: token)
  end

  def create_project(params, user) do
    Repo.transaction(fn ->
      changeset =
        Project.changeset(
          %Project{},
          Enum.into(params, %{"token" => SecureRandom.urlsafe_base64(10)})
        )

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
end
