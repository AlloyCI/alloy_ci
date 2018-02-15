defmodule AlloyCi.Pipeline do
  @moduledoc """
  A Pipeline represents the entire set of jobs, and all the information they
  contain. It maps directly to a single repository push.
  """
  use AlloyCi.Web, :schema

  schema "pipelines" do
    field(:before_sha, :string)
    field(:commit, :map)
    field(:duration, :integer)
    field(:finished_at, :naive_datetime)
    field(:installation_id, :integer)
    field(:notified, :boolean, default: false)
    field(:ref, :string)
    field(:sha, :string)
    field(:started_at, :naive_datetime)
    field(:status, :string, default: "pending")

    belongs_to(:project, AlloyCi.Project)
    has_many(:builds, AlloyCi.Build)

    timestamps()
  end

  @required_fields ~w(project_id ref sha before_sha commit installation_id)a
  @optional_fields ~w(started_at finished_at duration status notified)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:sha, name: :pipelines_project_id_sha_index)
  end
end
