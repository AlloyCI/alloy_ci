defmodule AlloyCi.ProjectPermission do
  @moduledoc """
  Mapping to give Users access to multiple Projects, without duplicating entries
  """
  use AlloyCi.Web, :model
  alias AlloyCi.Repo

  schema "project_permissions" do
    field :repo_id, :integer

    belongs_to :project, AlloyCi.Project
    belongs_to :user, AlloyCi.User

    timestamps()
  end

  @required_fields ~w(user_id project_id repo_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def existing_ids do
    query = from p in "project_permissions",
            distinct: true,
            select: {p.repo_id, p.project_id}
    query |> Repo.all
  end

  def repo_ids do
    query = from p in "project_permissions",
            distinct: true,
            select: p.repo_id
    query |> Repo.all
  end
end
