defmodule AlloyCi.Project do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field(:name, :string)
    field(:owner, :string)
    field(:private, :boolean, default: false)
    field(:repo_id, :integer)
    field(:secret_variables, :map)
    field(:tags, {:array, :string})
    field(:token, :string)

    has_many(:pipelines, AlloyCi.Pipeline)
    has_many(:project_permissions, AlloyCi.ProjectPermission)
    has_many(:runners, AlloyCi.Runner)
    has_many(:users, through: [:project_permissions, :user])

    timestamps()
  end

  @required_fields ~w(name owner private repo_id token)a
  @optional_fields ~w(tags secret_variables)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
