defmodule AlloyCi.Build do
  @moduledoc """
  A Build represents a single job unit for a Pipeline. Each job defined in
  the `.alloy-ci.json` file will be stored as a Build.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "builds" do
    field(:allow_failure, :boolean, default: false)
    field(:artifacts, :map)
    field(:commands, {:array, :string})
    field(:deps, {:array, :string})
    field(:finished_at, :naive_datetime)
    field(:name, :string)
    field(:options, :map)
    field(:queued_at, :naive_datetime)
    field(:stage, :string, default: "test")
    field(:stage_idx, :integer, default: 0)
    field(:started_at, :naive_datetime)
    field(:status, :string, default: "created")
    field(:tags, {:array, :string})
    field(:token, :string)
    field(:trace, :string, default: "")
    field(:variables, :map)
    field(:when, :string, default: "on_success")

    belongs_to(:pipeline, AlloyCi.Pipeline)
    belongs_to(:project, AlloyCi.Project)
    belongs_to(:runner, AlloyCi.Runner)

    has_one(:artifact, AlloyCi.Artifact)

    timestamps()
  end

  @required_fields ~w(commands name options pipeline_id project_id token)a
  @optional_fields ~w(allow_failure artifacts deps finished_at queued_at runner_id stage
                      started_at status tags trace variables when stage_idx)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
