defmodule AlloyCi.Build do
  @moduledoc """
  """
  use AlloyCi.Web, :model

  schema "builds" do
    field :allow_failure, :boolean, default: false
    field :commands, {:array, :string}
    field :finished_at, :naive_datetime
    field :name, :string
    field :options, :map
    field :queued_at, :naive_datetime
    field :runner_id, :integer
    field :stage, :string, default: "test"
    field :stage_idx, :integer
    field :started_at, :naive_datetime
    field :status, :string
    field :token, :string
    field :trace, :string
    field :variables, :map
    field :when, :string, default: "on_success"

    belongs_to :pipeline, AlloyCi.Pipeline
    belongs_to :project, AlloyCi.Project

    timestamps()
  end

  @required_fields ~w(commands name options pipeline_id project_id token)a
  @optional_fields ~w(allow_failure finished_at queued_at runner_id stage started_at status trace variables when stage_idx)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
