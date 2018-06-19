defmodule AlloyCi.Artifact do
  @moduledoc """
  Artifacts can be generated after a build job has finished.
  If the user specifies they want to save what was generated,
  the metadata for this file is stored here.
  """
  use Ecto.Schema
  import Ecto.Changeset
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
