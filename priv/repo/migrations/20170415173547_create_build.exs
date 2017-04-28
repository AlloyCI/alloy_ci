defmodule AlloyCi.Repo.Migrations.CreateBuild do
  @moduledoc """
  """
  use Ecto.Migration

  def change do
    create table(:builds) do
      add :allow_failure, :boolean, default: false, null: false
      add :commands, {:array, :string}
      add :finished_at, :naive_datetime
      add :name, :string, null: false
      add :options, :map
      add :pipeline_id, references(:pipelines, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :queued_at, :naive_datetime
      add :runner_id, :integer
      add :stage, :string, default: "test"
      add :stage_idx, :integer
      add :started_at, :naive_datetime
      add :status, :string, default: "pending"
      add :token, :string
      add :trace, :text
      add :variables, :map
      add :when, :string, default: "on_success"

      timestamps()
    end

    create index(:builds, [:token], unique: true)
    create index(:builds, [:project_id])
  end
end
