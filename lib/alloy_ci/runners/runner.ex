defmodule AlloyCi.Runner do
  @moduledoc """
  """
  use AlloyCi.Web, :schema

  schema "runners" do
    field :active, :boolean, default: true
    field :architecture, :string
    field :contacted_at, :naive_datetime
    field :description, :string
    field :global, :boolean, default: false
    field :locked, :boolean, default: false
    field :name, :string
    field :platform, :string
    field :project_id, :integer
    field :run_untagged, :boolean, default: true
    field :token, :string
    field :tags, {:array, :string}
    field :version, :string

    timestamps()
  end

  @required_fields ~w(description name token)a
  @optional_fields ~w(active architecture contacted_at global locked platform project_id run_untagged tags version)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
