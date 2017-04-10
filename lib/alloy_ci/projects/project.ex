defmodule AlloyCi.Project do
  @moduledoc """
  """
  use AlloyCi.Web, :model
  alias AlloyCi.Repo
  alias AlloyCi.ProjectPermission

  schema "projects" do
    field :name, :string
    field :owner, :string
    field :private, :boolean, default: false
    field :repo_id, :integer

    has_many :project_permissions, ProjectPermission
    has_many :users, through: [:project_permissions, :user]

    timestamps()
  end

  @required_fields ~w(name owner private repo_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def get_by(id, user) do
    permission =
      ProjectPermission
      |> Repo.get_by(project_id: id, user_id: user.id)
      |> Repo.preload(:project)
    case permission do
      %ProjectPermission{} -> {:ok, permission.project}
      _ -> {:error, nil}
    end
  end

  def create_project(params, user) do
    Repo.transaction(fn ->
      changeset = changeset(%AlloyCi.Project{}, params)
      with {:ok, project} <- Repo.insert(changeset) do
        permissions_changeset = ProjectPermission.changeset(
                                  %ProjectPermission{},
                                  %{project_id: project.id,
                                    repo_id: project.repo_id,
                                    user_id: user.id
                                  }
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

  def repos_for(user) do
    query = from auth in "authentications",
              where: auth.user_id == ^user.id and auth.provider == "github",
              select: auth.token
    token = Repo.one(query)
    client = Tentacat.Client.new(%{access_token: token})
    Tentacat.Repositories.list_mine(client, sort: "pushed")
  end
end
