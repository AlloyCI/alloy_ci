defmodule AlloyCi.Artifact do
  @moduledoc """
  A Build represents a single job unit for a Pipeline. Each job defined in
  the `.alloy-ci.json` file will be stored as a Build.
  """
  use AlloyCi.Web, :schema
  use Arc.Ecto.Schema

  schema "artifacts" do
    field(:file, AlloyCi.Artifacts.Type)
    field(:expires_at, :naive_datetime)

    belongs_to(:build, AlloyCi.Build)

    timestamps()
  end

  @required_fields ~w(build_id)a
  @optional_fields ~w(expires_at)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_attachments(params, [:file])
    |> validate_required(@required_fields)
  end
end
