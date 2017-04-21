defmodule AlloyCi.Build do
  @moduledoc """
  """
  use AlloyCi.Web, :model

  schema "builds" do
    field :allow_failure, :boolean, default: false
    field :commands, {:array, :string}
    field :finished_at, :naive_datetime
    field :options, {:array, :string}
    field :queued_at, :naive_datetime
    field :runner_id, :integer
    field :stage, :string, default: "test"
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

  @required_fields ~w(commands options runner_id pipeline_id project_id token)a
  @optional_fields ~w(allow_failure finished_at queued_at stage started_at status trace variables when)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
