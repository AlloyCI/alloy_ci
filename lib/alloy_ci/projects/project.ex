defmodule AlloyCi.Project do
  @moduledoc """
  """
  use AlloyCi.Web, :model

  schema "projects" do
    field :name, :string
    field :owner, :string
    field :private, :boolean, default: false
    field :repo_id, :integer
    field :tags, {:array, :string}
    field :token, :string

    has_many :project_permissions, AlloyCi.ProjectPermission
    has_many :users, through: [:project_permissions, :user]
    has_many :pipelines, AlloyCi.Pipeline

    timestamps()
  end

  @required_fields ~w(name owner private repo_id token)a
  @optional_fields ~w(tags)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
